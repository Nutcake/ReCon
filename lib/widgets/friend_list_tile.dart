import 'package:cached_network_image/cached_network_image.dart';
import 'package:contacts_plus/aux.dart';
import 'package:contacts_plus/models/friend.dart';
import 'package:contacts_plus/widgets/generic_avatar.dart';
import 'package:contacts_plus/widgets/messages.dart';
import 'package:flutter/material.dart';

class FriendListTile extends StatelessWidget {
  const FriendListTile({required this.friend, super.key});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final imageUri = Aux.neosDbToHttp(friend.userProfile.iconUrl);
    return ListTile(
      leading: GenericAvatar(imageUri: imageUri,),
      title: Text(friend.username),
      subtitle: Text(friend.userStatus.onlineStatus.name),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => Messages(friend: friend)));
      },
    );
  }
}