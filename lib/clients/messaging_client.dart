import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
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
  static const Duration _awayAfter = Duration(seconds: 60);
  static final bool _idleDetection = Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  final ApiClient _apiClient;
  final Map<String, Friend> _contacts = {};
  final List<Friend> _sortedContactsCache = []; // Keep a sorted copy so as to not have to sort during build()
  final Map<String, MessageCache> _messageCache = {};
  final Map<String, List<Message>> _unreads = {};
  final Logger _logger = Logger("Messaging");
  final NotificationClient _notificationClient;
  final HubManager _hubManager = HubManager();
  final Map<String, Session> _sessionMap = {};
  final Set<String> _knownSessionKeys = {};
  final SettingsClient _settingsClient;
  final Queue<List<dynamic>> _statusUpdateQueue = Queue();
  final Map<String, Map<String, UserStatus>> _userStatuses = {};
  late final AppLifecycleListener _lifecycleListener;

  Friend? selectedFriend;
  Timer? _statusHeartbeat;
  Timer? _unreadSafeguard;
  String? _initStatus;
  OnlineStatus _onlineStatus = OnlineStatus.offline;
  UserStatus _broadcastStatus = UserStatus.initial();
  bool _isPresent = true;
  bool _lifecyclePresent = true;
  DateTime _lastPresence = DateTime.now();

  OnlineStatus get onlineStatus => _onlineStatus;

  UserStatus get userStatus => _broadcastStatus;

  bool _areContactsLoaded = false;

  bool get _isHidden => _onlineStatus == OnlineStatus.invisible || _onlineStatus == OnlineStatus.offline;

  MessagingClient({required this._apiClient, required this._notificationClient, required this._settingsClient}) {
    _lifecyclePresent = _isPresentState(WidgetsBinding.instance.lifecycleState);
    _isPresent = _lifecyclePresent;
    if (_idleDetection) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onGlobalPointer);
      HardwareKeyboard.instance.addHandler(_onKeyboardKey);
    }
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _onLifecycleStateChanged,
      onExitRequested: () async {
        _goOffline();
        await _hubManager.close();
        return AppExitResponse.exit;
      },
    );
    SessionApi.getSessions(_apiClient).then((sessions) async {
      _sessionMap.addEntries(sessions.whereNot((s) => s.id == null).map((s) => MapEntry(s.id!, s)));
      _redecodeAll();
    });
    _setupHub();
  }

  @override
  void dispose() {
    if (_idleDetection) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_onGlobalPointer);
      HardwareKeyboard.instance.removeHandler(_onKeyboardKey);
    }
    _goOffline();
    _lifecycleListener.dispose();
    _statusHeartbeat?.cancel();
    _unreadSafeguard?.cancel();
    _hubManager.dispose();
    super.dispose();
  }

  String? get initStatus => _initStatus;

  List<Friend> get cachedFriends => _sortedContactsCache;

  List<Message> getUnreadsForFriend(Friend friend) => _unreads[friend.contactUserId] ?? [];

  bool friendHasUnreads(Friend friend) => _unreads.containsKey(friend.contactUserId);

  bool messageIsUnread(Message message) => _unreads[message.senderId]?.any((element) => element.id == message.id) ?? false;

  Friend? getAsContact(String userId) => _contacts[userId];

  MessageCache? getUserMessageCache(String userId) => _messageCache[userId];

  MessageCache _createUserMessageCache(String userId) => MessageCache(apiClient: _apiClient, userId: userId);

  List<Session> get knownSessions => _sessionMap.values.toList();

  List<Session> sessionsOf(String userId) => _userStatuses[userId]?.values.expand((s) => s.decodedSessions).toSet().toList() ?? [];

  static bool _isPresentState(AppLifecycleState? s) => s == null || s == AppLifecycleState.resumed || s == AppLifecycleState.inactive;

  void updateLastPresence() {
    _lastPresence = DateTime.now();
    if (!_isPresent) _recomputePresence();
  }

  void _onLifecycleStateChanged(AppLifecycleState state) {
    final present = _isPresentState(state);
    if (present == _lifecyclePresent) {
      return;
    }
    _lifecyclePresent = present;

    if (present) {
      _lastPresence = DateTime.now();
    }
    _recomputePresence();
    if (present && _areContactsLoaded) {
      _clearExpired();
      refreshContactsList();
    }
  }

  void _recomputePresence() {
    final present = _lifecyclePresent && !(_idleDetection && DateTime.now().difference(_lastPresence) >= _awayAfter);
    if (present == _isPresent) {
      return;
    }
    _isPresent = present;
    if (_areContactsLoaded) {
      _updateStatus();
    }
  }

  void _onGlobalPointer(PointerEvent _) => updateLastPresence();

  bool _onKeyboardKey(KeyEvent _) {
    updateLastPresence();
    return false;
  }

  UserStatus _decodeSessionsInStatus(UserStatus status) {
    final sessionMap = createSessionMap(status.hashSalt);
    return status.copyWith(decodedSessions: status.sessions.map((e) => sessionMap[e.sessionHash] ?? Session.none().copyWith(accessLevel: e.accessLevel)).toList());
  }

  Future<void> refreshContactsListWithErrorHandler() async {
    try {
      await refreshContactsList();
    } catch (e) {
      _initStatus = "$e";
      notifyListeners();
    }
  }

  Future<void> initFriendsList() async {
    _areContactsLoaded = false;
    _contacts.clear();
    _userStatuses.clear();
    _knownSessionKeys.clear();
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

    final pkginfo = await PackageInfo.fromPlatform();
    _broadcastStatus = _broadcastStatus.copyWith(userId: _apiClient.userId, isMobile: Platform.isAndroid || Platform.isIOS, appVersion: "${pkginfo.version} of ${pkginfo.appName}");
    _onlineStatus = OnlineStatus.values.elementAtOrNull(_settingsClient.currentSettings.lastOnlineStatus.valueOrDefault) ?? OnlineStatus.online;
    _hubManager.send("RequestStatus", arguments: [null, _onlineStatus == OnlineStatus.invisible]);
    _updateStatus(force: !_isHidden);

    _statusHeartbeat?.cancel();
    _statusHeartbeat = Timer.periodic(const Duration(seconds: 30), (timer) async {
      _recomputePresence();
      _updateStatus();
      _clearExpired();
    });

    await _refreshUnreads();
    _unreadSafeguard?.cancel();
    _unreadSafeguard = Timer.periodic(_unreadSafeguardDuration, (timer) => _refreshUnreads());
  }

  Future<void> refreshContactsList() async {
    _hubManager.send("RequestStatus", arguments: [null, onlineStatus == OnlineStatus.invisible]);
    _initStatus = "";
    notifyListeners();
  }

  Future<void> requestUserStatus(String userId) async {
    _hubManager.send("RequestStatus", arguments: [userId, onlineStatus == OnlineStatus.invisible]);
  }

  void sendMessage(Message message) {
    final msgBody = message.toMap();
    _hubManager.send("SendMessage", arguments: [msgBody]);
    (getUserMessageCache(message.recipientId) ?? _createUserMessageCache(message.recipientId)).addMessage(message);
    notifyListeners();
  }

  void markMessagesRead(MarkReadBatch batch) {
    if (_isHidden) return;
    final msgBody = batch.toMap();
    _hubManager.send("MarkMessagesRead", arguments: [msgBody]);
    clearUnreadsForUser(batch.senderId);
  }

  void _updateStatus({bool force = false}) {
    final hidden = _isHidden;
    final wasHidden = _broadcastStatus.onlineStatus == OnlineStatus.offline;
    final now = DateTime.now();
    final targetStatus = _onlineStatus == OnlineStatus.online && !_isPresent ? OnlineStatus.away : _onlineStatus;
    final changed = hidden ? !wasHidden : _broadcastStatus.onlineStatus != targetStatus || _broadcastStatus.isPresent != _isPresent;
    final heartbeatDue = !hidden && now.difference(_broadcastStatus.lastStatusChange) >= _statusHeartbeatDuration;
    if (!hidden && _isPresent && !_idleDetection) _lastPresence = now;
    if (!force && !changed && !heartbeatDue) return;

    _broadcastStatus = hidden
        ? _broadcastStatus.copyWith(onlineStatus: OnlineStatus.offline, isPresent: false, sessions: [], currentSessionIndex: -1, outputDevice: () => null, lastStatusChange: now)
        : _broadcastStatus.copyWith(onlineStatus: targetStatus, isPresent: _isPresent, lastPresenceTimestamp: _lastPresence, outputDevice: () => null, lastStatusChange: now);

    if (!(hidden && wasHidden)) {
      _hubManager.send(
        "BroadcastStatus",
        arguments: [
          _broadcastStatus.toMap(),
          {"group": 1, "targetIds": null},
        ],
      );
    }

    _applyStatus(_broadcastStatus);
  }

  void _onSendStatusToUser(List args) {
    final userId = args[0] as String;
    if (!_contacts.containsKey(userId)) return;
    _hubManager.send(
      "BroadcastStatus",
      arguments: [
        _broadcastStatus.toMap(),
        {
          "group": 2,
          "targetIds": [userId],
        },
      ],
    );
  }

  void _clearExpired() {
    var changed = false;
    _userStatuses.forEach((userId, sessions) {
      final lengthBefore = sessions.length;
      sessions.removeWhere((_, s) => s.isExpired);
      if (sessions.length != lengthBefore) {
        final contact = _contacts[userId];
        if (contact != null) {
          _setContactFinalStatus(contact);
        }
        changed = true;
      }
    });
    _userStatuses.removeWhere((_, s) => s.isEmpty);
    if (changed) {
      notifyListeners();
    }
  }

  void _goOffline() {
    _onlineStatus = OnlineStatus.offline;
    try {
      _updateStatus();
    } catch (_) {}
  }

  void setOnlineStatus(OnlineStatus status) {
    _onlineStatus = status;
    _updateStatus(force: true);
    notifyListeners();
  }

  Future<Friend> addContact(User user) async {
    final friend = Friend.empty().copyWith(ownerId: _apiClient.userId, contactUserId: user.id, contactUsername: user.username, contactStatus: ContactStatus.accepted);
    if (!await _hubUpdateContact(friend)) {
      throw "Failed to add contact";
    }
    return friend;
  }

  Future<bool> removeContact(Friend friend) async {
    return _hubUpdateContact(friend.copyWith(contactStatus: ContactStatus.ignored));
  }

  Future<bool> _hubUpdateContact(Friend friend) async {
    final response = await _hubManager.sendAndWait<bool>("UpdateContact", arguments: [friend.toMap()]) ?? false;
    if (response) {
      await _updateContact(friend.copyWith(userStatus: _contacts[friend.contactUserId]?.userStatus));
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
      usernames[uid] = getAsContact(uid)?.contactUsername ?? uid;
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
    _sortedContactsCache
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
    final sIndex = _sortedContactsCache.indexWhere((element) => element.contactUserId == friend.contactUserId);
    if (sIndex == -1) {
      _sortedContactsCache.add(friend);
    } else {
      _sortedContactsCache[sIndex] = friend;
    }
    if (friend.contactUserId == selectedFriend?.contactUserId) {
      selectedFriend = friend;
    }
    _sortFriendsCache();
  }

  bool _applyStatus(UserStatus status) {
    final contact = _contacts[status.userId];
    if (contact == null) return false;
    if (status.isExpired) {
      _logger.info("Received expired status for user ${status.userId}");
      return false;
    }
    final sessions = _userStatuses.putIfAbsent(status.userId, () => {});
    final existing = sessions[status.userSessionId];
    if (existing != null && !status.lastStatusChange.isAfter(existing.lastStatusChange)) return false;
    sessions[status.userSessionId] = status;
    _setContactFinalStatus(contact);
    return true;
  }

  void _setContactFinalStatus(Friend contact) {
    UserStatus? dominant;
    for (final s in _userStatuses[contact.contactUserId]?.values ?? const <UserStatus>[]) {
      if (s.isDominantOver(dominant)) {
        dominant = s;
      }
    }
    var aggregate = dominant ?? UserStatus.defaultFor(contact.contactUserId);
    if (contact.contactUserId == Friend.resoniteBotId) {
      aggregate = aggregate.copyWith(onlineStatus: OnlineStatus.online);
    }
    _updateContact(contact.copyWith(userStatus: aggregate));
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
      ..setHandler(EventTarget.sendStatusToUser, _onSendStatusToUser)
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

  void _onSessionChanged(String sessionId, Session? session) {
    final dirty = <String>{};
    for (final MapEntry(key: userId, value: statuses) in _userStatuses.entries) {
      for (final userSessionId in statuses.keys.toList()) {
        final status = statuses[userSessionId]!;
        final hash = CryptoHelper.idHash(sessionId + status.hashSalt);
        final index = status.sessions.indexWhere((m) => m.sessionHash == hash);
        if (index == -1) continue;
        final decoded = [...status.decodedSessions];
        decoded[index] = session ?? Session.none().copyWith(accessLevel: status.sessions[index].accessLevel);
        statuses[userSessionId] = status.copyWith(decodedSessions: decoded);
        dirty.add(userId);
      }
    }
    for (final userId in dirty) {
      final contact = _contacts[userId];
      if (contact != null) _setContactFinalStatus(contact);
    }
    if (dirty.isNotEmpty) notifyListeners();
  }

  void _redecodeAll() {
    _userStatuses.forEach((userId, statuses) {
      statuses.updateAll((_, s) => _decodeSessionsInStatus(s));
      final contact = _contacts[userId];
      if (contact != null) _setContactFinalStatus(contact);
    });
    notifyListeners();
  }

  void _onReceiveStatusUpdate(List args) {
    if (!_areContactsLoaded) {
      _statusUpdateQueue.add(args);
      _logger.info("Deferring status update to after contacts are loaded");
      return;
    }
    var status = _decodeSessionsInStatus(UserStatus.fromMap(args[0] as Map));
    final sessionMap = createSessionMap(status.hashSalt);
    status = status.copyWith(decodedSessions: status.sessions.map((e) => sessionMap[e.sessionHash] ?? Session.none().copyWith(accessLevel: e.accessLevel)).toList());
    if (!_applyStatus(status)) {
      return;
    }
    for (final session in status.sessions) {
      final key = session.broadcastKey;
      if (key != null && _knownSessionKeys.add(key)) {
        _hubManager.send("ListenOnKey", arguments: [key]);
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
      _onSessionChanged(session.id!, session);
      notifyListeners();
    }
  }

  void _onRemoveSession(List args) {
    final sessionId = args[0] as String;
    _sessionMap.remove(sessionId);
    _onSessionChanged(sessionId, null);
    notifyListeners();
  }
}
