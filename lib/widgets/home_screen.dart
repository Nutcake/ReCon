import 'package:cached_network_image/cached_network_image.dart';
import 'package:contacts_plus/apis/friend_api.dart';
import 'package:contacts_plus/aux.dart';
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
  ClientHolder? _clientHolder;

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
    final apiClient = ClientHolder.of(context).client;
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
                    final iconUri = entry.userProfile.httpIconUri.toString();
                    return ListTile(
                      leading: CachedNetworkImage(
                        imageBuilder: (context, imageProvider) {
                          return CircleAvatar(
                            foregroundImage: imageProvider,
                          );
                        },
                          imageUrl: iconUri,
                        placeholder: (context, url) {
                          return const CircleAvatar(backgroundColor: Colors.white54,);
                        },
                        errorWidget: (context, error, what) => const CircleAvatar(
                          backgroundColor: Colors.transparent,
                          child: Icon(Icons.person),
                        ),
                      ),
                      title: Text(entry.username),
                      subtitle: Text(entry.userStatus.onlineStatus.name),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => Messages(friend: entry)));
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