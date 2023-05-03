import 'dart:async';

import 'package:contacts_plus_plus/api_client.dart';
import 'package:contacts_plus_plus/apis/friend_api.dart';
import 'package:contacts_plus_plus/models/friend.dart';
import 'package:contacts_plus_plus/widgets/expanding_input_fab.dart';
import 'package:contacts_plus_plus/widgets/friend_list_tile.dart';
import 'package:contacts_plus_plus/widgets/settings_page.dart';
import 'package:flutter/material.dart';

class FriendsList extends StatefulWidget {
  const FriendsList({super.key});

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  Future<List<Friend>>? _friendsFuture;
  ClientHolder? _clientHolder;
  Timer? _debouncer;
  String _searchFilter = "";

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
    _friendsFuture = FriendApi.getFriendsList(_clientHolder!.client).then((Iterable<Friend> value) =>
    value.toList()
      ..sort((a, b) {
        if (a.userStatus.onlineStatus == b.userStatus.onlineStatus) {
          return a.userStatus.lastStatusChange.compareTo(b.userStatus.lastStatusChange);
        } else {
          return a.userStatus.onlineStatus.compareTo(b.userStatus.onlineStatus);
        }
      },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacts++"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
            icon: const Icon(Icons.settings),
          )
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              _refreshFriendsList();
              await _friendsFuture;
            },
            child: FutureBuilder(
                future: _friendsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var data = (snapshot.data as List<Friend>);
                    if (_searchFilter.isNotEmpty) {
                      data = data.where((element) => element.username.contains(_searchFilter)).toList();
                      data.sort((a, b) => a.username.length.compareTo(b.username.length));
                    }
                    return ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) => FriendListTile(friend: data[index]),
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
                setState(() {
                  _searchFilter = text;
                });
              },
              onExpansionChanged: (expanded) {
                if (_debouncer?.isActive ?? false) _debouncer?.cancel();
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
