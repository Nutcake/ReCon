import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:recon/client_holder.dart';
import 'package:recon/models/invite_request.dart';
import 'package:recon/models/message.dart';
import 'package:recon/string_formatter.dart';
import 'package:recon/widgets/formatted_text.dart';
import 'package:recon/widgets/messages/message_state_indicator.dart';

class MessageInviteRequest extends StatelessWidget {
  const MessageInviteRequest({required this.message, this.foregroundColor, super.key});

  final Color? foregroundColor;
  final Message message;
  @override
  Widget build(BuildContext context) {
    final inviteInfo = InviteRequest.fromMap(jsonDecode(message.content));
    final bool fromSelf = message.senderId == ClientHolder.of(context).apiClient.userId;
    final bool selfRequest = fromSelf && inviteInfo.forSessionName == null;
    String text;
    if (selfRequest) {
      //if the sender is the logged in user and the session name isn't included; this is the user requesting for an invite themselves.
      text ='''Requested invite''';
    } else if (fromSelf) {
      //Forwarded invite request
      text = '''Forwarded invite request from "${inviteInfo.usernameToInvite}" to session "${inviteInfo.forSessionName}"''';
    } else if (inviteInfo.forSessionName != null) {
      //Another user requested an invite from you.
      text = '''${inviteInfo.usernameToInvite} would like to join you in "${inviteInfo.forSessionName}"''';
    } else {
      text = '''${inviteInfo.usernameToInvite} would like to join you''';
    }

    final formattedText = FormatNode.fromText(text);
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: 
              FormattedText(
                  formattedText,
                  softWrap: true,
                  maxLines: null,
                  style: Theme
                        .of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: foregroundColor),),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              MessageStateIndicator(
                message: message,
                foregroundColor: foregroundColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}