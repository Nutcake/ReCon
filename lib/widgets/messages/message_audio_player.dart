import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';
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
  static final bool _backendReportsPosition = Platform.isLinux || Platform.isWindows;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late final Stream<Duration> _positionStream = _backendReportsPosition ? _audioPlayer.playbackEventStream.map((e) => e.updatePosition).distinct() : _audioPlayer.positionStream;
  Future? _audioFileFuture;
  double? _dragValue;
  bool _resumeAfterDrag = false;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioFileFuture = _loadAudio();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _audioPlayer.pause();
    }
  }

  @override
  void didUpdateWidget(covariant MessageAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id == widget.message.id) return;
    _audioPlayer.stop();
    _dragValue = null;
    _audioFileFuture = _loadAudio();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose().onError((error, stackTrace) {});
    super.dispose();
  }

  Future<void> _loadAudio() async {
    final audioCache = Provider.of<AudioCacheClient>(context, listen: false);
    final file = await audioCache.cachedNetworkAudioFile(AudioClipContent.fromMap(jsonDecode(widget.message.content)));
    _filePath = file.path;
    await _audioPlayer.setFilePath(file.path);
    await _audioPlayer.setLoopMode(LoopMode.off);
  }

  Future<void> _restartAt(Duration position, {required bool play}) async {
    final path = _filePath;
    if (path == null) return;
    await _audioPlayer.pause();
    await _audioPlayer.setFilePath(path, initialPosition: position);
    if (play) unawaited(_audioPlayer.play());
  }

  Widget _createErrorWidget(String error) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 4),
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IntrinsicWidth(
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
                          return const IconButton(icon: Icon(Icons.warning), tooltip: "Failed to load audio-message.", onPressed: null);
                        }
                        final fileReady = fileSnapshot.connectionState == ConnectionState.done && !fileSnapshot.hasError;

                        return IconButton(
                          onPressed: fileReady && snapshot.hasData && playerState != null && playerState.processingState != ProcessingState.loading
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
                                      _restartAt(Duration.zero, play: true);
                                      break;
                                  }
                                }
                              : null,
                          color: widget.foregroundColor,
                          icon: Icon(
                            playerState?.processingState == ProcessingState.completed
                                ? Icons.replay
                                : (playerState?.playing ?? false)
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                        );
                      },
                    ),
                    StreamBuilder<Duration>(
                      stream: _positionStream,
                      builder: (context, snapshot) {
                        final duration = _audioPlayer.duration;
                        final completed = _audioPlayer.processingState == ProcessingState.completed;
                        final canSeek = duration != null && duration > Duration.zero;
                        final position = completed ? (duration ?? Duration.zero) : (snapshot.data ?? Duration.zero);
                        final playbackValue = canSeek ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0) : 0.0;
                        return SliderTheme(
                          data: SliderThemeData(inactiveTrackColor: widget.foregroundColor?.withAlpha(100)),
                          child: Slider(
                            thumbColor: widget.foregroundColor,
                            value: _dragValue ?? playbackValue,
                            onChangeStart: canSeek
                                ? (value) {
                                    _resumeAfterDrag = _audioPlayer.playing && _audioPlayer.processingState != ProcessingState.completed;
                                    _audioPlayer.pause();
                                    setState(() => _dragValue = value);
                                  }
                                : null,
                            onChanged: canSeek ? (value) => setState(() => _dragValue = value) : null,
                            onChangeEnd: canSeek
                                ? (value) async {
                                    final target = duration * value;
                                    if (_audioPlayer.processingState == ProcessingState.completed) {
                                      await _restartAt(target, play: false);
                                    } else {
                                      await _audioPlayer.seek(target);
                                    }
                                    if (!mounted) return;
                                    setState(() => _dragValue = null);
                                    if (_resumeAfterDrag) unawaited(_audioPlayer.play());
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 4),
                    StreamBuilder(
                      stream: _positionStream,
                      builder: (context, snapshot) {
                        final duration = _audioPlayer.duration;
                        final completed = _audioPlayer.processingState == ProcessingState.completed;
                        final position = completed ? (duration ?? Duration.zero) : (snapshot.data ?? Duration.zero);
                        final shown = _dragValue != null && duration != null ? duration * _dragValue! : position;
                        return Text(
                          "${shown.format()}/${duration?.format() ?? "??"}",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: widget.foregroundColor?.withAlpha(150)),
                        );
                      },
                    ),
                    const Spacer(),
                    MessageStateIndicator(message: widget.message, foregroundColor: widget.foregroundColor),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
