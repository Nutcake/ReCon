import 'dart:convert';
import 'dart:io' show Platform;

import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:contacts_plus_plus/widgets/messages/message_state_indicator.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MessageAudioPlayer extends StatefulWidget {
  const MessageAudioPlayer({required this.message, this.foregroundColor, super.key});

  final Message message;
  final Color? foregroundColor;

  @override
  State<MessageAudioPlayer> createState() => _MessageAudioPlayerState();
}

class _MessageAudioPlayerState extends State<MessageAudioPlayer> with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _sliderValue = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
      //TODO: Add caching of audio-files
      _audioPlayer.setUrl(
          Aux.neosDbToHttp(AudioClipContent
              .fromMap(jsonDecode(widget.message.content)).assetUri),
          preload: true).whenComplete(() => _audioPlayer.setLoopMode(LoopMode.off));
    }
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
    _audioPlayer.setUrl(
        Aux.neosDbToHttp(AudioClipContent
            .fromMap(jsonDecode(widget.message.content)).assetUri),
        preload: true).whenComplete(() => _audioPlayer.setLoopMode(LoopMode.off));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _createErrorWidget(String error) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Theme
              .of(context)
              .colorScheme
              .error,),
          const SizedBox(height: 4,),
          Text(error, textAlign: TextAlign.center,
            softWrap: true,
            maxLines: 3,
            style: Theme
                .of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme
                .of(context)
                .colorScheme
                .error),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return _createErrorWidget("Sorry, audio-messages are not\n supported on this platform.");
    }
    return IntrinsicWidth(
      child: StreamBuilder<PlayerState>(
          stream: _audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final playerState = snapshot.data as PlayerState;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
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
                        },
                        color: widget.foregroundColor,
                        icon: SizedBox(
                          width: 24,
                          height: 24,
                          child: playerState.processingState == ProcessingState.loading
                              ? const Center(child: CircularProgressIndicator(),)
                              : Icon(((_audioPlayer.duration ?? Duration.zero) - _audioPlayer.position).inMilliseconds <
                              10 ? Icons.replay
                              : (playerState.playing ? Icons.pause : Icons.play_arrow)),
                        ),
                      ),
                      StreamBuilder(
                          stream: _audioPlayer.positionStream,
                          builder: (context, snapshot) {
                            _sliderValue = _audioPlayer.duration == null ? 0 : (_audioPlayer.position.inMilliseconds /
                                (_audioPlayer.duration!.inMilliseconds)).clamp(0, 1);
                            return StatefulBuilder( // Not sure if this makes sense here...
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
                                        _audioPlayer.pause();
                                        setState(() {
                                          _sliderValue = value;
                                        });
                                        _audioPlayer.seek(Duration(
                                          milliseconds: (value * (_audioPlayer.duration?.inMilliseconds ?? 0)).round(),
                                        ));
                                      },
                                    ),
                                  );
                                }
                            );
                          }
                      )
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 4,),
                      StreamBuilder(
                          stream: _audioPlayer.positionStream,
                          builder: (context, snapshot) {
                            return Text("${snapshot.data?.format() ?? "??"}/${_audioPlayer.duration?.format() ??
                                "??"}",
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: widget.foregroundColor?.withAlpha(150)),
                            );
                          }
                      ),
                      const Spacer(),
                      MessageStateIndicator(message: widget.message, foregroundColor: widget.foregroundColor,),
                    ],
                  )
                ],
              );
            } else if (snapshot.hasError) {
              FlutterError.reportError(FlutterErrorDetails(exception: snapshot.error!, stack: snapshot.stackTrace));
              return _createErrorWidget("Failed to load audio-message.");
            } else {
              return const Center(child: CircularProgressIndicator(),);
            }
          }
      ),
    );
  }
}