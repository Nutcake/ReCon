import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:recon/apis/message_api.dart';
import 'package:recon/apis/session_api.dart';
import 'package:recon/clients/api_client.dart';
import 'package:recon/clients/notification_client.dart';
import 'package:recon/clients/settings_client.dart';
import 'package:recon/crypto_helper.dart';
import 'package:recon/hub_manager.dart';
import 'package:recon/models/hub_events.dart';
import 'package:recon/models/message.dart';
import 'package:recon/models/session.dart';
import 'package:recon/models/users/friend.dart';
import 'package:recon/models/users/friend_status.dart';
import 'package:recon/models/users/online_status.dart';
import 'package:recon/models/users/user.dart';
import 'package:recon/models/users/user_status.dart';

class MessagingClient extends ChangeNotifier {
  static const Duration _unreadSafeguardDuration = Duration(seconds: 120);
  static const Duration _statusHeartbeatDuration = Duration(seconds: 150);

  final ApiClient _apiClient;
  final Map<String, Friend> _contacts = {};
  final List<Friend> _sortedFriendsCache = []; // Keep a sorted copy so as to not have to sort during build()
  final Map<String, MessageCache> _messageCache = {};
  final Map<String, List<Message>> _unreads = {};
  final Logger _logger = Logger("Messaging");
  final NotificationClient _notificationClient;
  final HubManager _hubManager = HubManager();
  final Map<String, Session> _sessionMap = {};
  final Set<String> _knownSessionKeys = {};
  final SettingsClient _settingsClient;
  final Queue<List<dynamic>> _statusUpdateQueue = Queue();
  Friend? selectedFriend;

  Timer? _statusHeartbeat;
  Timer? _unreadSafeguard;
  String? _initStatus;
  UserStatus _userStatus = UserStatus.initial();
  DateTime _lastStatusChange = DateTime.fromMillisecondsSinceEpoch(0);

  UserStatus get userStatus => _userStatus;

  bool _areContactsLoaded = false;

  MessagingClient({
    required this._apiClient,
    required this._notificationClient,
    required this._settingsClient,
  }) {
    _apiClient.addLogoutListener(dispose);

    SessionApi.getSessions(_apiClient).then(
      (sessions) async {
        try {
          _sessionMap.addEntries(sessions.whereNot((s) => s.id == null).map((s) => MapEntry(s.id!, s)));
        } catch (e, s) {
          _logger.severe("Failed to initialize session list", e, s);
        }
      },
    );
    _setupHub();
  }

  @override
  void dispose() {
    _statusHeartbeat?.cancel();
    _unreadSafeguard?.cancel();
    _hubManager.dispose();
    super.dispose();
  }

  String? get initStatus => _initStatus;

  List<Friend> get cachedFriends => _sortedFriendsCache;

  List<Message> getUnreadsForFriend(Friend friend) => _unreads[friend.contactUserId] ?? [];

  bool friendHasUnreads(Friend friend) => _unreads.containsKey(friend.contactUserId);

  bool messageIsUnread(Message message) => _unreads[message.senderId]?.any((element) => element.id == message.id) ?? false;

  Friend? getAsFriend(String userId) => _contacts[userId];

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

  Future<void> initFriendsList() async {
    _areContactsLoaded = false;
    _contacts.clear();
    var count = 0;
    try {
      await for (final raw in _hubManager.stream("InitializeContacts")) {
        _initStatus = "";
        final friend = Friend.fromMap(raw);
        _contacts[friend.contactUserId] = friend;
        count++;
        if (count % 10 == 0) {
          _sortFriendsCache();
          notifyListeners();
        }
      }
    } catch (e) {
      _initStatus = "$e";
      notifyListeners();
      return;
    }
    _sortFriendsCache();
    _initStatus = "";
    _areContactsLoaded = true;
    notifyListeners();

    _statusUpdateQueue
      ..forEach(_onReceiveStatusUpdate)
      ..clear();

    final lastOnline = OnlineStatus.values.elementAtOrNull(_settingsClient.currentSettings.lastOnlineStatus.valueOrDefault);
    _hubManager.send("RequestStatus", arguments: [null, lastOnline == OnlineStatus.invisible]);
    await setOnlineStatus(lastOnline ?? OnlineStatus.online, broadcast: lastOnline != OnlineStatus.invisible);
    _statusHeartbeat?.cancel();
    _statusHeartbeat = Timer.periodic(_statusHeartbeatDuration, (timer) async {
      await setOnlineStatus(_userStatus.onlineStatus, broadcast: _userStatus.onlineStatus != OnlineStatus.invisible && _userStatus.onlineStatus != OnlineStatus.offline);
    });
    await _refreshUnreads();
    _unreadSafeguard?.cancel();
    _unreadSafeguard = Timer.periodic(_unreadSafeguardDuration, (timer) => _refreshUnreads());
  }

  Future<void> refreshFriendsList() async {
    final self = getAsFriend(_apiClient.userId);
    _hubManager.send("RequestStatus", arguments: [null, self?.userStatus.onlineStatus == OnlineStatus.invisible]);
    _initStatus = "";
    notifyListeners();
  }

  Future<void> requestUserStatus(String userId) async {
    final self = getAsFriend(_apiClient.userId);
    _hubManager.send("RequestStatus", arguments: [userId, self?.userStatus.onlineStatus == OnlineStatus.invisible]);
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

  Future<void> setOnlineStatus(OnlineStatus status, {bool broadcast = true}) async {
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
    if (broadcast) {
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
    }
    final self = getAsFriend(_apiClient.userId);
    if (self != null) {
      await _updateContact(self.copyWith(userStatus: _userStatus));
    }
    notifyListeners();
  }

  Future<Friend> addContact(User user) async {
    final friend = Friend.empty().copyWith(
      ownerId: _apiClient.userId,
      contactUserId: user.id,
      contactUsername: user.username,
      contactStatus: ContactStatus.accepted,
    );
    if (!await _hubUpdateContact(friend)) {
      throw "Failed to add contact";
    }
    return friend;
  }

  Future<bool> removeContact(Friend friend) async {
    return _hubUpdateContact(
      friend.copyWith(
        contactStatus: ContactStatus.ignored,
      ),
    );
  }

  Future<bool> _hubUpdateContact(Friend friend) async {
    final response = await _hubManager.sendAndWait<bool>(
          "UpdateContact",
          arguments: [
            friend.toMap(),
          ],
        ) ??
        false;
    if (response) {
      await _updateContact(friend);
    }
    return response;
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
    final usernames = <String, String>{};
    for (final msg in messages) {
      final uid = msg.senderId;
      usernames[uid] = getAsFriend(uid)?.contactUsername ?? uid;
    }

    _notificationClient.showUnreadMessagesNotification(messages.reversed, usernames);
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
    _sortedFriendsCache
      ..clear()
      ..addAll(_contacts.values)
      ..removeWhere((element) => element.contactStatus != ContactStatus.accepted)
      ..sort((a, b) {
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

  Future<void> _updateContact(Friend friend) async {
    _contacts[friend.contactUserId] = friend;
    if (friend.userStatus.lastStatusChange.isAfter(_lastStatusChange)) {
      _lastStatusChange = friend.userStatus.lastStatusChange;
    }
    final sIndex = _sortedFriendsCache.indexWhere((element) => element.contactUserId == friend.contactUserId);
    if (sIndex == -1) {
      _sortedFriendsCache.add(friend);
    } else {
      _sortedFriendsCache[sIndex] = friend;
    }
    if (friend.contactUserId == selectedFriend?.contactUserId) {
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
      ..setHandler(
        EventTarget.messagesRead,
        _onMessagesRead,
      )
      ..setHandler(EventTarget.receiveStatusUpdate, _onReceiveStatusUpdate)
      ..setHandler(
        EventTarget.receiveSessionUpdate,
        _onReceiveSessionUpdate,
      )
      ..setHandler(EventTarget.removeSession, _onRemoveSession)
      ..onConnected = initFriendsList;
    await _hubManager.start();
  }

  Map<String, Session> createSessionMap(String salt) {
    return _sessionMap.map((key, value) => MapEntry(CryptoHelper.idHash(value.id! + salt), value));
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
    if (message.senderId != selectedFriend?.contactUserId) {
      addUnread(message);
      requestUserStatus(message.senderId);
    } else {
      markMessagesRead(MarkReadBatch(senderId: message.senderId, ids: [message.id], readTime: DateTime.now()));
    }
    notifyListeners();
  }

  void _onMessagesRead(List args) {
    final maps = args.cast<Map>();
    final messageIds = maps[0]["ids"] as List;
    final recipientId = maps[0]["recipientId"];
    if (recipientId == null) return;
    final cache = getUserMessageCache(recipientId);
    if (cache == null) return;
    for (final id in messageIds) {
      cache.setMessageState(id, MessageState.read);
    }
    notifyListeners();
  }

  void _onReceiveStatusUpdate(List args) {
    if (!_areContactsLoaded) {
      _statusUpdateQueue.add(args);
      _logger.info("Deferring status update to after contacts are loaded");
      return;
    }
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
    if (session.id == null) {
      return;
    }
    final oldSession = _sessionMap[session.id!];
    _sessionMap[session.id!] = session;
    if (oldSession != session) {
      notifyListeners();
    }
  }

  void _onRemoveSession(List args) {
    final session = args[0];
    _sessionMap.remove(session);
    notifyListeners();
  }
}
