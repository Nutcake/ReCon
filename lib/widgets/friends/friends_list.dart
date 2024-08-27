import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recon/clients/messaging_client.dart';
import 'package:recon/widgets/default_error_widget.dart';
import 'package:recon/widgets/friends/friend_list_tile.dart';

class FriendsList extends StatefulWidget {
  const FriendsList({super.key});

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> with AutomaticKeepAliveClientMixin {
  String _searchFilter = "";

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    super.build(context);
    return Consumer<MessagingClient>(
      builder: (context, mClient, _) {
        return Builder(
          builder: (context) {
            if (mClient.initStatus == null) {
              return LinearProgressIndicator(
                color: theme.colorScheme.surface,
                backgroundColor: theme.colorScheme.background,
              );
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
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
