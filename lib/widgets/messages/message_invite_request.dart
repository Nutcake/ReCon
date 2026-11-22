import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recon/client_holder.dart';
import 'package:recon/models/invite_request.dart';
import 'package:recon/models/message.dart';
import 'package:recon/string_formatter.dart';
import 'package:recon/widgets/formatted_text.dart';
import 'package:recon/widgets/messages/message_state_indicator.dart';
import 'package:provider/provider.dart';
import 'package:recon/clients/messaging_client.dart';

class MessageInviteRequest extends StatelessWidget {
  const MessageInviteRequest({required this.message, this.foregroundColor, super.key});

  final Color? foregroundColor;
  final Message message;
  @override
  Widget build(BuildContext context) {
    final clientHolder = ClientHolder.of(context);
    final inviteInfo = InviteRequest.fromMap(jsonDecode(message.content));
    final fromSelf = message.senderId == ClientHolder.of(context).apiClient.userId;
    final selfRequest = fromSelf && inviteInfo.forSessionName == null;
    String text;
    if (selfRequest) {
      //if the sender is the logged in user and the session name isn't included; this is the user requesting for an invite themselves.
      text = '''Requested invite''';
    } else if (fromSelf) {
      //Forwarded invite request
      if (inviteInfo.response == "SendInvite") {
        text = 'messaging.invite.granted'.tr(args: [inviteInfo.usernameToInvite, inviteInfo.forSessionName.toString()]);
      } else if (inviteInfo.response == "AddAsContact") {
        text = 'messaging.invite.addAsContact'.tr(args: [inviteInfo.usernameToInvite]);
      } else {
        //If new responses are added to the InviteRequestResponse enum.
        text = 'messaging.invite.unknownResponse'.tr(args: [inviteInfo.response.toString()]);
      }
    } else if (inviteInfo.forSessionName != null) {
      //Another user requested an invite from you.
      if (inviteInfo.requestingFromUsername.isNotEmpty) {
        //User wants to invite user2 to world
        text = '''"${inviteInfo.requestingFromUsername}" wants to invite "${inviteInfo.usernameToInvite}" to "${inviteInfo.forSessionName}"''';
      } else {
        //Another user requested an invite from you.
        text = '''${inviteInfo.usernameToInvite} would like to join you in "${inviteInfo.forSessionName}"''';
      }
    } else {
      text = '''${inviteInfo.usernameToInvite} would like to join you''';
    }

    final formattedText = FormatNode.fromText(text);
    return Consumer<MessagingClient>(
      builder: (context, mClient, _) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 300),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FormattedText(formattedText, softWrap: true, maxLines: null, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: foregroundColor)),
              ),

              if (!fromSelf && inviteInfo.forSessionName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (inviteInfo.requestingFromUsername.isNotEmpty) ...[
                        //User wants to invite user2 to world
                        TextButton(
                          onPressed: () async {
                            try {
                              final response = Message.inviteRequestResponse(
                                senderId: clientHolder.apiClient.userId,
                                recipientId: message.senderId,
                                inviteRequest: inviteInfo,
                                response: "SendInvite",
                              );

                              mClient.sendMessage(response);
                            } catch (e) {
                              FlutterError.reportError(FlutterErrorDetails(exception: e));
                            }
                          },
                          child: const Text('messaging.invite.grantInvite').tr(),
                        ),
                        if (inviteInfo.isContactOfHost != true) ...[
                          // User is not already a contact of host, show add as contact button
                          TextButton(
                            onPressed: () async {
                              try {
                                final response = Message.inviteRequestResponse(
                                  senderId: clientHolder.apiClient.userId,
                                  recipientId: message.senderId,
                                  inviteRequest: inviteInfo,
                                  response: "AddAsContact",
                                );

                                mClient.sendMessage(response);
                              } catch (e) {
                                FlutterError.reportError(FlutterErrorDetails(exception: e));
                              }
                            },
                            child: const Text('messaging.invite.addUserAsContact').tr(args: [inviteInfo.usernameToInvite]),
                          ),
                        ],
                      ] else ...[
                        //Forward this to host
                        TextButton(
                          onPressed: () {
                            try {
                              final response = Message.forwardedInviteRequest(
                                senderId: clientHolder.apiClient.userId,
                                recipientId: inviteInfo.requestingFromUserId,
                                inviteRequest: inviteInfo,
                                sessionId: inviteInfo.forSessionId ?? "",
                                sessionName: inviteInfo.forSessionName ?? ""
                              );

                              mClient.sendMessage(response);
                            } catch (e) {
                              FlutterError.reportError(
                                FlutterErrorDetails(exception: e),
                              );
                            }
                          },
                          child: const Text('messaging.invite.forwardToHost').tr(args: [inviteInfo.hostUsername]),
                        ),
                      ],
                    ],
                  ),
                ),

              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [MessageStateIndicator(message: message, foregroundColor: foregroundColor)],
              ),
            ],
          ),
        );
      },
    );
  }
}
