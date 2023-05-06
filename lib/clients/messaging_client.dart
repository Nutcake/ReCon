import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:contacts_plus_plus/apis/friend_api.dart';
import 'package:contacts_plus_plus/apis/message_api.dart';
import 'package:contacts_plus_plus/clients/notification_client.dart';
import 'package:contacts_plus_plus/models/authentication_data.dart';
import 'package:contacts_plus_plus/models/friend.dart';
import 'package:flutter/widgets.dart';
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
  static const Duration _autoRefreshDuration = Duration(seconds: 90);
  static const Duration _refreshTimeoutDuration = Duration(seconds: 30);
  final ApiClient _apiClient;
  final Map<String, Friend> _friendsCache = {};
  final List<Friend> _sortedFriendsCache = []; // Keep a sorted copy so as to not have to sort during build()
  final Map<String, MessageCache> _messageCache = {};
  final Map<String, Function> _messageUpdateListeners = {};
  final Map<String, List<Message>> _unreads = {};
  final Logger _logger = Logger("NeosHub");
  final Workmanager _workmanager = Workmanager();
  final NotificationClient _notificationClient;
  Timer? _autoRefresh;
  Timer? _refreshTimeout;
  int _attempts = 0;
  WebSocket? _wsChannel;
  bool _isConnecting = false;
  String _initError = "";
  bool _initDone = false;

  String get initError => _initError;

  MessagingClient({required ApiClient apiClient, required NotificationClient notificationClient})
      : _apiClient = apiClient, _notificationClient = notificationClient {
    refreshFriendsListWithErrorHandler();
    start();
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _refreshTimeout?.cancel();
    _wsChannel?.close();
    super.dispose();
  }

  void _sendData(data) {
    if (_wsChannel == null) throw "Neos Hub is not connected";
    _wsChannel!.add(jsonEncode(data)+eofChar);
  }

  void refreshFriendsListWithErrorHandler () async {
    try {
      await refreshFriendsList();
      _initDone = true;
    } catch (e) {
      _initError = "$e";
    }
    notifyListeners();
  }

  Future<void> refreshFriendsList() async {
    if (_refreshTimeout?.isActive == true) return;

    _autoRefresh?.cancel();
    _autoRefresh = Timer(_autoRefreshDuration, () => refreshFriendsList());
    _refreshTimeout?.cancel();
    _refreshTimeout = Timer(_refreshTimeoutDuration, () {});

    final unreadMessages = await MessageApi.getUserMessages(_apiClient, unreadOnly: true);
    updateAllUnreads(unreadMessages.toList());

    final friends = await FriendApi.getFriendsList(_apiClient);
    _friendsCache.clear();
    for (final friend in friends) {
      _friendsCache[friend.id] = friend;
    }
    _sortedFriendsCache.clear();
    _sortedFriendsCache.addAll(friends.sorted((a, b) {
      var aVal = friendHasUnreads(a) ? -3 : 0;
      var bVal = friendHasUnreads(b) ? -3 : 0;

      aVal -= a.userStatus.lastStatusChange.compareTo(b.userStatus.lastStatusChange);
      aVal += a.userStatus.onlineStatus.compareTo(b.userStatus.onlineStatus) * 2;
      return aVal.compareTo(bVal);
    }));
    _initError = "";
    notifyListeners();
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
    _notificationClient.showUnreadMessagesNotification(messages.reversed);
    notifyListeners();
  }

  void clearUnreadsForFriend(Friend friend) {
    _unreads[friend.id]?.clear();
    notifyListeners();
  }

  List<Message> getUnreadsForFriend(Friend friend) => _unreads[friend.id] ?? [];

  bool friendHasUnreads(Friend friend) => _unreads.containsKey(friend.id);

  bool messageIsUnread(Message message) {
    return _unreads[message.senderId]?.any((element) => element.id == message.id) ?? false;
  }

  Friend? getAsFriend(String userId) => _friendsCache[userId];

  List<Friend> get cachedFriends => _sortedFriendsCache;

  Future<MessageCache> getMessageCache(String userId) async {
    var cache = _messageCache[userId];
    if (cache == null){
      cache = MessageCache(apiClient: _apiClient, userId: userId);
      await cache.loadInitialMessages();
      _messageCache[userId] = cache;
    }
    return cache;
  }

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
    _logger.warning("Neos Hub connection died with error '$error', reconnecting...");
    await start();
  }

  Future<void> start() async {
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

  void registerMessageListener(String userId, Function function) => _messageUpdateListeners[userId] = function;
  void unregisterMessageListener(String userId) => _messageUpdateListeners.remove(userId);
  void notifyMessageListener(String userId) => _messageUpdateListeners[userId]?.call();

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
        final cache = await getMessageCache(message.recipientId);
        cache.addMessage(message);
        notifyMessageListener(message.recipientId);
        break;
      case EventTarget.receiveMessage:
        final msg = args[0];
        final message = Message.fromMap(msg);
        final cache = await getMessageCache(message.senderId);
        cache.addMessage(message);
        if (!_messageUpdateListeners.containsKey(message.senderId)) {
          addUnread(message);
        }
        notifyMessageListener(message.senderId);
        break;
      case EventTarget.messagesRead:
        final messageIds = args[0]["ids"] as List;
        final recipientId = args[0]["recipientId"];
        final cache = await getMessageCache(recipientId ?? "");
        for (var id in messageIds) {
          cache.setMessageState(id, MessageState.read);
        }
        notifyMessageListener(recipientId);
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
    final cache = await getMessageCache(message.recipientId);
    cache.messages.add(message);
    notifyMessageListener(message.recipientId);
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
  }
}
