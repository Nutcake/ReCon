import 'dart:convert';
import 'dart:io';

import 'package:contacts_plus_plus/apis/record_api.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/client_holder.dart';
import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/clients/messaging_client.dart';
import 'package:contacts_plus_plus/models/friend.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:contacts_plus_plus/widgets/default_error_widget.dart';
import 'package:contacts_plus_plus/widgets/friends/friend_online_status_indicator.dart';
import 'package:contacts_plus_plus/widgets/messages/messages_session_header.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

import 'message_bubble.dart';

class MessagesList extends StatefulWidget {
  const MessagesList({required this.friend, super.key});

  final Friend friend;

  @override
  State<StatefulWidget> createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> with SingleTickerProviderStateMixin {
  final TextEditingController _messageTextController = TextEditingController();
  final ScrollController _sessionListScrollController = ScrollController();
  final ScrollController _messageScrollController = ScrollController();

  bool _hasText = false;
  bool _isSending = false;
  bool _showSessionListScrollChevron = false;
  bool _showBottomBarShadow = false;
  File? _loadedFile;

  double get _shevronOpacity => _showSessionListScrollChevron ? 1.0 : 0.0;


  @override
  void dispose() {
    _messageTextController.dispose();
    _sessionListScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _sessionListScrollController.addListener(() {
      if (_sessionListScrollController.position.maxScrollExtent > 0 && !_showSessionListScrollChevron) {
        setState(() {
          _showSessionListScrollChevron = true;
        });
      }
      if (_sessionListScrollController.position.atEdge && _sessionListScrollController.position.pixels > 0
          && _showSessionListScrollChevron) {
        setState(() {
          _showSessionListScrollChevron = false;
        });
      }
    });
    _messageScrollController.addListener(() {
      if (!_messageScrollController.hasClients) return;
      if (_messageScrollController.position.atEdge && _messageScrollController.position.pixels == 0 &&
          _showBottomBarShadow) {
        setState(() {
          _showBottomBarShadow = false;
        });
      } else if (!_showBottomBarShadow) {
        setState(() {
          _showBottomBarShadow = true;
        });
      }
    });
  }

  Future<void> sendTextMessage(ScaffoldMessengerState scaffoldMessenger, ApiClient client, MessagingClient mClient, String content) async {
    setState(() {
      _isSending = true;
    });
    final message = Message(
      id: Message.generateId(),
      recipientId: widget.friend.id,
      senderId: client.userId,
      type: MessageType.text,
      content: content,
      sendTime: DateTime.now().toUtc(),
    );
    try {
      mClient.sendMessage(message);
      _messageTextController.clear();
      setState(() {});
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Failed to send message\n$e",
            maxLines: null,
          ),
        ),
      );
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> sendImageMessage(ScaffoldMessengerState scaffoldMessenger, ApiClient client, MessagingClient mClient, File file, machineId) async {
    setState(() {
      _isSending = true;
    });
    try {
      var record = await RecordApi.uploadFile(
        client,
        file: file,
        machineId: machineId,
      );
      final newUri = Aux.neosDbToHttp(record.assetUri);
      record = record.copyWith(
        assetUri: newUri,
        thumbnailUri: newUri,
      );

      final message = Message(
        id: Message.generateId(),
        recipientId: widget.friend.id,
        senderId: client.userId,
        type: MessageType.object,
        content: jsonEncode(record.toMap()),
        sendTime: DateTime.now().toUtc(),
      );
      mClient.sendMessage(message);
      _messageTextController.clear();
      _loadedFile = null;
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Failed to send file\n$e",
            maxLines: null,
          ),
        ),
      );
    }
    setState(() {
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ClientHolder
        .of(context)
        .apiClient;
    var sessions = widget.friend.userStatus.activeSessions;
    final appBarColor = Theme
        .of(context)
        .colorScheme
        .surfaceVariant;
    return Consumer<MessagingClient>(
        builder: (context, mClient, _) {
          final cache = mClient.getUserMessageCache(widget.friend.id);
          return Scaffold(
            appBar: AppBar(
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FriendOnlineStatusIndicator(userStatus: widget.friend.userStatus),
                  const SizedBox(width: 8,),
                  Text(widget.friend.username),
                  if (widget.friend.isHeadless) Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(Icons.dns, size: 18, color: Theme
                        .of(context)
                        .colorScheme
                        .onSecondaryContainer
                        .withAlpha(150),),
                  ),
                ],
              ),
              scrolledUnderElevation: 0.0,
              backgroundColor: appBarColor,
            ),
            body: Column(
              children: [
                if (sessions.isNotEmpty) Container(
                  constraints: const BoxConstraints(maxHeight: 64),
                  decoration: BoxDecoration(
                      color: appBarColor,
                      border: const Border(top: BorderSide(width: 1, color: Colors.black26),)
                  ),
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _sessionListScrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: sessions.length,
                        itemBuilder: (context, index) => SessionTile(session: sessions[index]),
                      ),
                      AnimatedOpacity(
                        opacity: _shevronOpacity,
                        curve: Curves.easeOut,
                        duration: const Duration(milliseconds: 200),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.only(left: 16, right: 4, top: 1, bottom: 1),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  appBarColor.withOpacity(0),
                                  appBarColor,
                                  appBarColor,
                                ],
                              ),
                            ),
                            height: double.infinity,
                            child: const Icon(Icons.chevron_right),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (cache == null) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            LinearProgressIndicator()
                          ],
                        );
                      }
                      if (cache.error != null) {
                        return DefaultErrorWidget(
                          message: cache.error.toString(),
                          onRetry: () {
                            setState(() {
                              mClient.deleteUserMessageCache(widget.friend.id);
                            });
                            mClient.loadUserMessageCache(widget.friend.id);
                          },
                        );
                      }
                      if (cache.messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.message_outlined),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  "There are no messages here\nWhy not say hello?",
                                  textAlign: TextAlign.center,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              )
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: _messageScrollController,
                        reverse: true,
                        itemCount: cache.messages.length,
                        itemBuilder: (context, index) {
                          final entry = cache.messages[index];
                          if (index == cache.messages.length - 1) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: MessageBubble(message: entry,),
                            );
                          }
                          return MessageBubble(message: entry,);
                        },
                      );
                    },
                  ),
                ),
                if (_isSending && _loadedFile != null) const LinearProgressIndicator(),
                AnimatedContainer(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        blurRadius: _showBottomBarShadow ? 8 : 0,
                        color: Theme
                            .of(context)
                            .shadowColor,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    color: Theme
                        .of(context)
                        .colorScheme
                        .background,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  duration: const Duration(milliseconds: 250),
                  child: Row(
                    children: [
                      /*IconButton(
                        onPressed: _hasText ? null : _loadedFile == null ? () async {
                          //final machineId = ClientHolder.of(context).settingsClient.currentSettings.machineId.valueOrDefault;
                          final result = await FilePicker.platform.pickFiles(type: FileType.image);

                          if (result != null && result.files.single.path != null) {
                            setState(() {
                              _loadedFile = File(result.files.single.path!);
                            });
                          }
                        } : () => setState(() => _loadedFile = null),
                        icon: _loadedFile == null ? const Icon(Icons.attach_file) : const Icon(Icons.close),
                      ),*/
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            enabled: cache != null && cache.error == null && _loadedFile == null,
                            autocorrect: true,
                            controller: _messageTextController,
                            maxLines: 4,
                            minLines: 1,
                            onChanged: (text) {
                              if (text.isNotEmpty && !_hasText) {
                                setState(() {
                                  _hasText = true;
                                });
                              } else if (text.isEmpty && _hasText) {
                                setState(() {
                                  _hasText = false;
                                });
                              }
                            },
                            decoration: InputDecoration(
                                isDense: true,
                                hintText: _loadedFile == null ?  "Message ${widget.friend
                                    .username}..." : "Send ${basename(_loadedFile?.path ?? "")}",
                                hintMaxLines: 1,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24)
                                )
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 4.0),
                        child: IconButton(
                          splashRadius: 24,
                          onPressed: _isSending ? null : () async {
                            if (_loadedFile == null) {
                              await sendTextMessage(ScaffoldMessenger.of(context), apiClient, mClient, _messageTextController.text);
                            } else {
                              await sendImageMessage(ScaffoldMessenger.of(context), apiClient, mClient, _loadedFile!, ClientHolder.of(context).settingsClient.currentSettings.machineId.valueOrDefault);
                            }
                          },
                          iconSize: 28,
                          icon: const Icon(Icons.send),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
    );
  }
}
