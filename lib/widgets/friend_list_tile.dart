import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/models/friend.dart';
import 'package:contacts_plus_plus/widgets/generic_avatar.dart';
import 'package:contacts_plus_plus/widgets/messages_list.dart';
import 'package:flutter/material.dart';

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
      subtitle: Text(friend.userStatus.onlineStatus.name),
      onTap: () async {
         Navigator.of(context).push(MaterialPageRoute(builder: (context) => MessagesList(friend: friend)));
         await onTap?.call();
      },
    );
  }
}