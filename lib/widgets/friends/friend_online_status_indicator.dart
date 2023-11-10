import 'package:flutter/material.dart';
import 'package:recon/models/users/online_status.dart';
import 'package:recon/models/users/user_status.dart';

class FriendOnlineStatusIndicator extends StatelessWidget {
  const FriendOnlineStatusIndicator({required this.userStatus, super.key});

  final UserStatus userStatus;

  @override
  Widget build(BuildContext context) {
    return userStatus.appVersion.contains("ReCon") &&
            userStatus.onlineStatus != OnlineStatus.offline
        ? SizedBox.square(
            dimension: 10,
            child: Image.asset(
              "assets/images/logo-white.png",
              color: userStatus.onlineStatus.color(context),
              filterQuality: FilterQuality.medium,
              isAntiAlias: true,
            ),
          )
        : Icon(
            userStatus.onlineStatus == OnlineStatus.offline
                ? Icons.circle_outlined
                : Icons.circle,
            color: userStatus.onlineStatus.color(context),
            size: 10,
          );
  }
}
