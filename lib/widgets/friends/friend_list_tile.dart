import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/clients/messaging_client.dart';
import 'package:recon/models/message.dart';
import 'package:recon/models/users/friend.dart';
import 'package:recon/models/users/online_status.dart';
import 'package:recon/widgets/formatted_text.dart';
import 'package:recon/widgets/friends/friend_online_status_indicator.dart';
import 'package:recon/widgets/generic_avatar.dart';
import 'package:recon/widgets/messages/messages_list.dart';

class FriendListTile extends StatelessWidget {
  const FriendListTile({required this.friend, required this.unreads, super.key});

  final Friend friend;
  final int unreads;

  @override
  Widget build(BuildContext context) {
    final imageUri = Aux.resdbToHttp(friend.userProfile.iconUrl);
    final theme = Theme.of(context);
    final mClient = Provider.of<MessagingClient>(context, listen: false);
    final currentSession = friend.userStatus.currentSessionIndex == -1 ? null : friend.userStatus.decodedSessions.elementAtOrNull(friend.userStatus.currentSessionIndex);
    return ListTile(
      leading: GenericAvatar(
        imageUri: imageUri,
      ),
      trailing: unreads != 0
          ? Text(
              "+$unreads",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
            )
          : null,
      title: Row(
        children: [
          Text(friend.contactUsername),
          if (friend.isHeadless)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.dns,
                size: 12,
                color: theme.colorScheme.onSecondaryContainer.withAlpha(150),
              ),
            ),
        ],
      ),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FriendOnlineStatusIndicator(friend: friend),
          const SizedBox(
            width: 4,
          ),
          if (!(friend.isOffline || friend.isHeadless || friend.isBot)) ...[
            if (currentSession != null) ...[
              if (currentSession.name.isNotEmpty) ...[
                Text('contacts.inWorld'.tr(args: ['contacts.status.${friend.userStatus.onlineStatus.name}'.tr()])),
                Expanded(
                  child: FormattedText(
                    currentSession.formattedName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                )
              ]
              else
                Expanded(
                  child: Text(
                    'contacts.inWorldNoDetails'.tr(args: ['contacts.status.${friend.userStatus.onlineStatus.name}'.tr(), 'sessions.accessLevel.${currentSession.accessLevel.name}'.tr()]),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
            ] else if (friend.userStatus.appVersion.isNotEmpty)
              Expanded(
                child: Text(
                  'contacts.onVersion'.tr(args: ['contacts.status.${friend.userStatus.onlineStatus.name}'.tr(), friend.userStatus.appVersion]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ] else if (friend.isOffline)
            Text(
              'contacts.status.offline'.tr(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: OnlineStatus.offline.color(context),
              ),
            )
          else if (friend.isBot)
            Text(
              'contacts.bot'.tr(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              
            )
          else
            Text(
              'contacts.headlessHost'.tr(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color.fromARGB(255, 41, 77, 92),
              ),
            ),
        ],
      ),
      onTap: () async {
        unawaited(
          Future(
            () async {
              await mClient.loadUserMessageCache(friend.contactUserId);
              final unreads = mClient.getUnreadsForFriend(friend);
              if (unreads.isNotEmpty) {
                final readBatch = MarkReadBatch(
                  senderId: friend.contactUserId,
                  ids: unreads.map((e) => e.id).toList(),
                  readTime: DateTime.now(),
                );
                mClient.markMessagesRead(readBatch);
              }
            },
          ),
        );
        mClient.selectedFriend = friend;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider<MessagingClient>.value(
              value: mClient,
              child: const MessagesList(),
            ),
          ),
        );
        mClient.selectedFriend = null;
      },
    );
  }
}
