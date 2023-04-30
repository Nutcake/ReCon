import 'dart:async';

import 'package:contacts_plus/apis/friend_api.dart';
import 'package:contacts_plus/apis/user_api.dart';
import 'package:contacts_plus/main.dart';
import 'package:contacts_plus/models/friend.dart';
import 'package:contacts_plus/models/user.dart';
import 'package:contacts_plus/widgets/expanding_input_fab.dart';
import 'package:contacts_plus/widgets/friend_list_tile.dart';
import 'package:contacts_plus/widgets/user_list_tile.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List>? _listFuture;
  Future<List>? _friendFuture;
  ClientHolder? _clientHolder;
  Timer? _debouncer;
  bool _searchIsLoading = false;

  @override
  void dispose() {
    _debouncer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final clientHolder = ClientHolder.of(context);
    if (_clientHolder != clientHolder) {
      _clientHolder = clientHolder;
      _refreshFriendsList();
    }
  }

  void _refreshFriendsList() {
    _searchIsLoading = true;
    _listFuture = FriendApi.getFriendsList(_clientHolder!.client).then((Iterable<Friend> value) =>
    value.toList()
      ..sort((a, b) {
        if (a.userStatus.onlineStatus == b.userStatus.onlineStatus) {
          return a.userStatus.lastStatusChange.compareTo(b.userStatus.lastStatusChange);
        } else {
          if (a.userStatus.onlineStatus == OnlineStatus.online) {
            return -1;
          } else {
            return 1;
          }
        }
      },
      ),
    ).whenComplete(() => setState((){ _searchIsLoading = false; }));
    _friendFuture = _listFuture;
  }

  void _searchForUsers(String needle) {
    _listFuture = UserApi.searchUsers(_clientHolder!.client, needle: needle).then((value) =>
    value.toList()
      ..sort((a, b) {
        return a.username.length.compareTo(b.username.length);
      },)
    ).whenComplete(() => setState((){ _searchIsLoading = false; }));
  }

  void _restoreFriendsList() {
    _listFuture = _friendFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacts++"),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              _refreshFriendsList();
              await _listFuture;
            },
            child: FutureBuilder(
                future: _listFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final data = snapshot.data as Iterable;
                    return ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final entry = data.elementAt(index);
                        if (entry is Friend) {
                          return FriendListTile(friend: entry);
                        } else if (entry is User) {
                          return UserListTile(user: entry);
                        }
                        return null;
                      },
                    );
                  } else if (snapshot.hasError) {
                    FlutterError.reportError(FlutterErrorDetails(exception: snapshot.error!, stack: snapshot.stackTrace));
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(64),
                        child: Text(
                          "Something went wrong: ${snapshot.error}",
                          softWrap: true,
                          style: Theme
                              .of(context)
                              .textTheme
                              .labelMedium,
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ExpandingInputFab(
              onInputChanged: (String text) {
                if (_debouncer?.isActive ?? false) _debouncer?.cancel();
                if (text.isEmpty) {
                  setState(() {
                    _searchIsLoading = false;
                    _restoreFriendsList();
                  });
                  return;
                }
                setState(() {
                  _searchIsLoading = true;
                });
                _debouncer = Timer(const Duration(milliseconds: 500), () {
                    setState(() {
                      if(text.isNotEmpty) {
                        _searchForUsers(text);
                      } else {
                        _searchIsLoading = false;
                      }
                    });
                });
              },
              onExpansionChanged: (expanded) {
                if (_debouncer?.isActive ?? false) _debouncer?.cancel();
                if (!expanded) {
                  setState(() {
                    _restoreFriendsList();
                  });
                }
              },
            ),
          ),
          if (_searchIsLoading) const Align(alignment: Alignment.topCenter, child: LinearProgressIndicator(),)
        ],
      ),
    );
  }
}
