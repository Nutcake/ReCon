import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:recon/apis/record_api.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/client_holder.dart';
import 'package:recon/clients/api_client.dart';
import 'package:recon/clients/messaging_client.dart';
import 'package:recon/config.dart';
import 'package:recon/models/message.dart';
import 'package:recon/models/users/friend.dart';
import 'package:recon/widgets/messages/message_attachment_list.dart';
import 'package:record/record.dart';

class MessageInputBar extends StatefulWidget {
  const MessageInputBar({this.disabled = false, required this.recipient, this.onMessageSent, super.key});

  final bool disabled;
  final Friend recipient;
  final Function()? onMessageSent;

  @override
  State<StatefulWidget> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  final TextEditingController _messageTextController = TextEditingController();
  final List<(FileType, File)> _loadedFiles = [];
  final AudioRecorder _recorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();

  DateTime? _recordingStartTime;

  bool _isSending = false;
  bool _attachmentPickerOpen = false;
  String _currentText = "";
  double? _sendProgress;
  bool _shiftHeld = false;

  bool get _isRecording => _recordingStartTime != null;

  set _isRecording(value) => _recordingStartTime = value ? DateTime.now() : null;
  bool _recordingCancelled = false;

  @override
  void dispose() {
    _recorder.dispose();
    _messageTextController.dispose();
    super.dispose();
  }

  Future<void> sendTextMessage(ApiClient client, MessagingClient mClient, String content) async {
    if (content.isEmpty) return;
    final message = Message(
      id: Message.generateId(),
      recipientId: widget.recipient.id,
      senderId: client.userId,
      type: MessageType.text,
      content: content,
      sendTime: DateTime.now().toUtc(),
      state: MessageState.local,
    );
    mClient.sendMessage(message);
  }

  Future<void> sendImageMessage(
    ApiClient client,
    MessagingClient mClient,
    File file,
    String machineId,
    void Function(double progress) progressCallback,
  ) async {
    final record = await RecordApi.uploadImage(
      client,
      image: file,
      machineId: machineId,
      progressCallback: progressCallback,
    );
    final message = Message(
      id: record.extractMessageId() ?? Message.generateId(),
      recipientId: widget.recipient.id,
      senderId: client.userId,
      type: MessageType.object,
      content: jsonEncode(record.toMap()),
      sendTime: DateTime.now().toUtc(),
      state: MessageState.local,
    );
    mClient.sendMessage(message);
  }

  Future<void> sendVoiceMessage(
    ApiClient client,
    MessagingClient mClient,
    File file,
    String machineId,
    void Function(double progress) progressCallback,
  ) async {
    final record = await RecordApi.uploadVoiceClip(
      client,
      voiceClip: file,
      machineId: machineId,
      progressCallback: progressCallback,
    );
    final message = Message(
      id: record.extractMessageId() ?? Message.generateId(),
      recipientId: widget.recipient.id,
      senderId: client.userId,
      type: MessageType.sound,
      content: jsonEncode(record.toMap()),
      sendTime: DateTime.now().toUtc(),
      state: MessageState.local,
    );
    mClient.sendMessage(message);
  }

  Future<void> sendRawFileMessage(
    ApiClient client,
    MessagingClient mClient,
    File file,
    String machineId,
    void Function(double progress) progressCallback,
  ) async {
    final record = await RecordApi.uploadRawFile(
      client,
      file: file,
      machineId: machineId,
      progressCallback: progressCallback,
    );
    final message = Message(
      id: record.extractMessageId() ?? Message.generateId(),
      recipientId: widget.recipient.id,
      senderId: client.userId,
      type: MessageType.object,
      content: jsonEncode(record.toMap()),
      sendTime: DateTime.now().toUtc(),
      state: MessageState.local,
    );
    mClient.sendMessage(message);
  }

  Future<void> _sendCurrentMessage() async {
    setState(() {
      _isSending = true;
      _sendProgress = 0;
      _attachmentPickerOpen = false;
      _loadedFiles.clear();
    });
    final cHolder = ClientHolder.of(context);
    final mClient = Provider.of<MessagingClient>(context, listen: false);
    final sMsgnr = ScaffoldMessenger.of(context);
    final settings = cHolder.settingsClient.currentSettings;
    final toSend = List<(FileType, File)>.from(_loadedFiles);
    try {
      for (var i = 0; i < toSend.length; i++) {
        final totalProgress = i / toSend.length;
        final file = toSend[i];
        if (file.$1 == FileType.image) {
          await sendImageMessage(
            cHolder.apiClient,
            mClient,
            file.$2,
            settings.machineId.valueOrDefault,
            (progress) => setState(() {
              _sendProgress = totalProgress + progress * 1 / toSend.length;
            }),
          );
        } else {
          await sendRawFileMessage(
            cHolder.apiClient,
            mClient,
            file.$2,
            settings.machineId.valueOrDefault,
            (progress) => setState(
              () => _sendProgress = totalProgress + progress * 1 / toSend.length,
            ),
          );
        }
      }
      setState(() {
        _sendProgress = null;
      });

      if (_currentText.isNotEmpty) {
        await sendTextMessage(cHolder.apiClient, mClient, _messageTextController.text);
      }
      _messageTextController.clear();
      _currentText = "";
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
    widget.onMessageSent?.call();
  }

  void _pointerMoveEventHandler(PointerMoveEvent event) {
    if (!_isRecording) return;
    final width = MediaQuery.of(context).size.width;

    if (event.localPosition.dx < width - width / 4) {
      if (!_recordingCancelled) {
        HapticFeedback.vibrate();
        setState(() {
          _recordingCancelled = true;
        });
      }
    } else {
      if (_recordingCancelled) {
        HapticFeedback.vibrate();
        setState(() {
          _recordingCancelled = false;
        });
      }
    }
  }

  Stream<Duration> _recordingDurationStream() async* {
    while (_isRecording) {
      yield DateTime.now().difference(_recordingStartTime!);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mClient = Provider.of<MessagingClient>(context, listen: false);
    return Listener(
      onPointerMove: _pointerMoveEventHandler,
      onPointerUp: (_) async {
        // Do this here as the pointerUp event of the gesture detector on the mic button can be unreliable
        final cHolder = ClientHolder.of(context);
        if (_isRecording) {
          if (_recordingCancelled) {
            setState(() {
              _isRecording = false;
            });
            final recording = await _recorder.stop();
            if (recording == null) return;
            final file = File(recording);
            if (file.existsSync()) {
              await file.delete();
            }
          }
          setState(() {
            _recordingCancelled = false;
            _isRecording = false;
          });

          if (await _recorder.isRecording()) {
            final recording = await _recorder.stop();
            if (recording == null) return;

            final file = File(recording);
            setState(() {
              _isSending = true;
              _sendProgress = 0;
            });
            final apiClient = cHolder.apiClient;
            await sendVoiceMessage(apiClient, mClient, file, cHolder.settingsClient.currentSettings.machineId.valueOrDefault, (progress) {
              setState(() {
                _sendProgress = progress;
              });
            });
            setState(() {
              _isSending = false;
              _sendProgress = null;
            });
          }
        }
      },
      child: Focus(
        onKeyEvent: Config.isDesktop
            ? (node, event) {
                if (_isSending || _currentText.trim().isEmpty) return KeyEventResult.ignored;
                if (event.logicalKey.synonyms.contains(LogicalKeyboardKey.shift)) {
                  _shiftHeld = event is KeyDownEvent;
                  return KeyEventResult.handled;
                }

                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                  if (_shiftHeld) {
                    _messageTextController.text = "${_messageTextController.text}\n";
                    return KeyEventResult.handled;
                  }
                  _isSending = true; // set this early just to be extra sure
                  _sendCurrentMessage();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            border: const Border(top: BorderSide(width: 1, color: Colors.black)),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                if (_isSending && _sendProgress != null) LinearProgressIndicator(value: _sendProgress),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) => SizeTransition(
                      sizeFactor: animation,
                      child: child,
                    ),
                    child: switch ((_attachmentPickerOpen, _loadedFiles)) {
                      (true, []) => Row(
                          key: const ValueKey("attachment-picker"),
                          children: [
                            TextButton.icon(
                              onPressed: _isSending
                                  ? null
                                  : () async {
                                      final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
                                      if (result != null) {
                                        setState(() {
                                          _loadedFiles.addAll(
                                            result.files.map((e) => e.path != null ? (FileType.image, File(e.path!)) : null).nonNulls,
                                          );
                                        });
                                      }
                                    },
                              icon: const Icon(Icons.image),
                              label: const Text("Gallery"),
                            ),
                            TextButton.icon(
                              onPressed: _isSending
                                  ? null
                                  : () async {
                                      final picture = await _imagePicker.pickImage(source: ImageSource.camera);
                                      if (picture == null) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to get image path")));
                                        }
                                        return;
                                      }
                                      final file = File(picture.path);
                                      if (file.existsSync()) {
                                        setState(() {
                                          _loadedFiles.add((FileType.image, file));
                                        });
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to load image file")));
                                        }
                                      }
                                    },
                              icon: const Icon(Icons.camera),
                              label: const Text("Camera"),
                            ),
                            TextButton.icon(
                              onPressed: _isSending
                                  ? null
                                  : () async {
                                      final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: true);
                                      if (result != null) {
                                        setState(() {
                                          _loadedFiles.addAll(
                                            result.files.map((e) => e.path != null ? (FileType.any, File(e.path!)) : null).nonNulls,
                                          );
                                        });
                                      }
                                    },
                              icon: const Icon(Icons.file_present_rounded),
                              label: const Text("Document"),
                            ),
                          ],
                        ),
                      (false, []) => null,
                      (_, _) => MessageAttachmentList(
                          disabled: _isSending,
                          initialFiles: _loadedFiles,
                          onChange: (loadedFiles) => setState(() {
                            _loadedFiles
                              ..clear()
                              ..addAll(loadedFiles);
                          }),
                        ),
                    },
                  ),
                ),
                Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: RotationTransition(
                          turns: Tween<double>(begin: 0.6, end: 1).animate(animation),
                          child: child,
                        ),
                      ),
                      child: switch ((_attachmentPickerOpen, _isRecording)) {
                        (_, true) => IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.delete,
                              color: _recordingCancelled ? Theme.of(context).colorScheme.error : null,
                            ),
                          ),
                        (false, _) => IconButton(
                            key: const ValueKey("add-attachment-icon"),
                            onPressed: _isSending
                                ? null
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Sorry, this feature is not yet available")),
                                    );
                                    return;
                                    // setState(() {
                                    //   _attachmentPickerOpen = true;
                                    // });
                                  },
                            icon: const Icon(
                              Icons.attach_file,
                            ),
                          ),
                        (true, _) => IconButton(
                            key: const ValueKey("remove-attachment-icon"),
                            onPressed: _isSending
                                ? null
                                : () async {
                                    if (_loadedFiles.isNotEmpty) {
                                      await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
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
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      setState(() {
                                        _attachmentPickerOpen = false;
                                      });
                                    }
                                  },
                            icon: const Icon(
                              Icons.close,
                            ),
                          ),
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Stack(
                          children: [
                            TextField(
                              enabled: (!widget.disabled) && !_isSending,
                              autocorrect: true,
                              controller: _messageTextController,
                              showCursor: !_isRecording,
                              maxLines: 4,
                              minLines: 1,
                              onChanged: (text) {
                                if (text.isEmpty != _currentText.isEmpty) {
                                  setState(() {
                                    _currentText = text;
                                  });
                                  return;
                                }
                                _currentText = text;
                              },
                              style: Theme.of(context).textTheme.bodyLarge,
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: _isRecording ? "" : "Message ${widget.recipient.username}...",
                                hintMaxLines: 1,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                fillColor: Colors.black26,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) => FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, .2),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                              child: _isRecording
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                                      child: _recordingCancelled
                                          ? Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                const SizedBox(
                                                  width: 8,
                                                ),
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                                  child: Icon(
                                                    Icons.cancel,
                                                    color: Colors.red,
                                                    size: 16,
                                                  ),
                                                ),
                                                Text("Cancel Recording", style: Theme.of(context).textTheme.titleMedium),
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                const SizedBox(
                                                  width: 8,
                                                ),
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                                  child: Icon(
                                                    Icons.circle,
                                                    color: Colors.red,
                                                    size: 16,
                                                  ),
                                                ),
                                                StreamBuilder<Duration>(
                                                  stream: _recordingDurationStream(),
                                                  builder: (context, snapshot) {
                                                    return Text(
                                                      "Recording: ${snapshot.data?.format()}",
                                                      style: Theme.of(context).textTheme.titleMedium,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: RotationTransition(
                          turns: Tween<double>(begin: 0.5, end: 1).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _currentText.trim().isNotEmpty || _loadedFiles.isNotEmpty
                          ? IconButton(
                              key: const ValueKey("send-button"),
                              splashRadius: 24,
                              padding: EdgeInsets.zero,
                              onPressed: _isSending ? null : _sendCurrentMessage,
                              icon: const Icon(Icons.send),
                            )
                          : GestureDetector(
                              onTapUp: (_) {
                                _recordingCancelled = true;
                              },
                              onTapDown: widget.disabled
                                  ? null
                                  : (_) async {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Sorry, this feature is not yet available")),
                                      );
                                      return;
                                      // HapticFeedback.vibrate();
                                      // final hadToAsk =
                                      //     await Permission.microphone.isDenied;
                                      // final hasPermission =
                                      //     !await _recorder.hasPermission();
                                      // if (hasPermission) {
                                      //   if (context.mounted) {
                                      //     ScaffoldMessenger.of(context)
                                      //         .showSnackBar(const SnackBar(
                                      //       content: Text(
                                      //           "No permission to record audio."),
                                      //     ));
                                      //   }
                                      //   return;
                                      // }
                                      // if (hadToAsk) {
                                      //   // We had to ask for permissions so the user removed their finger from the record button.
                                      //   return;
                                      // }

                                      // final dir = await getTemporaryDirectory();
                                      // await _recorder.start(
                                      //     path: "${dir.path}/A-${const Uuid().v4()}.wav",
                                      //     const RecordConfig(
                                      //         numChannels: 1,
                                      //         sampleRate: 44100,
                                      //         encoder: AudioEncoder.wav));
                                      // setState(() {
                                      //   _isRecording = true;
                                      // });
                                    },
                              child: IconButton(
                                icon: const Icon(Icons.mic_outlined),
                                onPressed: _isSending
                                    ? null
                                    : () {
                                        // Empty onPressed for that sweet sweet ripple effect
                                      },
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
