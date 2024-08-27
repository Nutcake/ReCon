import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/clients/messaging_client.dart';
import 'package:recon/models/message.dart';
import 'package:recon/models/users/friend.dart';
import 'package:recon/models/users/online_status.dart';
import 'package:recon/string_formatter.dart';
import 'package:recon/widgets/formatted_text.dart';
import 'package:recon/widgets/friends/friend_online_status_indicator.dart';
import 'package:recon/widgets/generic_avatar.dart';
import 'package:recon/widgets/messages/messages_list.dart';

class FriendListTile extends StatelessWidget {
  const FriendListTile({required this.friend, required this.unreads, this.onTap, super.key});

  final Friend friend;
  final int unreads;
  final Function? onTap;

  @override
  Widget build(BuildContext context) {
    final imageUri = Aux.resdbToHttp(friend.userProfile.iconUrl);
    final theme = Theme.of(context);
    final mClient = Provider.of<MessagingClient>(context, listen: false);
    final currentSession = friend.userStatus.currentSessionIndex == -1
        ? null
        : friend.userStatus.decodedSessions.elementAtOrNull(friend.userStatus.currentSessionIndex);

    FormatNode offlineStatus = FormatNode.buildFromStyles(
      [FormatData(name: 'color', parameter: OnlineStatus.offline.color(context).toCss(), isAdditive: true)],
      'Offline',
    );
    FormatNode headlessHostStatus = FormatNode.buildFromStyles(
      [FormatData(name: 'color', parameter: const Color.fromARGB(255, 41, 77, 92).toCss(), isAdditive: true)],
      'Headless Host',
    );

    List<FormatNode> statusSegments = [
      FormatNode.unformatted(toBeginningOfSentenceCase(friend.userStatus.onlineStatus.name) ?? '')
    ];

    if (friend.isOffline) {
      statusSegments = [offlineStatus];
    } else if (friend.isHeadless) {
      statusSegments = [headlessHostStatus];
    } else if (currentSession != null) {
      statusSegments.add(FormatNode.unformatted(' in '));
      if (currentSession.name.isNotEmpty) {
        statusSegments.add(currentSession.formattedName);
      } else {
        final bool showHidden = !currentSession.isVisible && currentSession.accessLevel.index != 1;
        final bool hideAccessLevel = currentSession.accessLevel.index > 3 || currentSession.accessLevel.index == 0;
        statusSegments.add(FormatNode.unformatted(
            'a ${showHidden ? 'Hidden${hideAccessLevel ? '' : ', '}' : ''}${!hideAccessLevel ? currentSession.accessLevel.toReadableString() : ''} World'));
      }
    } else if (friend.userStatus.appVersion.isNotEmpty) {
      statusSegments.add(FormatNode.unformatted(' on version ${friend.userStatus.appVersion}'));
    }

    FormatNode formattedStatus = FormatNode.merge(statusSegments);

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
          Text(friend.username),
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
          FriendOnlineStatusIndicator(friend),
          const SizedBox(width: 4),
          Expanded(
            child: FormattedText(
              formattedStatus,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      onTap: () async {
        onTap?.call();
        mClient.loadUserMessageCache(friend.id);
        final unreads = mClient.getUnreadsForFriend(friend);
        if (unreads.isNotEmpty) {
          final readBatch = MarkReadBatch(
            senderId: friend.id,
            ids: unreads.map((e) => e.id).toList(),
            readTime: DateTime.now(),
          );
          mClient.markMessagesRead(readBatch);
        }
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
