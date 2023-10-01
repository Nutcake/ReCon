import 'dart:async';
import 'package:contacts_plus_plus/apis/session_api.dart';
import 'package:contacts_plus_plus/crypto_helper.dart';
import 'package:contacts_plus_plus/hub_manager.dart';
import 'package:contacts_plus_plus/models/session.dart';
import 'package:contacts_plus_plus/models/users/user_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

import 'package:contacts_plus_plus/apis/contact_api.dart';
import 'package:contacts_plus_plus/apis/message_api.dart';
import 'package:contacts_plus_plus/apis/user_api.dart';
import 'package:contacts_plus_plus/clients/notification_client.dart';
import 'package:contacts_plus_plus/models/users/friend.dart';
import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum EventType {
  undefined,
  invocation,
  streamItem,
  completion,
  streamInvocation,
  cancelInvocation,
  ping,
  close;
}

enum EventTarget {
  unknown,
  messageSent,
  receiveMessage,
  messagesRead,
  receiveSessionUpdate,
  removeSession,
  receiveStatusUpdate;

  factory EventTarget.parse(String? text) {
    if (text == null) return EventTarget.unknown;
    return EventTarget.values.firstWhere(
      (element) => element.name.toLowerCase() == text.toLowerCase(),
      orElse: () => EventTarget.unknown,
    );
  }
}

class MessagingClient extends ChangeNotifier {
  static const Duration _autoRefreshDuration = Duration(seconds: 10);
  static const Duration _unreadSafeguardDuration = Duration(seconds: 120);
  static const String _messageBoxKey = "message-box";
  static const String _lastUpdateKey = "__last-update-time";

  final ApiClient _apiClient;
  final List<Friend> _sortedFriendsCache = []; // Keep a sorted copy so as to not have to sort during build()
  final Map<String, MessageCache> _messageCache = {};
  final Map<String, List<Message>> _unreads = {};
  final Logger _logger = Logger("Messaging");
  final NotificationClient _notificationClient;
  final HubManager _hubManager = HubManager();
  final Map<String, Session> _sessionMap = {};
  Friend? selectedFriend;

  Timer? _notifyOnlineTimer;
  Timer? _autoRefresh;
  Timer? _unreadSafeguard;
  String? _initStatus;
  UserStatus _userStatus = UserStatus.initial();

  UserStatus get userStatus => _userStatus;

  MessagingClient({required ApiClient apiClient, required NotificationClient notificationClient})
      : _apiClient = apiClient,
        _notificationClient = notificationClient {
    debugPrint("mClient created: $hashCode");
    Hive.openBox(_messageBoxKey).then((box) async {
      await box.delete(_lastUpdateKey);
      final activeSessions = await SessionApi.getSessions(apiClient);
      for (final session in activeSessions) {
        final idHash = CryptoHelper.idHash(session.id + _userStatus.hashSalt);
        _sessionMap[idHash] = session;
      }
      _setupHub();
    });
  }

  @override
  void dispose() {
    debugPrint("mClient disposed: $hashCode");
    _autoRefresh?.cancel();
    _notifyOnlineTimer?.cancel();
    _unreadSafeguard?.cancel();
    _hubManager.dispose();
    super.dispose();
  }

  String? get initStatus => _initStatus;

  List<Friend> get cachedFriends => _sortedFriendsCache;

  List<Message> getUnreadsForFriend(Friend friend) => _unreads[friend.id] ?? [];

  bool friendHasUnreads(Friend friend) => _unreads.containsKey(friend.id);

  bool messageIsUnread(Message message) =>
      _unreads[message.senderId]?.any((element) => element.id == message.id) ?? false;

  Friend? getAsFriend(String userId) => Friend.fromMapOrNull(Hive.box(_messageBoxKey).get(userId));

  MessageCache? getUserMessageCache(String userId) => _messageCache[userId];

  MessageCache _createUserMessageCache(String userId) => MessageCache(apiClient: _apiClient, userId: userId);

  Session? getSessionInfo(String idHash) => _sessionMap[idHash];

  Future<void> refreshFriendsListWithErrorHandler() async {
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

    final friends = await ContactApi.getFriendsList(_apiClient, lastStatusUpdate: lastUpdateUtc);
    for (final friend in friends) {
      await _updateContact(friend);
    }

    _initStatus = "";
    notifyListeners();
  }

  void sendMessage(Message message) {
    final msgBody = message.toMap();
    _hubManager.send("SendMessage", arguments: [msgBody]);
    final cache = getUserMessageCache(message.recipientId) ?? _createUserMessageCache(message.recipientId);
    cache.addMessage(message);
    notifyListeners();
  }

  void markMessagesRead(MarkReadBatch batch) {
    final msgBody = batch.toMap();
    _hubManager.send("MarkMessagesRead", arguments: [msgBody]);
    clearUnreadsForUser(batch.senderId);
  }

  Future<void> setUserStatus(UserStatus status) async {
    final pkginfo = await PackageInfo.fromPlatform();

    _userStatus = status.copyWith(
      appVersion: "${pkginfo.version} of ${pkginfo.appName}",
      lastStatusChange: DateTime.now(),
    );

    _hubManager.send(
      "BroadcastStatus",
      arguments: [
        _userStatus.toMap(),
        {
          "group": 0,
          "targetIds": [],
        }
      ],
    );

    final self = getAsFriend(_apiClient.userId);
    await _updateContact(self!.copyWith(userStatus: _userStatus));
    notifyListeners();
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

  void clearUnreadsForUser(String userId) {
    _unreads[userId]?.clear();
    notifyListeners();
  }

  void deleteUserMessageCache(String userId) {
    _messageCache.remove(userId);
  }

  Future<void> loadUserMessageCache(String userId) async {
    final cache = getUserMessageCache(userId) ?? _createUserMessageCache(userId);
    await cache.loadMessages();
    _messageCache[userId] = cache;
    notifyListeners();
  }

  Future<void> updateFriendStatus(String userId) async {
    final friend = getAsFriend(userId);
    if (friend == null) return;
    final newStatus = await UserApi.getUserStatus(_apiClient, userId: userId);
    await _updateContact(friend.copyWith(userStatus: newStatus));
    notifyListeners();
  }

  void resetInitStatus() {
    _initStatus = null;
    notifyListeners();
  }

  Future<void> _refreshUnreads() async {
    try {
      final unreadMessages = await MessageApi.getUserMessages(_apiClient, unreadOnly: true);
      updateAllUnreads(unreadMessages.toList());
    } catch (_) {}
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

  Future<void> _updateContact(Friend friend) async {
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
    if (friend.id == selectedFriend?.id) {
      selectedFriend = friend;
    }
    _sortFriendsCache();
  }

  Future<void> _setupHub() async {
    if (!_apiClient.isAuthenticated) {
      _logger.info("Tried to connect to Resonite Hub without authentication, this is probably fine for now.");
      return;
    }
    _hubManager.setHeaders(_apiClient.authorizationHeader);

    _hubManager.setHandler(EventTarget.messageSent, _onMessageSent);
    _hubManager.setHandler(EventTarget.receiveMessage, _onReceiveMessage);
    _hubManager.setHandler(EventTarget.messagesRead, _onMessagesRead);
    _hubManager.setHandler(EventTarget.receiveStatusUpdate, _onReceiveStatusUpdate);
    _hubManager.setHandler(EventTarget.receiveSessionUpdate, _onReceiveSessionUpdate);

    await _hubManager.start();
    setUserStatus(userStatus);
    _hubManager.send(
      "InitializeStatus",
      responseHandler: (Map data) async {
        final rawContacts = data["contacts"] as List;
        final contacts = rawContacts.map((e) => Friend.fromMap(e)).toList();
        for (final contact in contacts) {
          await _updateContact(contact);
        }
        _initStatus = "";
        notifyListeners();
        await _refreshUnreads();
        _unreadSafeguard = Timer.periodic(_unreadSafeguardDuration, (timer) => _refreshUnreads());
        _hubManager.send("RequestStatus", arguments: [null, false]);
      },
    );
  }

  void _onMessageSent(List args) {
    final msg = args[0];
    final message = Message.fromMap(msg, withState: MessageState.sent);
    final cache = getUserMessageCache(message.recipientId) ?? _createUserMessageCache(message.recipientId);
    cache.addMessage(message);
    notifyListeners();
  }

  void _onReceiveMessage(List args) {
    final msg = args[0];
    final message = Message.fromMap(msg);
    final cache = getUserMessageCache(message.senderId) ?? _createUserMessageCache(message.senderId);
    cache.addMessage(message);
    if (message.senderId != selectedFriend?.id) {
      addUnread(message);
      updateFriendStatus(message.senderId);
    } else {
      markMessagesRead(MarkReadBatch(senderId: message.senderId, ids: [message.id], readTime: DateTime.now()));
    }
    notifyListeners();
  }

  void _onMessagesRead(List args) {
    final messageIds = args[0]["ids"] as List;
    final recipientId = args[0]["recipientId"];
    if (recipientId == null) return;
    final cache = getUserMessageCache(recipientId);
    if (cache == null) return;
    for (var id in messageIds) {
      cache.setMessageState(id, MessageState.read);
    }
    notifyListeners();
  }

  void _onReceiveStatusUpdate(List args) {
    for (final statusUpdate in args) {
      final status = UserStatus.fromMap(statusUpdate);
      var friend = getAsFriend(statusUpdate["userId"]);
      friend = friend?.copyWith(userStatus: status);
      if (friend != null) {
        _updateContact(friend);
      }
    }
    notifyListeners();
  }

  void _onReceiveSessionUpdate(List args) {
    for (final sessionUpdate in args) {
      final session = Session.fromMap(sessionUpdate);
      final idHash = CryptoHelper.idHash(session.id + _userStatus.hashSalt);
      _sessionMap[idHash] = session;
    }
    notifyListeners();
  }
}
