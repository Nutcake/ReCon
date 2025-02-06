import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:recon/apis/message_api.dart';
import 'package:recon/apis/session_api.dart';
import 'package:recon/apis/user_api.dart';
import 'package:recon/clients/api_client.dart';
import 'package:recon/clients/notification_client.dart';
import 'package:recon/clients/settings_client.dart';
import 'package:recon/crypto_helper.dart';
import 'package:recon/hub_manager.dart';
import 'package:recon/models/hub_events.dart';
import 'package:recon/models/message.dart';
import 'package:recon/models/session.dart';
import 'package:recon/models/users/friend.dart';
import 'package:recon/models/users/online_status.dart';
import 'package:recon/models/users/user_status.dart';

class MessagingClient extends ChangeNotifier {
  static const Duration _unreadSafeguardDuration = Duration(seconds: 120);
  static const Duration _statusHeartbeatDuration = Duration(seconds: 150);
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
  final Set<String> _knownSessionKeys = {};
  final SettingsClient _settingsClient;
  Friend? selectedFriend;

  Timer? _statusHeartbeat;
  Timer? _unreadSafeguard;
  String? _initStatus;
  UserStatus _userStatus = UserStatus.initial();

  UserStatus get userStatus => _userStatus;

  MessagingClient({
    required ApiClient apiClient,
    required NotificationClient notificationClient,
    required SettingsClient settingsClient,
  })  : _apiClient = apiClient,
        _notificationClient = notificationClient,
        _settingsClient = settingsClient {
    debugPrint("mClient created: $hashCode");
    Hive.openBox(_messageBoxKey).then((box) async {
      await box.delete(_lastUpdateKey);
      final sessions = await SessionApi.getSessions(_apiClient);
      _sessionMap.addEntries(sessions.map((e) => MapEntry(e.id, e)));
      await _setupHub();
    });
  }

  @override
  void dispose() {
    debugPrint("mClient disposed: $hashCode");
    _statusHeartbeat?.cancel();
    _unreadSafeguard?.cancel();
    _hubManager.dispose();
    super.dispose();
  }

  String? get initStatus => _initStatus;

  List<Friend> get cachedFriends => _sortedFriendsCache;

  List<Message> getUnreadsForFriend(Friend friend) => _unreads[friend.id] ?? [];

  bool friendHasUnreads(Friend friend) => _unreads.containsKey(friend.id);

  bool messageIsUnread(Message message) => _unreads[message.senderId]?.any((element) => element.id == message.id) ?? false;

  Friend? getAsFriend(String userId) => Friend.fromMapOrNull(Hive.box(_messageBoxKey).get(userId));

  MessageCache? getUserMessageCache(String userId) => _messageCache[userId];

  MessageCache _createUserMessageCache(String userId) => MessageCache(apiClient: _apiClient, userId: userId);

  Future<void> refreshFriendsListWithErrorHandler() async {
    try {
      await refreshFriendsList();
    } catch (e) {
      _initStatus = "$e";
      notifyListeners();
    }
  }

  Future<void> refreshFriendsList() async {
    _hubManager.send(
      "InitializeStatus",
      responseHandler: (data) async {
        final rawContacts = data["contacts"] as List;
        final contacts = rawContacts.map((e) => Friend.fromMap(e)).toList();
        await _updateContacts(contacts);
        _initStatus = "";
        notifyListeners();
        await _refreshUnreads();
        _unreadSafeguard?.cancel();
        _unreadSafeguard = Timer.periodic(_unreadSafeguardDuration, (timer) => _refreshUnreads());
        _hubManager.send("RequestStatus", arguments: [null, false]);
        final lastOnline = OnlineStatus.values.elementAtOrNull(_settingsClient.currentSettings.lastOnlineStatus.valueOrDefault);
        await setOnlineStatus(lastOnline ?? OnlineStatus.online);
        _statusHeartbeat?.cancel();
        _statusHeartbeat = Timer.periodic(_statusHeartbeatDuration, (timer) {
          setOnlineStatus(_userStatus.onlineStatus);
        });
      },
    );

    _initStatus = "";
    notifyListeners();
  }

  void sendMessage(Message message) {
    final msgBody = message.toMap();
    _hubManager.send("SendMessage", arguments: [msgBody]);
    (getUserMessageCache(message.recipientId) ?? _createUserMessageCache(message.recipientId)).addMessage(message);
    notifyListeners();
  }

  void markMessagesRead(MarkReadBatch batch) {
    if (_userStatus.onlineStatus == OnlineStatus.invisible || _userStatus.onlineStatus == OnlineStatus.offline) return;
    final msgBody = batch.toMap();
    _hubManager.send("MarkMessagesRead", arguments: [msgBody]);
    clearUnreadsForUser(batch.senderId);
  }

  Future<void> setOnlineStatus(OnlineStatus status) async {
    final pkginfo = await PackageInfo.fromPlatform();
    final now = DateTime.now();
    _userStatus = _userStatus.copyWith(
      userId: _apiClient.userId,
      appVersion: "${pkginfo.version} of ${pkginfo.appName}",
      lastPresenceTimestamp: now,
      lastStatusChange: now,
      onlineStatus: status,
      isPresent: true,
    );

    _hubManager.send(
      "BroadcastStatus",
      arguments: [
        _userStatus.toMap(),
        {
          "group": 1,
          "targetIds": null,
        }
      ],
    );

    final self = getAsFriend(_apiClient.userId);
    if (self != null) {
      await _updateContact(self.copyWith(userStatus: _userStatus));
    }
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

  // Calculate online status value, with 'headless' between 'busy' and 'offline'
  double getOnlineStatusValue(Friend friend) {
    // Adjusting values to ensure correct placement of 'headless'
    if (friend.isHeadless) return 3.5;
    switch (friend.userStatus.onlineStatus) {
      case OnlineStatus.sociable:
        return 0;
      case OnlineStatus.online:
        return 1;
      case OnlineStatus.away:
        return 2;
      case OnlineStatus.busy:
        return 3;
      case OnlineStatus.invisible:
        return 3.5;
      case OnlineStatus.offline:
        return 4;
    }
  }

  void _sortFriendsCache() {
    _sortedFriendsCache.sort((a, b) {
      // Check for unreads and sort by latest message time if either has unreads
      final aHasUnreads = friendHasUnreads(a);
      final bHasUnreads = friendHasUnreads(b);
      if (aHasUnreads || bHasUnreads) {
        if (aHasUnreads && bHasUnreads) {
          return -a.latestMessageTime.compareTo(b.latestMessageTime);
        }

        return aHasUnreads ? -1 : 1;
      }

      final onlineStatusComparison = getOnlineStatusValue(a).compareTo(getOnlineStatusValue(b));
      if (onlineStatusComparison != 0) {
        return onlineStatusComparison;
      }

      return -a.latestMessageTime.compareTo(b.latestMessageTime);
    });
  }

  Future<void> _updateContacts(List<Friend> friends) async {
    final box = Hive.box(_messageBoxKey);
    for (final friend in friends) {
      await box.put(friend.id, friend.toMap());
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
    }
    _sortFriendsCache();
  }

  Future<void> _updateContact(Friend friend) async {
    final box = Hive.box(_messageBoxKey);
    await box.put(friend.id, friend.toMap());
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
    _hubManager
      ..setHeaders(_apiClient.authorizationHeader)
      ..setHandler(EventTarget.messageSent, _onMessageSent)
      ..setHandler(EventTarget.receiveMessage, _onReceiveMessage)
      ..setHandler(EventTarget.messagesRead, _onMessagesRead)
      ..setHandler(EventTarget.receiveStatusUpdate, _onReceiveStatusUpdate)
      ..setHandler(EventTarget.receiveSessionUpdate, _onReceiveSessionUpdate)
      ..setHandler(EventTarget.removeSession, _onRemoveSession)
      ..onConnected = refreshFriendsList;
    await _hubManager.start();
  }

  Map<String, Session> createSessionMap(String salt) {
    return _sessionMap.map((key, value) => MapEntry(CryptoHelper.idHash(value.id + salt), value));
  }

  void _onMessageSent(List args) {
    final msg = args[0];
    final message = Message.fromMap(msg, withState: MessageState.sent);
    (getUserMessageCache(message.recipientId) ?? _createUserMessageCache(message.recipientId)).addMessage(message);
    notifyListeners();
  }

  void _onReceiveMessage(List args) {
    final msg = args[0];
    final message = Message.fromMap(msg);
    (getUserMessageCache(message.senderId) ?? _createUserMessageCache(message.senderId)).addMessage(message);
    if (message.senderId != selectedFriend?.id) {
      addUnread(message);
      updateFriendStatus(message.senderId);
    } else {
      markMessagesRead(MarkReadBatch(senderId: message.senderId, ids: [message.id], readTime: DateTime.now()));
    }
    notifyListeners();
  }

  void _onMessagesRead(List args) {
    args = args as List<Map>;
    final messageIds = args[0]["ids"] as List;
    final recipientId = args[0]["recipientId"];
    if (recipientId == null) return;
    final cache = getUserMessageCache(recipientId);
    if (cache == null) return;
    for (final id in messageIds) {
      cache.setMessageState(id, MessageState.read);
    }
    notifyListeners();
  }

  void _onReceiveStatusUpdate(List args) {
    final statusUpdate = args[0] as Map;
    var status = UserStatus.fromMap(statusUpdate);
    final sessionMap = createSessionMap(status.hashSalt);
    status = status.copyWith(
      decodedSessions: status.sessions.map((e) => sessionMap[e.sessionHash] ?? Session.none().copyWith(accessLevel: e.accessLevel)).toList(),
    );
    final friend = getAsFriend(statusUpdate["userId"])?.copyWith(userStatus: status);
    if (friend != null) {
      _updateContact(friend);
    }
    for (final session in status.sessions) {
      if (session.broadcastKey != null && _knownSessionKeys.add(session.broadcastKey ?? "")) {
        _hubManager.send("ListenOnKey", arguments: [session.broadcastKey]);
      }
    }
    notifyListeners();
  }

  void _onReceiveSessionUpdate(List args) {
    final sessionUpdate = args[0];
    final session = Session.fromMap(sessionUpdate);
    _sessionMap[session.id] = session;
    notifyListeners();
  }

  void _onRemoveSession(List args) {
    final session = args[0];
    _sessionMap.remove(session);
    notifyListeners();
  }
}
