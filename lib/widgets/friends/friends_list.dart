import 'package:recon/clients/messaging_client.dart';
import 'package:recon/widgets/default_error_widget.dart';
import 'package:recon/widgets/friends/expanding_input_fab.dart';
import 'package:recon/widgets/friends/friend_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FriendsList extends StatefulWidget {
  const FriendsList({super.key});

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> with AutomaticKeepAliveClientMixin {
  String _searchFilter = "";

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<MessagingClient>(
      builder: (context, mClient, _) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Builder(
              builder: (context) {
                if (mClient.initStatus == null) {
                  return const LinearProgressIndicator();
                } else if (mClient.initStatus!.isNotEmpty) {
                  return Column(
                    children: [
                      Expanded(
                        child: DefaultErrorWidget(
                          message: mClient.initStatus,
                          onRetry: () async {
                            mClient.resetInitStatus();
                            mClient.refreshFriendsListWithErrorHandler();
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  var friends = List.from(mClient.cachedFriends); // Explicit copy.
                  if (_searchFilter.isNotEmpty) {
                    friends = friends
                        .where((element) => element.username.toLowerCase().contains(_searchFilter.toLowerCase()))
                        .toList();
                    friends.sort((a, b) => a.username.length.compareTo(b.username.length));
                  }
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final unreads = mClient.getUnreadsForFriend(friend);
                      return FriendListTile(
                        friend: friend,
                        unreads: unreads.length,
                      );
                    },
                  );
                }
              },
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
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
