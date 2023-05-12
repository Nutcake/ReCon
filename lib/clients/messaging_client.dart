import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:contacts_plus_plus/apis/friend_api.dart';
import 'package:contacts_plus_plus/apis/message_api.dart';
import 'package:contacts_plus_plus/apis/user_api.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/clients/notification_client.dart';
import 'package:contacts_plus_plus/clients/settings_client.dart';
import 'package:contacts_plus_plus/models/authentication_data.dart';
import 'package:contacts_plus_plus/models/friend.dart';
import 'package:contacts_plus_plus/models/settings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/config.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

enum EventType {
  unknown,
  message,
  unknown1,
  unknown2,
  unknown3,
  unknown4,
  keepAlive,
  error;
}

enum EventTarget {
  unknown,
  messageSent,
  receiveMessage,
  messagesRead;

  factory EventTarget.parse(String? text) {
    if (text == null) return EventTarget.unknown;
    return EventTarget.values.firstWhere((element) => element.name.toLowerCase() == text.toLowerCase(),
      orElse: () => EventTarget.unknown,
    );
  }
}

class MessagingClient extends ChangeNotifier {
  static const String eofChar = "";
  static const String _negotiationPacket = "{\"protocol\":\"json\", \"version\":1}$eofChar";
  static const List<int> _reconnectTimeoutsSeconds = [0, 5, 10, 20, 60];

  static const int _unreadCheckMinuteInterval = 30;
  static const String unreadCheckTaskName = "periodic-unread-check";
  static const String _storageNotifiedUnreadsKey = "notfiedUnreads";
  static const String _storageLastUpdateKey = "lastUnreadCheck";
  static const String _hiveKey = "mClient";
  static const String _storedFriendsKey = "friends";
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const Duration _autoRefreshDuration = Duration(seconds: 90);

  final ApiClient _apiClient;
  final Map<String, Friend> _friendsCache = {};
  final List<Friend> _sortedFriendsCache = []; // Keep a sorted copy so as to not have to sort during build()
  final Map<String, MessageCache> _messageCache = {};
  final Map<String, List<Message>> _unreads = {};
  final Logger _logger = Logger("NeosHub");
  final Workmanager _workmanager = Workmanager();

  final NotificationClient _notificationClient;
  final SettingsClient _settingsClient;

  WebSocket? _wsChannel;
  Friend? selectedFriend;
  Timer? _notifyOnlineTimer;
  Timer? _autoRefresh;
  Timer? _refreshTimeout;
  int _attempts = 0;
  bool _isConnecting = false;
  String? _initStatus;

  String? get initStatus => _initStatus;

  bool get websocketConnected => _wsChannel != null;

  MessagingClient({required ApiClient apiClient, required NotificationClient notificationClient,
    required SettingsClient settingsClient})
      : _apiClient = apiClient, _notificationClient = notificationClient, _settingsClient = settingsClient {
    initFriends();
    startWebsocket();
    _notifyOnlineTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      // We should probably let the MessagingClient handle the entire state of USerStatus instead of mirroring like this
      // but I don't feel like implementing that right now.
      UserApi.setStatus(apiClient, status: await UserApi.getUserStatus(apiClient, userId: apiClient.userId));
    });
    //_settingsClient.addListener(onSettingsChanged);
    if (!_settingsClient.currentSettings.notificationsDenied.valueOrDefault) {
      //registerNotificationTask();
    }
  }

  Future<void> initFriends() async {
    try {
      await initBox();
      await _restoreFriendsList();
      try {
        await refreshFriendsList();
      } catch (e, s) {
        FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s));
        notifyListeners();
      }
    } catch (e,s) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s));
      refreshFriendsListWithErrorHandler();
    }
  }

  Future<void> onSettingsChanged(Settings oldSettings, Settings newSettings) async {
    if (oldSettings.notificationsDenied.valueOrDefault != newSettings.notificationsDenied.valueOrDefault) {
      if (newSettings.notificationsDenied.valueOrDefault) {
        await unregisterNotificationTask();
      } else {
        await registerNotificationTask();
      }
    }
  }

  static Future<List<Message>> updateNotified(List<Message> unreads) async {
    if (unreads.isEmpty) return [];
    const storage = FlutterSecureStorage();
    final data = await storage.read(key: _storageNotifiedUnreadsKey);

    final existing = data == null ? <String>[] : (jsonDecode(data) as List).map((e) => "$e").toList();
    final unnotified = unreads.where((unread) => !existing.contains(unread.id));
    existing.addAll(unnotified.map((e) => e.id));
    await storage.write(key: _storageNotifiedUnreadsKey, value: jsonEncode(existing.unique()));
    return unnotified.toList();
  }

  static Future<void> backgroundCheckUnreads(Map<String, dynamic>? inputData) async {
    if (inputData == null) throw "Unauthenticated";
    return;
    final auth = AuthenticationData.fromMap(inputData);
    const storage = FlutterSecureStorage();
    final lastCheckData = await storage.read(key: _storageLastUpdateKey);
    if (lastCheckData != null && DateTime.now().difference(DateTime.parse(lastCheckData)) < const Duration(
      minutes: _unreadCheckMinuteInterval,
    )) {
      return;
    }

    final client = ApiClient(authenticationData: auth);
    await client.extendSession();

    final unreads = await MessageApi.getUserMessages(client, unreadOnly: true);

    final unnotified = await updateNotified(unreads);

    await NotificationClient().showUnreadMessagesNotification(unnotified);
    await storage.write(key: _storageLastUpdateKey, value: DateTime.now().toIso8601String());
  }

  Future<void> registerNotificationTask() async {
    final auth = _apiClient.authenticationData;
    if (!auth.isAuthenticated) throw "Unauthenticated";
    _workmanager.registerPeriodicTask(
      unreadCheckTaskName,
      unreadCheckTaskName,
      frequency: const Duration(minutes: _unreadCheckMinuteInterval),
      inputData: auth.toMap(),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  Future<void> unregisterNotificationTask() async {
    await _workmanager.cancelByUniqueName(unreadCheckTaskName);
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _refreshTimeout?.cancel();
    _notifyOnlineTimer?.cancel();
    _wsChannel?.close();
    super.dispose();
  }

  void _sendData(data) {
    if (_wsChannel == null) throw "Neos Hub is not connected";
    _wsChannel!.add(jsonEncode(data)+eofChar);
  }

  void resetStatus() {
    _initStatus = null;
    notifyListeners();
  }

  void refreshFriendsListWithErrorHandler() async {
    try {
      await refreshFriendsList();
    } catch (e) {
      _initStatus = "$e";
      notifyListeners();
    }
  }

  Future<void> initBox() async {
    try {
      final path = await getTemporaryDirectory();
      Hive.init(path.path);
      await Hive.openBox(_hiveKey, path: path.path);
    } catch (_) {}
  }

  Future<void> _restoreFriendsList() async {
    if (!Hive.isBoxOpen(_hiveKey)) throw "Failed to open box";
    final mStorage = Hive.box(_hiveKey);
    final storedFriends = await mStorage.get(_storedFriendsKey) as List?;
    if (storedFriends == null) throw "No cached friends list";
    _friendsCache.clear();
    _sortedFriendsCache.clear();

    for (final storedFriend in storedFriends) {
      final friend = Friend.fromMap(storedFriend);
      _friendsCache[friend.id] = friend;
      _sortedFriendsCache.add(friend);
    }
    _sortFriendsCache();
    notifyListeners();
  }


  Future<void> refreshFriendsList() async {
    _autoRefresh?.cancel();
    _autoRefresh = Timer(_autoRefreshDuration, () async {
      try {
        await refreshFriendsList();
      } catch (_) {
        // We don't really need to do anything if fetching unreads and messages fails in the background since we can
        // just keep showing the old state until refreshing succeeds.
      }
    });
    final now = DateTime.now();
    final lastUpdate = await _storage.read(key: _storageLastUpdateKey);
    if (lastUpdate != null && now.difference(DateTime.parse(lastUpdate)) < _autoRefreshDuration) throw "You are being rate limited.";

    final friends = await FriendApi.getFriendsList(_apiClient);
    final List<Map> storableFriends = [];
    _friendsCache.clear();
    for (final friend in friends) {
      _friendsCache[friend.id] = friend;
      storableFriends.add(friend.toMap(shallow: true));
    }
    _sortedFriendsCache.clear();
    _sortedFriendsCache.addAll(friends);
    _sortFriendsCache();
    _initStatus = "";
    await _storage.write(key: _storageLastUpdateKey, value: now.toIso8601String());
    final unreadMessages = await MessageApi.getUserMessages(_apiClient, unreadOnly: true);
    updateAllUnreads(unreadMessages.toList());

    notifyListeners();
    if (!Hive.isBoxOpen(_hiveKey)) return;
    final mStorage = Hive.box(_hiveKey);
    mStorage.put(_storedFriendsKey, storableFriends);
  }

  void _sortFriendsCache() {
    _sortedFriendsCache.sort((a, b) {
      var aVal = friendHasUnreads(a) ? -3 : 0;
      var bVal = friendHasUnreads(b) ? -3 : 0;

      aVal -= a.latestMessageTime.compareTo(b.latestMessageTime);
      aVal += a.userStatus.onlineStatus.compareTo(b.userStatus.onlineStatus) * 2;
      return aVal.compareTo(bVal);
    });
  }

  void updateAllUnreads(List<Message> messages) {
    _unreads.clear();
    for (final msg in messages) {
      if (msg.senderId != _apiClient.userId) {
        final value = _unreads[msg.senderId];
        if (value == null) {
          _unreads[msg.senderId] = [msg];
        } else {
          value.add(msg);
        }
      }
    }
  }

  void addUnread(Message message) {
    var messages = _unreads[message.senderId];
    if (messages == null) {
      messages = [message];
      _unreads[message.senderId] = messages;
    } else {
      messages.add(message);
    }
    _sortFriendsCache();
    if (!_settingsClient.currentSettings.notificationsDenied.valueOrDefault) {
      updateNotified(messages).then((unnotified) {
        unnotified.sort();
        _notificationClient.showUnreadMessagesNotification(unnotified.reversed);
      });
    }
    notifyListeners();
  }

  void clearUnreadsForUser(String userId) {
    _unreads[userId]?.clear();
    notifyListeners();
  }

  List<Message> getUnreadsForFriend(Friend friend) => _unreads[friend.id] ?? [];

  bool friendHasUnreads(Friend friend) => _unreads.containsKey(friend.id);

  bool messageIsUnread(Message message) {
    return _unreads[message.senderId]?.any((element) => element.id == message.id) ?? false;
  }

  Friend? getAsFriend(String userId) => _friendsCache[userId];

  List<Friend> get cachedFriends => _sortedFriendsCache;

  MessageCache _createUserMessageCache(String userId) => MessageCache(apiClient: _apiClient, userId: userId);

  Future<void> loadUserMessageCache(String userId) async {
    final cache = getUserMessageCache(userId) ?? _createUserMessageCache(userId);
    await cache.loadMessages();
    _messageCache[userId] = cache;
    notifyListeners();
  }

  void _updateFriend(Friend friend) {
    _friendsCache[friend.id] = friend;
    final sIndex = _sortedFriendsCache.indexWhere((element) => element.id == friend.id);
    if (sIndex == -1) {
      _sortedFriendsCache.add(friend);
    } else {
      _sortedFriendsCache[sIndex] = friend;
    }
    _sortFriendsCache();
  }

  Future<void> updateFriendStatus(String userId) async {
    final friend = getAsFriend(userId);
    if (friend == null) return;
    final newStatus = await UserApi.getUserStatus(_apiClient, userId: userId);
    _updateFriend(friend.copyWith(userStatus: newStatus));
    notifyListeners();
  }

  MessageCache? getUserMessageCache(String userId) => _messageCache[userId];

  void _onDisconnected(error) async {
    _wsChannel = null;
    _logger.warning("Neos Hub connection died with error '$error', reconnecting...");
    await startWebsocket();
  }

  Future<void> startWebsocket() async {
    if (!_apiClient.isAuthenticated) {
      _logger.info("Tried to connect to Neos Hub without authentication, this is probably fine for now.");
      return;
    }
    if (_isConnecting) {
      return;
    }
    _isConnecting = true;
    _wsChannel = await _tryConnect();
    _isConnecting = false;
    _logger.info("Connected to Neos Hub.");
    _wsChannel!.done.then((error) => _onDisconnected(error));
    _wsChannel!.listen(_handleEvent, onDone: () => _onDisconnected("Connection closed."), onError: _onDisconnected);
    _wsChannel!.add(_negotiationPacket);
  }

  Future<WebSocket> _tryConnect() async {
    while (true) {
      try {
        final http.Response response;
        try {
          response = await http.post(
            Uri.parse("${Config.neosHubUrl}/negotiate"),
            headers: _apiClient.authorizationHeader,
          );
          ApiClient.checkResponse(response);
        } catch (e) {
          throw "Failed to acquire connection info from Neos API: $e";
        }
        final body = jsonDecode(response.body);
        final url = (body["url"] as String?)?.replaceFirst("https://", "wss://");
        final wsToken = body["accessToken"];

        if (url == null || wsToken == null) {
          throw "Invalid response from server.";
        }
        final ws = await WebSocket.connect("$url&access_token=$wsToken");
        _attempts = 0;
        return ws;
      } catch (e) {
        final timeout = _reconnectTimeoutsSeconds[_attempts.clamp(0, _reconnectTimeoutsSeconds.length - 1)];
        _logger.severe(e);
        _logger.severe("Retrying in $timeout seconds");
        await Future.delayed(Duration(seconds: timeout));
        _attempts++;
      }
    }
  }

  void _handleEvent(event) {
    final body = jsonDecode((event.toString().replaceAll(eofChar, "")));
    final int rawType = body["type"] ?? 0;
    if (rawType > EventType.values.length) {
      _logger.info("Unhandled event type $rawType: $body");
      return;
    }
    switch (EventType.values[rawType]) {
      case EventType.unknown1:
      case EventType.unknown2:
      case EventType.unknown3:
      case EventType.unknown4:
      case EventType.unknown:
        _logger.info("Received unknown event: $rawType: $body");
        break;
      case EventType.message:
        _logger.info("Received message-event.");
        _handleMessageEvent(body);
        break;
      case EventType.keepAlive:
        _logger.info("Received keep-alive.");
        break;
      case EventType.error:
        _logger.severe("Received error-event: ${body["error"]}");
        // Should we trigger a manual reconnect here or just let the remote service close the connection?
        break;
    }
  }

  void _handleMessageEvent(body) async {
    final target = EventTarget.parse(body["target"]);
    final args = body["arguments"];
    switch (target) {
      case EventTarget.unknown:
        _logger.info("Unknown event-target in message: $body");
        return;
      case EventTarget.messageSent:
        final msg = args[0];
        final message = Message.fromMap(msg, withState: MessageState.sent);
        final cache = getUserMessageCache(message.recipientId) ?? _createUserMessageCache(message.recipientId);
        cache.addMessage(message);
        notifyListeners();
        break;
      case EventTarget.receiveMessage:
        final msg = args[0];
        final message = Message.fromMap(msg);
        final cache = getUserMessageCache(message.senderId) ?? _createUserMessageCache(message.senderId);
        cache.addMessage(message);
        if (message.senderId != selectedFriend?.id) {
          addUnread(message);
          updateFriendStatus(message.senderId);
        }
        notifyListeners();
        break;
      case EventTarget.messagesRead:
        final messageIds = args[0]["ids"] as List;
        final recipientId = args[0]["recipientId"];
        if (recipientId == null) break;
        final cache = getUserMessageCache(recipientId);
        if (cache == null) break;
        for (var id in messageIds) {
          cache.setMessageState(id, MessageState.read);
        }
        notifyListeners();
        break;
    }
  }

  void sendMessage(Message message) async {
    final msgBody = message.toMap();
    final data = {
      "type": EventType.message.index,
      "target": "SendMessage",
      "arguments": [
        msgBody
      ],
    };
    _sendData(data);
    final cache = getUserMessageCache(message.recipientId) ?? _createUserMessageCache(message.recipientId);
    cache.messages.add(message);
    notifyListeners();
  }

  void markMessagesRead(MarkReadBatch batch) {
    final msgBody = batch.toMap();
    final data = {
      "type": EventType.message.index,
      "target": "MarkMessagesRead",
      "arguments": [
        msgBody
      ],
    };
    _sendData(data);
    clearUnreadsForUser(batch.senderId);
    _storage.read(key: _storageNotifiedUnreadsKey).then((data) async {
      final existing = data == null ? [] : jsonDecode(data) as List<String>;
      final marked = existing.where((element) => !batch.ids.contains(element)).toList();
      await _storage.write(key: _storageNotifiedUnreadsKey, value: jsonEncode(marked));
    });
  }
}