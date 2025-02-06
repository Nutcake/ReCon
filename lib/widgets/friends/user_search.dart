import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recon/apis/user_api.dart';
import 'package:recon/client_holder.dart';
import 'package:recon/clients/messaging_client.dart';
import 'package:recon/models/users/user.dart';
import 'package:recon/widgets/default_error_widget.dart';
import 'package:recon/widgets/friends/user_list_tile.dart';

class SearchError {
  final String message;
  final IconData icon;

  const SearchError({required this.message, required this.icon});
}

class UserSearch extends StatefulWidget {
  const UserSearch({super.key});

  @override
  State<StatefulWidget> createState() => _UserSearchState();
}

class _UserSearchState extends State<UserSearch> {
  final TextEditingController _searchInputController = TextEditingController();
  Timer? _searchDebouncer;
  late Future<List<User>?>? _usersFuture = _emptySearch;

  Future<List<User>> get _emptySearch => Future(
        () => throw const SearchError(
          message: "Start typing to search for users",
          icon: Icons.search,
        ),
      );

  void _querySearch(BuildContext context, String needle) {
    if (needle.isEmpty) {
      _usersFuture = _emptySearch;
      return;
    }
    _usersFuture = UserApi.searchUsers(
      ClientHolder.of(context).apiClient,
      needle: needle,
    ).then((value) {
      final res = value.toList();
      if (res.isEmpty) throw SearchError(message: "No user found with username '$needle'", icon: Icons.search_off);
      res.sort(
        (a, b) => a.username.length.compareTo(b.username.length),
      );
      return res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mClient = Provider.of<MessagingClient>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Users"),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final users = snapshot.data!;
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return UserListTile(
                          user: user,
                          onChanged: () {
                            mClient.refreshFriendsList();
                          },
                          isFriend: mClient.getAsFriend(user.id) != null,
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    final err = snapshot.error;
                    if (err is SearchError) {
                      return DefaultErrorWidget(
                        title: err.message,
                        iconOverride: err.icon,
                      );
                    } else {
                      FlutterError.reportError(
                        FlutterErrorDetails(exception: snapshot.error!, stack: snapshot.stackTrace),
                      );
                      return DefaultErrorWidget(
                        title: "${snapshot.error}",
                      );
                    }
                  } else {
                    return const Column(
                      children: [
                        LinearProgressIndicator(),
                      ],
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Search for users...",
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                autocorrect: false,
                controller: _searchInputController,
                onChanged: (value) {
                  _searchDebouncer?.cancel();
                  if (value.isEmpty) {
                    setState(() {
                      _querySearch(context, value);
                    });
                    return;
                  }
                  setState(() {
                    _usersFuture = Future(() => null);
                  });
                  _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
                    setState(() {
                      _querySearch(context, value);
                    });
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
