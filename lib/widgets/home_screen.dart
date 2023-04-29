import 'package:contacts_plus/apis/friend_api.dart';
import 'package:contacts_plus/main.dart';
import 'package:contacts_plus/models/friend.dart';
import 'package:contacts_plus/widgets/messages.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Friend>>? _friendsFuture;

  @override
  void initState() {
    super.initState();
    _refreshFriendsList();
  }

  void _refreshFriendsList() {
    _friendsFuture = FriendApi.getFriendsList().then((Iterable<Friend> value) =>
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacts+"),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshFriendsList();
          await _friendsFuture;
        },
        child: FutureBuilder(
            future: _friendsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final data = snapshot.data as Iterable<Friend>;
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final entry = data.elementAt(index);
                    return ListTile(
                      title: Text(entry.username),
                      subtitle: Text(entry.userStatus.onlineStatus.name),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Messages(friend: entry)));
                      },
                    );
                  },
                );
              } else if (snapshot.hasError) {
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
                return const LinearProgressIndicator();
              }
            }
        ),
      ),
    );
  }
}