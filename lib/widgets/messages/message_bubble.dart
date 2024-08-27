import 'package:flutter/material.dart';
import 'package:recon/client_holder.dart';
import 'package:recon/color_palette.dart';
import 'package:recon/models/message.dart';
import 'package:recon/widgets/messages/message_asset.dart';
import 'package:recon/widgets/messages/message_audio_player.dart';
import 'package:recon/widgets/messages/message_session_invite.dart';
import 'package:recon/widgets/messages/message_text.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, super.key});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final bool mine = message.senderId == ClientHolder.of(context).apiClient.userId;
    final MessageState state = message.state;
    final ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foregroundColor = colorScheme.onBackground;
    final backgroundColor = mine
        ? switch (state) {
            MessageState.local => colorScheme.secondaryContainer,
            MessageState.sent => colorScheme.primaryContainer,
            MessageState.read => colorScheme.primaryContainer,
          }
        : palette.hero.cyan.withOpacity(0.2);
    return Padding(
      padding: EdgeInsets.only(left: mine ? 32 : 12, bottom: 16, right: mine ? 12 : 32),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Material(
            borderRadius: BorderRadius.circular(16),
            color: backgroundColor,
            textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: foregroundColor),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: switch (message.type) {
                MessageType.sessionInvite => MessageSessionInvite(
                    message: message,
                    foregroundColor: foregroundColor,
                  ),
                MessageType.object => MessageAsset(
                    message: message,
                    foregroundColor: foregroundColor,
                  ),
                MessageType.sound => MessageAudioPlayer(
                    message: message,
                    foregroundColor: foregroundColor,
                  ),
                MessageType.unknown || MessageType.text => MessageText(
                    message: message,
                    foregroundColor: foregroundColor,
                  )
              },
            ),
          ),
        ],
      ),
    );
  }
}
