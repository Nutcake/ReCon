import 'dart:async';

import 'package:contacts_plus_plus/apis/user_api.dart';
import 'package:contacts_plus_plus/client_holder.dart';
import 'package:contacts_plus_plus/apis/friend_api.dart';
import 'package:contacts_plus_plus/apis/message_api.dart';
import 'package:contacts_plus_plus/models/friend.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:contacts_plus_plus/models/personal_profile.dart';
import 'package:contacts_plus_plus/widgets/default_error_widget.dart';
import 'package:contacts_plus_plus/widgets/expanding_input_fab.dart';
import 'package:contacts_plus_plus/widgets/friend_list_tile.dart';
import 'package:contacts_plus_plus/widgets/my_profile_dialog.dart';
import 'package:contacts_plus_plus/widgets/settings_page.dart';
import 'package:contacts_plus_plus/widgets/user_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class MenuItemDefinition {
  final String name;
  final IconData icon;
  final Function() onTap;

  const MenuItemDefinition({required this.name, required this.icon, required this.onTap});
}

class FriendsList extends StatefulWidget {
  const FriendsList({super.key});

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  static const Duration _autoRefreshDuration = Duration(seconds: 90);
  static const Duration _refreshTimeoutDuration = Duration(seconds: 30);
  Future<List<Friend>>? _friendsFuture;
  Future<PersonalProfile>? _userProfileFuture;
  Future<UserStatus>? _userStatusFuture;
  ClientHolder? _clientHolder;
  Timer? _autoRefresh;
  Timer? _refreshTimeout;
  String _searchFilter = "";

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _refreshTimeout?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final clientHolder = ClientHolder.of(context);
    if (_clientHolder != clientHolder) {
      _clientHolder = clientHolder;
      final mClient = _clientHolder!.messagingClient;
      mClient.registerUnreadListener(() {
        if (context.mounted) {
          setState(() {});
        } else {
          mClient.unregisterUnreadListener();
        }
      });
      _refreshFriendsList();
      final apiClient = _clientHolder!.apiClient;
      _userProfileFuture = UserApi.getPersonalProfile(apiClient);
    }
  }

  void _refreshFriendsList() {
    if (_refreshTimeout?.isActive == true) return;
    final apiClient = _clientHolder!.apiClient;
    _friendsFuture = FriendApi.getFriendsList(apiClient).then((Iterable<Friend> value) async {
      final unreadMessages = await MessageApi.getUserMessages(apiClient, unreadOnly: true);
      final mClient = _clientHolder?.messagingClient;
      if (mClient == null) return [];
      mClient.updateAllUnreads(unreadMessages.toList());

      final friends = value.toList()
        ..sort((a, b) {
          var aVal = mClient.friendHasUnreads(a) ? -3 : 0;
          var bVal = mClient.friendHasUnreads(b) ? -3 : 0;

          aVal -= a.userStatus.lastStatusChange.compareTo(b.userStatus.lastStatusChange);
          aVal += a.userStatus.onlineStatus.compareTo(b.userStatus.onlineStatus) * 2;
          return aVal.compareTo(bVal);
        });
      _autoRefresh?.cancel();
      _autoRefresh = Timer(_autoRefreshDuration, () => setState(() => _refreshFriendsList()));
      _refreshTimeout?.cancel();
      _refreshTimeout = Timer(_refreshTimeoutDuration, () {});
      _clientHolder?.messagingClient.updateFriendsCache(friends);
      return friends;
    });
    _userStatusFuture = UserApi.getUserStatus(apiClient, userId: apiClient.userId).then((value) async {
      if (value.onlineStatus == OnlineStatus.offline) {
        final newStatus = value.copyWith(
            onlineStatus: OnlineStatus.values[_clientHolder!.settingsClient.currentSettings.lastOnlineStatus.valueOrDefault]
        );
        await UserApi.setStatus(apiClient, status: newStatus);
        return newStatus;
      }
      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ClientHolder.of(context).apiClient;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacts++"),
        actions: [
          FutureBuilder(
            future: _userStatusFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final userStatus = snapshot.data as UserStatus;
                return PopupMenuButton<OnlineStatus>(
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.circle, size: 16, color: userStatus.onlineStatus.color,),
                        ),
                        Text(toBeginningOfSentenceCase(userStatus.onlineStatus.name) ?? "Unknown"),
                      ],
                    ),
                    onSelected: (OnlineStatus onlineStatus) async {
                      try {
                        final newStatus = userStatus.copyWith(onlineStatus: onlineStatus);
                        setState(() {
                          _userStatusFuture = Future.value(newStatus.copyWith(lastStatusChange: DateTime.now()));
                        });
                        final settingsClient = ClientHolder.of(context).settingsClient;
                        await UserApi.setStatus(apiClient, status: newStatus);
                        await settingsClient.changeSettings(settingsClient.currentSettings.copyWith(lastOnlineStatus: onlineStatus.index));
                      } catch (e, s) {
                        FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to set online-status.")));
                        setState(() {
                          _userStatusFuture = Future.value(userStatus);
                        });
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        OnlineStatus.values.where((element) => element != OnlineStatus.offline).map((item) =>
                            PopupMenuItem<OnlineStatus>(
                              value: item,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.circle, size: 16, color: item.color,),
                                  const SizedBox(width: 8,),
                                  Text(toBeginningOfSentenceCase(item.name)!),
                                ],
                              ),
                            ),
                        ).toList());
              } else if (snapshot.hasError) {
                return TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2)
                  ),
                  onPressed: () {
                    setState(() {
                      _userStatusFuture = null;
                    });
                    setState(() {
                      _userStatusFuture = UserApi.getUserStatus(apiClient, userId: apiClient.userId);
                    });
                  },
                  icon: const Icon(Icons.warning),
                  label: const Text("Retry"),
                );
              } else {
                return TextButton.icon(
                  style: TextButton.styleFrom(
                    disabledForegroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: null,
                  icon: Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 4),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  label: const Text("Loading"),
                );
              }
            }
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: PopupMenuButton<MenuItemDefinition>(
              icon: const Icon(Icons.more_vert),
              onSelected: (MenuItemDefinition itemDef) async {
                await itemDef.onTap();
              },
              itemBuilder: (BuildContext context) =>
                  [
                    MenuItemDefinition(
                      name: "Settings",
                      icon: Icons.settings,
                      onTap: () async {
                        _autoRefresh?.cancel();
                        await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
                        _autoRefresh = Timer(_autoRefreshDuration, () => setState(() => _refreshFriendsList()));
                      },
                    ),
                    MenuItemDefinition(
                      name: "Find Users",
                      icon: Icons.person_add,
                      onTap: () async {
                        bool changed = false;
                        _autoRefresh?.cancel();
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                UserSearch(
                                  onFriendsChanged: () => changed = true,
                                ),
                          ),
                        );
                        if (changed) {
                          _refreshTimeout?.cancel();
                          setState(() {
                            _refreshFriendsList();
                          });
                        } else {
                          _autoRefresh = Timer(_autoRefreshDuration, () => setState(() => _refreshFriendsList()));
                        }
                      },
                    ),
                    MenuItemDefinition(
                      name: "My Profile",
                      icon: Icons.person,
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return FutureBuilder(
                              future: _userProfileFuture,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final profile = snapshot.data as PersonalProfile;
                                  return MyProfileDialog(profile: profile);
                                } else if (snapshot.hasError) {
                                  return DefaultErrorWidget(
                                    title: "Failed to load personal profile.",
                                    onRetry: () {
                                      setState(() {
                                        _userProfileFuture = UserApi.getPersonalProfile(ClientHolder.of(context).apiClient);
                                      });
                                    },
                                  );
                                } else {
                                  return const Center(child: CircularProgressIndicator(),);
                                }
                              }
                            );
                          },
                        );
                      },
                    ),
                  ].map((item) =>
                      PopupMenuItem<MenuItemDefinition>(
                        value: item,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.name),
                            Icon(item.icon),
                          ],
                        ),
                      ),
                  ).toList(),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              _refreshFriendsList();
              await _friendsFuture; // Keep the indicator running until everything's loaded
            },
            child: FutureBuilder(
                future: _friendsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var friends = (snapshot.data as List<Friend>);
                    if (_searchFilter.isNotEmpty) {
                      friends = friends.where((element) =>
                          element.username.toLowerCase().contains(_searchFilter.toLowerCase())).toList();
                      friends.sort((a, b) => a.username.length.compareTo(b.username.length));
                    }
                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        final unreads = _clientHolder?.messagingClient.getUnreadsForFriend(friend) ?? [];
                        return FriendListTile(
                          friend: friend,
                          unreads: unreads.length,
                          onTap: () async {
                            if (unreads.isNotEmpty) {
                              final readBatch = MarkReadBatch(
                                senderId: _clientHolder!.apiClient.userId,
                                ids: unreads.map((e) => e.id).toList(),
                                readTime: DateTime.now(),
                              );
                              _clientHolder!.messagingClient.markMessagesRead(readBatch);
                            }
                            setState(() {
                              unreads.clear();
                            });
                          },
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    FlutterError.reportError(
                        FlutterErrorDetails(exception: snapshot.error!, stack: snapshot.stackTrace));
                    return DefaultErrorWidget(
                      message: "${snapshot.error}",
                      onRetry: () {
                        _refreshTimeout?.cancel();
                        setState(() {
                          _refreshFriendsList();
                        });
                      },
                    );
                  } else {
                    return const LinearProgressIndicator();
                  }
                }
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ExpandingInputFab(
              onInputChanged: (String text) {
                setState(() {
                  _searchFilter = text;
                });
              },
              onExpansionChanged: (expanded) {
                if (!expanded) {
                  setState(() {
                    _searchFilter = "";
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
