import 'package:contacts_plus_plus/models/message.dart';
import 'package:contacts_plus_plus/widgets/formatted_text.dart';
import 'package:contacts_plus_plus/widgets/messages/message_asset.dart';
import 'package:contacts_plus_plus/widgets/messages/message_audio_player.dart';
import 'package:contacts_plus_plus/widgets/messages/message_session_invite.dart';
import 'package:contacts_plus_plus/widgets/messages/message_state_indicator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// The way these classes are laid out is pretty unclean, there's a lot of stuff that's shared between the different
// subwidgets with a lot of room for deduplication. Should probably redo this some day.

class MyMessageBubble extends StatelessWidget {
  MyMessageBubble({required this.message, super.key});

  final Message message;
  final DateFormat _dateFormat = DateFormat.Hm();

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.sessionInvite:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme
                  .of(context)
                  .colorScheme
                  .primaryContainer,
              margin: const EdgeInsets.only(left: 32, bottom: 16, right: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                child: MessageSessionInvite(message: message,),
              ),
            ),
          ],
        );
      case MessageType.object:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme
                  .of(context)
                  .colorScheme
                  .primaryContainer,
              margin: const EdgeInsets.only(left: 32, bottom: 16, right: 12),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: MessageAsset(message: message,),
              ),
            ),
          ],
        );
      case MessageType.unknown:
      case MessageType.text:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Theme
                    .of(context)
                    .colorScheme
                    .primaryContainer,
                margin: const EdgeInsets.only(left: 32, bottom: 16, right: 12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FormattedText(
                        message.formattedContent,
                        softWrap: true,
                        maxLines: null,
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodyLarge,
                      ),
                      const SizedBox(height: 6,),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              _dateFormat.format(message.sendTime.toLocal()),
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: Colors.white54),
                            ),
                          ),
                          MessageStateIndicator(messageState: message.state),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      case MessageType.sound:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme
                  .of(context)
                  .colorScheme
                  .primaryContainer,
              margin: const EdgeInsets.only(left: 32, bottom: 16, right: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: MessageAudioPlayer(message: message,),
              ),
            ),
          ],
        );
    }
  }
}


class OtherMessageBubble extends StatelessWidget {
  OtherMessageBubble({required this.message, super.key});

  final Message message;
  final DateFormat _dateFormat = DateFormat.Hm();

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.sessionInvite:
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme
                  .of(context)
                  .colorScheme
                  .secondaryContainer,
              margin: const EdgeInsets.only(right: 32, bottom: 16, left: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: MessageSessionInvite(message: message,),
              ),
            ),
          ],
        );
      case MessageType.object:
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme
                  .of(context)
                  .colorScheme
                  .secondaryContainer,
              margin: const EdgeInsets.only(right: 32, bottom: 16, left: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: MessageAsset(message: message,),
              ),
            ),
          ],
        );
      case MessageType.unknown:
      case MessageType.text:
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Theme
                    .of(context)
                    .colorScheme
                    .secondaryContainer,
                margin: const EdgeInsets.only(right: 32, bottom: 16, left: 12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormattedText(
                        message.formattedContent,
                        softWrap: true,
                        maxLines: null,
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodyLarge,
                      ),
                      const SizedBox(height: 6,),
                      Text(
                        _dateFormat.format(message.sendTime.toLocal()),
                        style: Theme
                            .of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      case MessageType.sound:
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme
                  .of(context)
                  .colorScheme
                  .secondaryContainer,
              margin: const EdgeInsets.only(right: 32, bottom: 16, left: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: MessageAudioPlayer(message: message,),
              ),
            ),
          ],
        );
    }
  }
}
