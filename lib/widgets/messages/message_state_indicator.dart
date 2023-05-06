
import 'package:contacts_plus_plus/models/message.dart';
import 'package:flutter/material.dart';

class MessageStateIndicator extends StatelessWidget {
  const MessageStateIndicator({required this.messageState, super.key});

  final MessageState messageState;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    switch (messageState) {
      case MessageState.local:
        icon = Icons.alarm;
        break;
      case MessageState.sent:
        icon = Icons.done;
        break;
      case MessageState.read:
        icon = Icons.done_all;
        break;
    }
    return Icon(
      icon,
      size: 12,
    );
  }
}
