import 'package:contacts_plus_plus/models/friend.dart';
import 'package:flutter/material.dart';

class FriendOnlineStatusIndicator extends StatelessWidget {
  const FriendOnlineStatusIndicator({required this.userStatus, super.key});

  final UserStatus userStatus;

  @override
  Widget build(BuildContext context) {
    return userStatus.neosVersion.contains("Contacts++") && userStatus.onlineStatus != OnlineStatus.offline
        ? SizedBox.square(
            dimension: 10,
            child: Image.asset(
              "assets/images/logo-white.png",
              alignment: Alignment.center,
              color: userStatus.onlineStatus.color(context),
            ),
          )
        : Icon(
            userStatus.onlineStatus == OnlineStatus.offline ? Icons.circle_outlined : Icons.circle,
            color: userStatus.onlineStatus.color(context),
            size: 10,
          );
  }
}
