import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recon/client_holder.dart';
import 'package:recon/models/message.dart';

class MessageStateIndicator extends StatelessWidget {
  MessageStateIndicator({required this.message, this.foregroundColor, super.key});

  final DateFormat _dateFormat = DateFormat.Hm();
  final Message message;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor?.withAlpha(150);
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            _dateFormat.format(message.sendTime.toLocal()),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
          ),
        ),
        if (message.senderId == ClientHolder.of(context).apiClient.userId)
          Icon(
            switch (message.state) {
              MessageState.local => Icons.alarm,
              MessageState.sent => Icons.done,
              MessageState.read => Icons.done_all,
            },
            size: 12,
            color: color,
          ),
      ],
    );
  }
}
