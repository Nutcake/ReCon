import 'package:cached_network_image/cached_network_image.dart';
import 'package:contacts_plus/models/friend.dart';
import 'package:contacts_plus/widgets/messages.dart';
import 'package:flutter/material.dart';

class FriendListTile extends StatelessWidget {
  const FriendListTile({required this.friend, super.key});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CachedNetworkImage(
        imageBuilder: (context, imageProvider) {
          return CircleAvatar(
            foregroundImage: imageProvider,
          );
        },
        imageUrl: friend.userProfile.httpIconUri.toString(),
        placeholder: (context, url) {
          return const CircleAvatar(backgroundColor: Colors.white54,);
        },
        errorWidget: (context, error, what) => const CircleAvatar(
          backgroundColor: Colors.transparent,
          child: Icon(Icons.person),
        ),
      ),
      title: Text(friend.username),
      subtitle: Text(friend.userStatus.onlineStatus.name),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => Messages(friend: friend)));
      },
    );
  }

}