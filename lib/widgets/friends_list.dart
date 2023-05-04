import 'dart:async';

import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/apis/friend_api.dart';
import 'package:contacts_plus_plus/apis/message_api.dart';
import 'package:contacts_plus_plus/models/friend.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:contacts_plus_plus/widgets/default_error_widget.dart';
import 'package:contacts_plus_plus/widgets/expanding_input_fab.dart';
import 'package:contacts_plus_plus/widgets/friend_list_tile.dart';
import 'package:contacts_plus_plus/widgets/settings_page.dart';
import 'package:contacts_plus_plus/widgets/user_search.dart';
import 'package:flutter/material.dart';


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
  final _unreads = <String, List<Message>>{};
  Future<List<Friend>>? _friendsFuture;
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
      _refreshFriendsList();
    }
  }

  void _refreshFriendsList() {
    if (_refreshTimeout?.isActive == true) return;
    _friendsFuture = FriendApi.getFriendsList(_clientHolder!.apiClient).then((Iterable<Friend> value) async {
      final unreadMessages = await MessageApi.getUserMessages(_clientHolder!.apiClient, unreadOnly: true);
      _unreads.clear();

      for (final msg in unreadMessages) {
        if (msg.senderId != _clientHolder!.apiClient.userId) {
          final value = _unreads[msg.senderId];
          if (value == null) {
            _unreads[msg.senderId] = [msg];
          } else {
            value.add(msg);
          }
        }
      }

      final friends = value.toList()
        ..sort((a, b) {
          var aVal = _unreads.containsKey(a.id) ? -3 : 0;
          var bVal = _unreads.containsKey(b.id) ? -3 : 0;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacts++"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: PopupMenuButton<MenuItemDefinition>(
              icon: const Icon(Icons.more_vert),
              onSelected: (MenuItemDefinition itemDef) async {
                await itemDef.onTap();
              },
              itemBuilder: (BuildContext context) => [
                    MenuItemDefinition(name: "Settings", icon: Icons.settings, onTap: () async {
                      _autoRefresh?.cancel();
                      await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
                      _autoRefresh = Timer(_autoRefreshDuration, () => setState(() => _refreshFriendsList()));
                    }),
                    MenuItemDefinition(name: "Find Users", icon: Icons.person_add, onTap: () async {
                      _autoRefresh?.cancel();
                      await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const UserSearch()));
                      _autoRefresh = Timer(_autoRefreshDuration, () => setState(() => _refreshFriendsList()));

                    })
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
                      friends = friends.where((element) => element.username.contains(_searchFilter)).toList();
                      friends.sort((a, b) => a.username.length.compareTo(b.username.length));
                    }
                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        final unread = _unreads[friend.id] ?? [];
                        return FriendListTile(
                          friend: friend,
                          unreads: unread.length,
                          onTap: () async {
                            if (unread.isNotEmpty) {
                              final readBatch = MarkReadBatch(
                                senderId: _clientHolder!.apiClient.userId,
                                ids: unread.map((e) => e.id).toList(),
                                readTime: DateTime.now(),
                              );
                              _clientHolder!.messagingClient.markMessagesRead(readBatch);
                            }
                            setState(() {
                              unread.clear();
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
