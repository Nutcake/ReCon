import 'dart:async';

import 'package:recon/apis/contact_api.dart';
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
import 'package:recon/models/users/contact.dart';
import 'package:recon/models/users/online_status.dart';
import 'package:recon/models/users/user.dart';
import 'package:recon/models/users/user_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MessagingClient extends ChangeNotifier {
  static const Duration _autoRefreshDuration = Duration(seconds: 10);
  static const Duration _unreadSafeguardDuration = Duration(seconds: 120);
  static const Duration _statusHeartbeatDuration = Duration(seconds: 150);
  static const String _messageBoxKey = "message-box";
  static const String _lastUpdateKey = "__last-update-time";

  final ApiClient _apiClient;
  final List<Contact> _sortedFriendsCache = []; // Keep a sorted copy so as to not have to sort during build()
  final Map<String, MessageCache> _messageCache = {};
  final Map<String, List<Message>> _unreads = {};
  final Logger _logger = Logger("Messaging");
  final NotificationClient _notificationClient;
  final HubManager _hubManager = HubManager();
  final Map<String, Session> _sessionMap = {};
  final Set<String> _knownSessionKeys = {};
  final SettingsClient _settingsClient;
  Contact? selectedFriend;

  Timer? _statusHeartbeat;
  Timer? _autoRefresh;
  Timer? _unreadSafeguard;
  String? _initStatus;
  UserStatus _userStatus = UserStatus.initial();

  UserStatus get userStatus => _userStatus;

  MessagingClient(
      {required ApiClient apiClient,
      required NotificationClient notificationClient,
      required SettingsClient settingsClient})
      : _apiClient = apiClient,
        _notificationClient = notificationClient,
        _settingsClient = settingsClient {
    debugPrint("mClient created: $hashCode");
    Hive.openBox(_messageBoxKey).then((box) async {
      await box.delete(_lastUpdateKey);
      final sessions = await SessionApi.getSessions(_apiClient);
      _sessionMap.addEntries(sessions.map((e) => MapEntry(e.id, e)));
      _setupHub();
    });
  }

  @override
  void dispose() {
    debugPrint("mClient disposed: $hashCode");
    _autoRefresh?.cancel();
    _statusHeartbeat?.cancel();
    _unreadSafeguard?.cancel();
    _hubManager.dispose();
    super.dispose();
  }

  String? get initStatus => _initStatus;

  List<Contact> get cachedFriends => _sortedFriendsCache;

  List<Message> getUnreadsForFriend(Contact friend) => _unreads[friend.id] ?? [];

  bool friendHasUnreads(Contact friend) => _unreads.containsKey(friend.id);

  bool messageIsUnread(Message message) =>
      _unreads[message.senderId]?.any((element) => element.id == message.id) ?? false;

  Contact? getAsFriend(String userId) => Contact.fromMapOrNull(Hive.box(_messageBoxKey).get(userId));

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
    DateTime? lastUpdateUtc = Hive.box(_messageBoxKey).get(_lastUpdateKey);
    _autoRefresh?.cancel();
    _autoRefresh = Timer(_autoRefreshDuration, () => refreshFriendsList());

    final friends = await ContactApi.getFriendsList(_apiClient, lastStatusUpdate: lastUpdateUtc);
    for (final friend in friends) {
      await _updateContactLocal(friend);
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
      await _updateContactLocal(self.copyWith(userStatus: _userStatus));
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
    await _updateContactLocal(friend.copyWith(userStatus: newStatus));
    notifyListeners();
  }

  void resetInitStatus() {
    _initStatus = null;
    notifyListeners();
  }

  void addUserAsFriend(User user) {
    _hubManager.send("UpdateContact", arguments: [user.asContactRequest(_apiClient.userId)]);
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

  Future<void> _updateContactLocal(Contact friend) async {
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
    _hubManager.setHandler(EventTarget.removeSession, _onRemoveSession);

    await _hubManager.start();
    _hubManager.send(
      "InitializeStatus",
      responseHandler: (Map data) async {
        final rawContacts = data["contacts"] as List;
        final contacts = rawContacts.map((e) => Contact.fromMap(e)).toList();
        for (final contact in contacts) {
          await _updateContactLocal(contact);
        }
        _initStatus = "";
        notifyListeners();
        await _refreshUnreads();
        _unreadSafeguard = Timer.periodic(_unreadSafeguardDuration, (timer) => _refreshUnreads());
        _hubManager.send("RequestStatus", arguments: [null, false]);
        final lastOnline =
            OnlineStatus.values.elementAtOrNull(_settingsClient.currentSettings.lastOnlineStatus.valueOrDefault);
        await setOnlineStatus(lastOnline ?? OnlineStatus.online);
        _statusHeartbeat = Timer.periodic(_statusHeartbeatDuration, (timer) {
          setOnlineStatus(_userStatus.onlineStatus);
        });
      },
    );
  }

  Map<String, Session> createSessionMap(String salt) {
    return _sessionMap.map((key, value) => MapEntry(CryptoHelper.idHash(value.id + salt), value));
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
    final statusUpdate = args[0];
    var status = UserStatus.fromMap(statusUpdate);
    final sessionMap = createSessionMap(status.hashSalt);
    status = status.copyWith(
        decodedSessions: status.sessions
            .map((e) => sessionMap[e.sessionHash] ?? Session.none().copyWith(accessLevel: e.accessLevel))
            .toList());
    final friend = getAsFriend(statusUpdate["userId"])?.copyWith(userStatus: status);
    if (friend != null) {
      _updateContactLocal(friend);
    }
    for (var session in status.sessions) {
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
