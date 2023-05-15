import 'dart:convert';

import 'package:contacts_plus_plus/client_holder.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:contacts_plus_plus/models/session.dart';
import 'package:contacts_plus_plus/widgets/formatted_text.dart';
import 'package:contacts_plus_plus/widgets/generic_avatar.dart';
import 'package:contacts_plus_plus/widgets/messages/messages_session_header.dart';
import 'package:contacts_plus_plus/widgets/messages/message_state_indicator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageSessionInvite extends StatelessWidget {
  MessageSessionInvite({required this.message, super.key});
  final DateFormat _dateFormat = DateFormat.Hm();
  final Message message;

  @override
  Widget build(BuildContext context) {
    final sessionInfo = Session.fromMap(jsonDecode(message.content));
    return TextButton(
      onPressed: () {
        showDialog(context: context, builder: (context) => SessionPopup(session: sessionInfo));
      },
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      child: Container(
        padding: const EdgeInsets.only(left: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: FormattedText(sessionInfo.formattedName, maxLines: null, softWrap: true, style: Theme.of(context).textTheme.titleMedium,),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GenericAvatar(
                        imageUri: Aux.neosDbToHttp(Aux.neosDbToHttp(sessionInfo.thumbnail)),
                        placeholderIcon: Icons.no_photography,
                      ),
                      const SizedBox(height: 4,),
                      Text("${sessionInfo.sessionUsers.length}/${sessionInfo.maxUsers}")
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text("Hosted by ${sessionInfo.hostUsername}", overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),)),
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
                const SizedBox(width: 4,),
                if (message.senderId == ClientHolder.of(context).apiClient.userId) Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: MessageStateIndicator(messageState: message.state),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

}