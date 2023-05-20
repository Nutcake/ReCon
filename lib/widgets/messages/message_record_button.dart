import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class MessageRecordButton extends StatefulWidget {
  const MessageRecordButton({required this.disabled, this.onRecordStart, this.onRecordEnd, super.key});

  final bool disabled;
  final Function()? onRecordStart;
  final Function(File? recording)? onRecordEnd;

  @override
  State<MessageRecordButton> createState() => _MessageRecordButtonState();
}

class _MessageRecordButtonState extends State<MessageRecordButton> {

  final Record _recorder = Record();

  @override
  void dispose() {
    super.dispose();
    Future.delayed(Duration.zero, _recorder.stop);
    Future.delayed(Duration.zero, _recorder.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) async {
          // TODO: Implement voice message recording
          debugPrint("Down");
          HapticFeedback.vibrate();
          widget.onRecordStart?.call();
          final dir = await getTemporaryDirectory();
          await _recorder.start(
            path: "${dir.path}/A-${const Uuid().v4()}.wav",
            encoder: AudioEncoder.wav,
            samplingRate: 44100,
          );
        },
        onTapUp: (_) async {
          debugPrint("Up");
          if (await _recorder.isRecording()) {
            final recording = await _recorder.stop();
            widget.onRecordEnd?.call(recording == null ? null : File(recording));
          }
        },
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.mic_outlined),
        ),
      ),
    );
  }
}