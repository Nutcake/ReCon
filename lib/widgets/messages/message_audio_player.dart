import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/clients/audio_cache_client.dart';
import 'package:recon/models/message.dart';
import 'package:recon/widgets/messages/message_state_indicator.dart';

class MessageAudioPlayer extends StatefulWidget {
  const MessageAudioPlayer({required this.message, this.foregroundColor, super.key});

  final Message message;
  final Color? foregroundColor;

  @override
  State<MessageAudioPlayer> createState() => _MessageAudioPlayerState();
}

class _MessageAudioPlayerState extends State<MessageAudioPlayer> with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Future? _audioFileFuture;
  double _sliderValue = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _audioPlayer.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final audioCache = Provider.of<AudioCacheClient>(context);
    _audioFileFuture = audioCache
        .cachedNetworkAudioFile(AudioClipContent.fromMap(jsonDecode(widget.message.content)))
        .then((value) => _audioPlayer.setFilePath(value.path))
        .whenComplete(() => _audioPlayer.setLoopMode(LoopMode.off));
  }

  @override
  void didUpdateWidget(covariant MessageAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id == widget.message.id) return;
    final audioCache = Provider.of<AudioCacheClient>(context);
    _audioFileFuture = audioCache.cachedNetworkAudioFile(AudioClipContent.fromMap(jsonDecode(widget.message.content))).then((value) async {
      final path = _audioPlayer.setFilePath(value.path);
      await _audioPlayer.setLoopMode(LoopMode.off);
      await _audioPlayer.pause();
      await _audioPlayer.seek(Duration.zero);
      return path;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose().onError((error, stackTrace) {});
    super.dispose();
  }

  Widget _createErrorWidget(String error) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            error,
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: 3,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: StreamBuilder<PlayerState>(
        stream: _audioPlayer.playerStateStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            FlutterError.reportError(FlutterErrorDetails(exception: snapshot.error!, stack: snapshot.stackTrace));
            return _createErrorWidget("Failed to load audio-message.");
          }
          final playerState = snapshot.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FutureBuilder(
                    future: _audioFileFuture,
                    builder: (context, fileSnapshot) {
                      if (fileSnapshot.hasError) {
                        FlutterError.reportError(FlutterErrorDetails(exception: fileSnapshot.error!, stack: fileSnapshot.stackTrace));
                        return const IconButton(
                          icon: Icon(Icons.warning),
                          tooltip: "Failed to load audio-message.",
                          onPressed: null,
                        );
                      }
                      return IconButton(
                        onPressed: fileSnapshot.hasData && snapshot.hasData && playerState != null && playerState.processingState != ProcessingState.loading
                            ? () {
                                switch (playerState.processingState) {
                                  case ProcessingState.idle:
                                  case ProcessingState.loading:
                                  case ProcessingState.buffering:
                                    break;
                                  case ProcessingState.ready:
                                    if (playerState.playing) {
                                      _audioPlayer.pause();
                                    } else {
                                      _audioPlayer.play();
                                    }
                                    break;
                                  case ProcessingState.completed:
                                    _audioPlayer.seek(Duration.zero);
                                    _audioPlayer.play();
                                    break;
                                }
                              }
                            : null,
                        color: widget.foregroundColor,
                        icon: Icon(
                          ((_audioPlayer.duration ?? const Duration(days: 9999)) - _audioPlayer.position).inMilliseconds < 10
                              ? Icons.replay
                              : ((playerState?.playing ?? false) ? Icons.pause : Icons.play_arrow),
                        ),
                      );
                    },
                  ),
                  StreamBuilder(
                    stream: _audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      _sliderValue = _audioPlayer.duration == null ? 0 : (_audioPlayer.position.inMilliseconds / (_audioPlayer.duration!.inMilliseconds)).clamp(0, 1);
                      return StatefulBuilder(
                        // Not sure if this makes sense here...
                        builder: (context, setState) {
                          return SliderTheme(
                            data: SliderThemeData(
                              inactiveTrackColor: widget.foregroundColor?.withAlpha(100),
                            ),
                            child: Slider(
                              thumbColor: widget.foregroundColor,
                              value: _sliderValue,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (value) async {
                                await _audioPlayer.pause();
                                setState(() {
                                  _sliderValue = value;
                                });
                                await _audioPlayer.seek(
                                  Duration(
                                    milliseconds: (value * (_audioPlayer.duration?.inMilliseconds ?? 0)).round(),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(
                    width: 4,
                  ),
                  StreamBuilder(
                    stream: _audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      return Text(
                        "${snapshot.data?.format() ?? "??"}/${_audioPlayer.duration?.format() ?? "??"}",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: widget.foregroundColor?.withAlpha(150)),
                      );
                    },
                  ),
                  const Spacer(),
                  MessageStateIndicator(
                    message: widget.message,
                    foregroundColor: widget.foregroundColor,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
