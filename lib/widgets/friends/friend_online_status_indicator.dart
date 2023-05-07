
import 'package:contacts_plus_plus/models/friend.dart';
import 'package:flutter/material.dart';

class FriendOnlineStatusIndicator extends StatelessWidget {
  const FriendOnlineStatusIndicator({required this.userStatus, super.key});

  final UserStatus userStatus;

  @override
  Widget build(BuildContext context) {
    return
      userStatus.neosVersion.contains("Contacts++") ? SizedBox.square(
        dimension: 10,
        child: Image.asset(
          "assets/images/logo-white.png",
          alignment: Alignment.center,
          color: userStatus.onlineStatus.color,
        ),
      ) : Icon(
        userStatus.onlineStatus == OnlineStatus.offline ? Icons.circle_outlined : Icons.circle,
        color: userStatus.onlineStatus.color,
        size: 10,
      );
  }
}