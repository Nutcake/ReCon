import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:contacts_plus_plus/apis/record_api.dart';
import 'package:contacts_plus_plus/client_holder.dart';
import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/clients/audio_cache_client.dart';
import 'package:contacts_plus_plus/clients/messaging_client.dart';
import 'package:contacts_plus_plus/models/friend.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:contacts_plus_plus/widgets/default_error_widget.dart';
import 'package:contacts_plus_plus/widgets/friends/friend_online_status_indicator.dart';
import 'package:contacts_plus_plus/widgets/messages/message_attachment_list.dart';
import 'package:contacts_plus_plus/widgets/messages/message_camera_view.dart';
import 'package:contacts_plus_plus/widgets/messages/message_record_button.dart';
import 'package:contacts_plus_plus/widgets/messages/messages_session_header.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  final List<(FileType, File)> _loadedFiles = [];

  bool _hasText = false;
  bool _isSending = false;
  bool _attachmentPickerOpen = false;
  double? _sendProgress;

  bool _showBottomBarShadow = false;
  bool _showSessionListScrollChevron = false;

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
      if (_attachmentPickerOpen && _loadedFiles.isEmpty) {
        setState(() {
          _attachmentPickerOpen = false;
        });
      }
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

  Future<void> sendTextMessage(ApiClient client, MessagingClient mClient, String content) async {
    if (content.isEmpty) return;
    final message = Message(
      id: Message.generateId(),
      recipientId: widget.friend.id,
      senderId: client.userId,
      type: MessageType.text,
      content: content,
      sendTime: DateTime.now().toUtc(),
    );
    mClient.sendMessage(message);
    _messageTextController.clear();
    _hasText = false;
  }

  Future<void> sendImageMessage(ApiClient client, MessagingClient mClient, File file, String machineId,
      void Function(double progress) progressCallback) async {
    final record = await RecordApi.uploadImage(
      client,
      image: file,
      machineId: machineId,
      progressCallback: progressCallback,
    );
    final message = Message(
      id: record.extractMessageId() ?? Message.generateId(),
      recipientId: widget.friend.id,
      senderId: client.userId,
      type: MessageType.object,
      content: jsonEncode(record.toMap()),
      sendTime: DateTime.now().toUtc(),
    );
    mClient.sendMessage(message);
    _messageTextController.clear();
    _hasText = false;
  }

  Future<void> sendVoiceMessage(ApiClient client, MessagingClient mClient, File file, String machineId,
      void Function(double progress) progressCallback) async {
    final record = await RecordApi.uploadVoiceClip(
      client,
      voiceClip: file,
      machineId: machineId,
      progressCallback: progressCallback,
    );
    final message = Message(
      id: record.extractMessageId() ?? Message.generateId(),
      recipientId: widget.friend.id,
      senderId: client.userId,
      type: MessageType.sound,
      content: jsonEncode(record.toMap()),
      sendTime: DateTime.now().toUtc(),
    );
    mClient.sendMessage(message);
    _messageTextController.clear();
    _hasText = false;
  }

  Future<void> sendRawFileMessage(ApiClient client, MessagingClient mClient, File file, String machineId,
      void Function(double progress) progressCallback) async {
    final record = await RecordApi.uploadRawFile(
      client,
      file: file,
      machineId: machineId,
      progressCallback: progressCallback,
    );
    final message = Message(
      id: record.extractMessageId() ?? Message.generateId(),
      recipientId: widget.friend.id,
      senderId: client.userId,
      type: MessageType.object,
      content: jsonEncode(record.toMap()),
      sendTime: DateTime.now().toUtc(),
    );
    mClient.sendMessage(message);
    _messageTextController.clear();
    _hasText = false;
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
                  child: Stack(
                    children: [
                      Builder(
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
                          return Provider(
                            create: (BuildContext context) => AudioCacheClient(),
                            child: ListView.builder(
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
                            ),
                          );
                        },
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 8,
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
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeOut,
                                transitionBuilder: (Widget child, animation) =>
                                    SizeTransition(sizeFactor: animation, child: child,),
                                child: switch ((_attachmentPickerOpen, _loadedFiles)) {
                                  (true, []) =>
                                      Row(
                                        key: const ValueKey("attachment-picker"),
                                        children: [
                                          TextButton.icon(
                                            onPressed: _isSending ? null : () async {
                                              final result = await FilePicker.platform.pickFiles(
                                                  type: FileType.image, allowMultiple: true);
                                              if (result != null) {
                                                setState(() {
                                                  _loadedFiles.addAll(
                                                      result.files.map((e) =>
                                                      e.path != null ? (FileType.image, File(e.path!)) : null)
                                                          .whereNotNull());
                                                });
                                              }
                                            },
                                            icon: const Icon(Icons.image),
                                            label: const Text("Gallery"),
                                          ),
                                          TextButton.icon(
                                            onPressed: _isSending ? null : () async {
                                              final picture = await Navigator.of(context).push(
                                                  MaterialPageRoute(builder: (context) => const MessageCameraView())) as File?;
                                              if (picture != null) {
                                                setState(() {
                                                  _loadedFiles.add((FileType.image, picture));
                                                });
                                              }
                                            },
                                            icon: const Icon(Icons.camera_alt),
                                            label: const Text("Camera"),
                                          ),
                                          TextButton.icon(
                                            onPressed: _isSending ? null : () async {
                                              final result = await FilePicker.platform.pickFiles(
                                                  type: FileType.any, allowMultiple: true);
                                              if (result != null) {
                                                setState(() {
                                                  _loadedFiles.addAll(
                                                      result.files.map((e) =>
                                                      e.path != null ? (FileType.any, File(e.path!)) : null)
                                                          .whereNotNull());
                                                });
                                              }
                                            },
                                            icon: const Icon(Icons.file_present_rounded),
                                            label: const Text("Document"),
                                          ),
                                        ],
                                      ),
                                  (false, []) => null,
                                  (_, _) =>
                                      MessageAttachmentList(
                                          disabled: _isSending,
                                          initialFiles: _loadedFiles,
                                          onChange: (List<(FileType, File)> loadedFiles) =>
                                          setState(() {
                                _loadedFiles.clear();
                                _loadedFiles.addAll(loadedFiles);
                                }),
                                )
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isSending && _sendProgress != null)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: LinearProgressIndicator(value: _sendProgress),
                        ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        blurRadius: _showBottomBarShadow && !_attachmentPickerOpen ? 8 : 0,
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
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) =>
                            FadeTransition(
                              opacity: animation,
                              child: RotationTransition(
                                turns: Tween<double>(begin: 0.6, end: 1).animate(animation),
                                child: child,
                              ),
                            ),
                        child: !_attachmentPickerOpen ?
                        IconButton(
                          key: const ValueKey("add-attachment-icon"),
                          onPressed: _isSending ? null : () {
                            setState(() {
                              _attachmentPickerOpen = true;
                            });
                          },
                          icon: const Icon(Icons.attach_file),
                        ) :
                        IconButton(
                          key: const ValueKey("remove-attachment-icon"),
                          onPressed: _isSending ? null : () async {
                            if (_loadedFiles.isNotEmpty) {
                              await showDialog(context: context, builder: (context) =>
                                  AlertDialog(
                                    title: const Text("Remove all attachments"),
                                    content: const Text("This will remove all attachments, are you sure?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("No"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _loadedFiles.clear();
                                            _attachmentPickerOpen = false;
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("Yes"),
                                      )
                                    ],
                                  ));
                            } else {
                              setState(() {
                                _attachmentPickerOpen = false;
                              });
                            }
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            enabled: cache != null && cache.error == null && !_isSending,
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
                                hintText: "Message ${widget.friend
                                    .username}...",
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
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (Widget child, Animation<double> animation) =>
                              FadeTransition(opacity: animation, child: RotationTransition(
                                turns: Tween<double>(begin: 0.5, end: 1).animate(animation), child: child,),),
                          child: _hasText || _loadedFiles.isNotEmpty ? IconButton(
                            key: const ValueKey("send-button"),
                            splashRadius: 24,
                            onPressed: _isSending ? null : () async {
                              final sMsgnr = ScaffoldMessenger.of(context);
                              final settings = ClientHolder
                                  .of(context)
                                  .settingsClient
                                  .currentSettings;
                              final toSend = List<(FileType, File)>.from(_loadedFiles);
                              setState(() {
                                _isSending = true;
                                _sendProgress = 0;
                                _attachmentPickerOpen = false;
                                _loadedFiles.clear();
                              });
                              try {
                                for (int i = 0; i < toSend.length; i++) {
                                  final totalProgress = i / toSend.length;
                                  final file = toSend[i];
                                  if (file.$1 == FileType.image) {
                                    await sendImageMessage(
                                      apiClient, mClient, file.$2, settings.machineId.valueOrDefault,
                                          (progress) =>
                                          setState(() {
                                            _sendProgress = totalProgress + progress * 1 / toSend.length;
                                          }),
                                    );
                                  } else {
                                    await sendRawFileMessage(
                                        apiClient, mClient, file.$2, settings.machineId.valueOrDefault, (progress) =>
                                        setState(() =>
                                        _sendProgress = totalProgress + progress * 1 / toSend.length));
                                  }
                                }
                                setState(() {
                                  _sendProgress = null;
                                });

                                if (_hasText) {
                                  await sendTextMessage(apiClient, mClient, _messageTextController.text);
                                }
                                _messageTextController.clear();
                                _loadedFiles.clear();
                                _attachmentPickerOpen = false;
                              } catch (e, s) {
                                FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s));
                                sMsgnr.showSnackBar(SnackBar(content: Text("Failed to send a message: $e")));
                              }
                              setState(() {
                                _isSending = false;
                                _sendProgress = null;
                              });
                            },
                            iconSize: 28,
                            icon: const Icon(Icons.send),
                          ) : MessageRecordButton(
                            key: const ValueKey("mic-button"),
                            disabled: _isSending,
                            onRecordEnd: (File? file) async {
                              if (file == null) return;
                              setState(() {
                                _isSending = true;
                                _sendProgress = 0;
                              });
                              await sendVoiceMessage(
                                  apiClient,
                                  mClient,
                                  file,
                                  ClientHolder
                                      .of(context)
                                      .settingsClient
                                      .currentSettings
                                      .machineId
                                      .valueOrDefault, (progress) {
                                setState(() {
                                  _sendProgress = progress;
                                });
                              }
                              );
                              setState(() {
                                _isSending = false;
                                _sendProgress = null;
                              });
                            },
                          ),
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
