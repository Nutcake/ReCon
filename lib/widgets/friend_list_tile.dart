import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/client_holder.dart';
import 'package:contacts_plus_plus/clients/messaging_client.dart';
import 'package:contacts_plus_plus/models/friend.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:contacts_plus_plus/widgets/generic_avatar.dart';
import 'package:contacts_plus_plus/widgets/messages_list.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class FriendListTile extends StatelessWidget {
  const FriendListTile({required this.friend, this.unreads, this.onTap, super.key});

  final Friend friend;
  final int? unreads;
  final Function? onTap;

  @override
  Widget build(BuildContext context) {
    final imageUri = Aux.neosDbToHttp(friend.userProfile.iconUrl);
    final theme = Theme.of(context);
    return ListTile(
      leading: GenericAvatar(imageUri: imageUri,),
      trailing: unreads != null && unreads != 0
          ? Text("+$unreads", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),)
          : null,
      title: Text(friend.username),
      subtitle: Text(toBeginningOfSentenceCase(friend.userStatus.onlineStatus.name) ?? "Unknown"),
      onTap: () async {
        onTap?.call();
        final mClient = Provider.of<MessagingClient>(context, listen: false);
        mClient.loadUserMessageCache(friend.id);
        final apiClient = ClientHolder
            .of(context)
            .apiClient;
        final unreads = mClient.getUnreadsForFriend(friend);
        if (unreads.isNotEmpty) {
          final readBatch = MarkReadBatch(
            senderId: apiClient.userId,
            ids: unreads.map((e) => e.id).toList(),
            readTime: DateTime.now(),
          );
          mClient.markMessagesRead(readBatch);
        }
        mClient.selectedFriend = friend;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
            ChangeNotifierProvider<MessagingClient>.value(
              value: mClient,
              child: MessagesList(friend: friend),
            ),
          ),
        );
        mClient.selectedFriend = null;
      },
    );
  }
}