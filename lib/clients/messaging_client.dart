import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:contacts_plus_plus/apis/friend_api.dart';
import 'package:contacts_plus_plus/apis/message_api.dart';
import 'package:contacts_plus_plus/apis/user_api.dart';
import 'package:contacts_plus_plus/clients/notification_client.dart';
import 'package:contacts_plus_plus/models/authentication_data.dart';
import 'package:contacts_plus_plus/models/friend.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/config.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:logging/logging.dart';
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
  static const String taskName = "periodic-unread-check";
  static const Duration _autoRefreshDuration = Duration(seconds: 10);
  static const Duration _unreadSafeguardDuration = Duration(seconds: 120);
  static const String _messageBoxKey = "message-box";
  static const String _lastUpdateKey = "__last-update-time";
  final ApiClient _apiClient;
  final List<Friend> _sortedFriendsCache = []; // Keep a sorted copy so as to not have to sort during build()
  final Map<String, MessageCache> _messageCache = {};
  final Map<String, List<Message>> _unreads = {};
  final Logger _logger = Logger("NeosHub");
  final Workmanager _workmanager = Workmanager();
  final NotificationClient _notificationClient;
  Friend? selectedFriend;
  Timer? _notifyOnlineTimer;
  Timer? _autoRefresh;
  Timer? _refreshTimeout;
  Timer? _unreadSafeguard;
  int _attempts = 0;
  WebSocket? _wsChannel;
  bool _isConnecting = false;
  String? _initStatus;

  String? get initStatus => _initStatus;

  bool get websocketConnected => _wsChannel != null;

  MessagingClient({required ApiClient apiClient, required NotificationClient notificationClient})
      : _apiClient = apiClient, _notificationClient = notificationClient {
    Hive.openBox(_messageBoxKey).then((box) async {
      box.delete(_lastUpdateKey);
      await refreshFriendsListWithErrorHandler();
      await _refreshUnreads();
    });
    startWebsocket();
    _notifyOnlineTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      // We should probably let the MessagingClient handle the entire state of USerStatus instead of mirroring like this
      // but I don't feel like implementing that right now.
      UserApi.setStatus(apiClient, status: await UserApi.getUserStatus(apiClient, userId: apiClient.userId));
    });
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

  Future<void> _refreshUnreads() async {
    _unreadSafeguard?.cancel();
    try {
      final unreadMessages = await MessageApi.getUserMessages(_apiClient, unreadOnly: true);
      updateAllUnreads(unreadMessages.toList());
    } catch (_) {}
    _unreadSafeguard = Timer(_unreadSafeguardDuration, _refreshUnreads);
  }

  Future<void> refreshFriendsListWithErrorHandler () async {
    try {
      await refreshFriendsList();
    } catch (e) {
      _initStatus = "$e";
      notifyListeners();
    }
  }

  Future<void> refreshFriendsList() async {
    DateTime? lastUpdateUtc = Hive.box(_messageBoxKey).get(_lastUpdateKey);
    _autoRefresh?.cancel();
    _autoRefresh = Timer(_autoRefreshDuration, () => refreshFriendsList());

    final friends = await FriendApi.getFriendsList(_apiClient, lastStatusUpdate: lastUpdateUtc);
    for (final friend in friends) {
      await _updateFriend(friend);
    }

    _initStatus = "";
    notifyListeners();
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
    messages.sort();
    _sortFriendsCache();
    _notificationClient.showUnreadMessagesNotification(messages.reversed);
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

  Friend? getAsFriend(String userId) => Friend.fromMapOrNull(Hive.box(_messageBoxKey).get(userId));

  List<Friend> get cachedFriends => _sortedFriendsCache;

  MessageCache _createUserMessageCache(String userId) => MessageCache(apiClient: _apiClient, userId: userId);

  void deleteUserMessageCache(String userId) {
    _messageCache.remove(userId);
  }

  Future<void> loadUserMessageCache(String userId) async {
    final cache = getUserMessageCache(userId) ?? _createUserMessageCache(userId);
    await cache.loadMessages();
    _messageCache[userId] = cache;
    notifyListeners();
  }

  Future<void> _updateFriend(Friend friend) async {
    final box = Hive.box(_messageBoxKey);
    box.put(friend.id, friend.toMap());
    final lastStatusUpdate = box.get(_lastUpdateKey);
    if (lastStatusUpdate == null || friend.userStatus.lastStatusChange.isAfter(lastStatusUpdate)) {
      await box.put(_lastUpdateKey, friend.userStatus.lastStatusChange);
    }
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
    await _updateFriend(friend.copyWith(userStatus: newStatus));
    notifyListeners();
  }

  MessageCache? getUserMessageCache(String userId) => _messageCache[userId];

  static Future<void> backgroundCheckUnreads(Map<String, dynamic>? inputData) async {
    if (inputData == null) return;
    final auth = AuthenticationData.fromMap(inputData);
    final unreads = await MessageApi.getUserMessages(ApiClient(authenticationData: auth), unreadOnly: true);
    for (var message in unreads) {
      throw UnimplementedError();
    }
  }

  Future<void> _updateNotificationTask(int minuteInterval) async {
    final auth = _apiClient.authenticationData;
    if (!auth.isAuthenticated) throw "Unauthenticated";
    await _workmanager.cancelByUniqueName(taskName);
    _workmanager.registerPeriodicTask(
      taskName,
      taskName,
      frequency: Duration(minutes: minuteInterval),
      inputData: auth.toMap(),
    );
  }

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
  }
}