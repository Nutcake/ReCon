import 'package:contacts_plus_plus/models/message.dart';
import 'package:contacts_plus_plus/widgets/formatted_text.dart';
import 'package:contacts_plus_plus/widgets/messages/message_state_indicator.dart';
import 'package:flutter/material.dart';

class MessageText extends StatelessWidget {
  const MessageText({required this.message, this.foregroundColor, super.key});

  final Message message;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FormattedText(
              message.formattedContent,
              softWrap: true,
              maxLines: null,
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: foregroundColor),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              MessageStateIndicator(message: message, foregroundColor: foregroundColor,),
            ],
          ),
        ],
    );
  }
}