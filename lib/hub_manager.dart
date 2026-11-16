import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:recon/config.dart';
import 'package:recon/models/hub_events.dart';
import 'package:uuid/uuid.dart';

class HubManager {
  static const String _eofChar = "";
  static const String _negotiationPacket = '{"protocol":"json", "version":1}$_eofChar';
  static const String _pingPacket = '{"type":6}$_eofChar';
  static const List<int> _reconnectTimeoutsSeconds = [0, 5, 10, 20, 60];
  static const Duration _connectTimeout = Duration(seconds: 15);
  static const Duration _keepAliveInterval = Duration(seconds: 15);

  final Logger _logger = Logger("Hub");
  final Map<String, dynamic> _headers = {};
  final Map<EventTarget, dynamic Function(List arguments)> _handlers = {};
  final Map<String, void Function(dynamic)> _responseHandlers = {};
  final Map<String, StreamController<dynamic>> _streams = {};
  bool _disposed = false;
  FutureOr<void> Function() onConnected = () {};
  WebSocket? _wsChannel;
  bool _isConnecting = false;
  int _attempts = 0;
  Timer? _keepAliveTimer;
  Completer<void>? _retryDelay;

  void setHandler(EventTarget target, Function(List args) function) {
    _handlers[target] = function;
  }

  void setHeaders(Map<String, dynamic> headers) {
    _headers.addAll(headers);
  }

  bool get isConnected => _wsChannel != null;

  void _onDisconnected(WebSocket socket, dynamic error) {
    if (!identical(socket, _wsChannel)) return;
    _wsChannel = null;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    final openStreams = _streams.values.toList();
    _streams.clear();
    for (final stream in openStreams) {
      stream.addError(error);
      unawaited(stream.close());
    }
    if (_disposed) return;
    _logger.warning("Hub connection died with error '$error', reconnecting...");
    unawaited(start());
  }

  Future<void> start() async {
    if (_isConnecting || _disposed || _wsChannel != null) {
      return;
    }
    _isConnecting = true;
    final WebSocket? initialWs;
    try {
      initialWs = await _tryConnect();
    } finally {
      _isConnecting = false;
    }
    if (initialWs == null) return;
    final ws = initialWs;
    if (_disposed) {
      unawaited(ws.close());
      return;
    }
    _wsChannel = ws;
    _logger.info("Connected to Resonite Hub.");
    ws.pingInterval = _keepAliveInterval;
    ws.listen(
      _handleEvent,
      onDone: () => _onDisconnected(ws, "Connection closed (${ws.closeCode}: ${ws.closeReason})."),
      onError: (e) => _onDisconnected(ws, e),
    );
    ws.add(_negotiationPacket);
    _keepAliveTimer = Timer.periodic(_keepAliveInterval, (_) {
      if (!identical(ws, _wsChannel)) return;
      try {
        ws.add(_pingPacket);
      } catch (e) {
        _onDisconnected(ws, e);
      }
    });
    try {
      await onConnected();
    } catch (e, s) {
      _logger.severe("Error while initializing hub connection", e, s);
    }
  }

  void reconnectNow() {
    if (_disposed || _wsChannel != null) return;
    if (_isConnecting) {
      _attempts = 0;
      final delay = _retryDelay;
      if (delay != null && !delay.isCompleted) delay.complete();
      return;
    }
    unawaited(start());
  }

  Stream<dynamic> stream(String target, {List args = const []}) {
    final id = const Uuid().v4();
    late final StreamController<dynamic> controller;
    controller = StreamController(
      onListen: () {
        if (_wsChannel == null) {
          controller
            ..addError("Resonite Hub is not connected")
            ..close();
          return;
        }
        _streams[id] = controller;
        _wsChannel!.add(
          jsonEncode({
                "type": EventType.streamInvocation.index,
                "invocationId": id,
                "target": target,
                "arguments": args,
              }) +
              _eofChar,
        );
      },
      onCancel: () {
        if (_streams.remove(id) != null) {
          _wsChannel?.add(jsonEncode({"type": EventType.cancelInvocation.index, "invocationId": id}) + _eofChar);
        }
      },
    );
    return controller.stream;
  }

  Future<WebSocket?> _tryConnect() async {
    while (!_disposed) {
      try {
        final connectFuture = WebSocket.connect(Config.resoniteHubUrl.replaceFirst("https://", "wss://"), headers: _headers);
        final ws = await connectFuture.timeout(
          _connectTimeout,
          onTimeout: () {
            unawaited(connectFuture.then((ws) => ws.close(), onError: (_) {}));
            throw TimeoutException("Timed out connecting to Resonite Hub", _connectTimeout);
          },
        );
        _attempts = 0;
        return ws;
      } catch (e) {
        final timeout = _reconnectTimeoutsSeconds[_attempts.clamp(0, _reconnectTimeoutsSeconds.length - 1)];
        _logger
          ..severe(e)
          ..severe("Retrying in $timeout seconds");
        await _waitForRetry(Duration(seconds: timeout));
        _attempts++;
      }
    }
    return null;
  }

  Future<void> _waitForRetry(Duration duration) async {
    final completer = Completer<void>();
    _retryDelay = completer;
    final timer = Timer(duration, () {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
    timer.cancel();
    _retryDelay = null;
  }

  void _handleEvent(dynamic event) {
    if (_disposed) return;
    final bodies = event.toString().split(_eofChar);
    final eventBodies = bodies.whereNot((element) => element.isEmpty).map(jsonDecode);
    for (final Map body in eventBodies) {
      final int? rawType = body["type"];
      if (rawType == null) {
        _logger.warning("Received empty event, content was $event");
        continue;
      }
      if (rawType >= EventType.values.length) {
        _logger.info("Unhandled event type $rawType: $body");
        continue;
      }
      switch (EventType.values[rawType]) {
        case EventType.streamItem:
          _streams[body["invocationId"]]?.add(body["item"]);
          break;
        case EventType.completion:
          final id = body["invocationId"];
          final stream = _streams.remove(id);
          if (stream != null) {
            if (body["error"] != null) {
              stream.addError(body["error"]);
            }
            stream.close();
          } else {
            _responseHandlers.remove(id)?.call(body["result"] ?? {});
          }
          _logger.info("Received completion event: $rawType: $body");
          break;
        case EventType.cancelInvocation:
        case EventType.undefined:
          _logger.info("Received unhandled event: $rawType: $body");
          break;
        case EventType.streamInvocation:
        case EventType.invocation:
          _logger.info("Received invocation-event.");
          _handleInvocation(body);
          break;
        case EventType.ping:
          _logger.info("Received keep-alive.");
          break;
        case EventType.close:
          _logger.severe("Received close-event: ${body["error"]}");
          // Should we trigger a manual reconnect here or just let the remote service close the connection?
          break;
      }
    }
  }

  Future<void> _handleInvocation(Map body) async {
    final target = EventTarget.parse(body["target"]);
    final args = body["arguments"] ?? [];
    final handler = _handlers[target];
    if (handler == null) {
      _logger.warning("Unhandled event received");
      if (kDebugMode) _logger.warning("Invocation target: ${target.name}, args:\n$args");
      return;
    }
    handler(args);
  }

  void send<T>(String target, {List arguments = const [], void Function(T data)? responseHandler}) {
    final invocationId = const Uuid().v4();
    final data = {
      "type": EventType.invocation.index,
      "invocationId": invocationId,
      "target": target,
      "arguments": arguments,
    };
    if (_wsChannel == null) throw "Resonite Hub is not connected";
    if (responseHandler != null) {
      _responseHandlers[invocationId] = (d) => responseHandler(d);
    }
    _wsChannel!.add(jsonEncode(data) + _eofChar);
  }

  Future<T?> sendAndWait<T>(String target, {List arguments = const [], Duration timeout = const Duration(seconds: 5)}) async {
    DateTime? startTime;
    T? result;
    Object? error;
    var hasResponse = false;
    while (!hasResponse && (startTime == null || DateTime.now().isBefore(startTime.add(timeout)))) {
      if (startTime == null) {
        startTime = DateTime.now();
        send(
          target,
          arguments: arguments,
          responseHandler: (data) async {
            try {
              result = data as T;
            } catch (e) {
              error = e;
            }
            hasResponse = true;
          },
        );
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (error != null) {
      throw error!;
    }
    return result;
  }

  Future<void> close() async {
    _disposed = true;
    _keepAliveTimer?.cancel();
    final delay = _retryDelay;
    if (delay != null && !delay.isCompleted) delay.complete();
    await _wsChannel?.close().timeout(const Duration(seconds: 1), onTimeout: () {});
  }

  void dispose() {
    _disposed = true;
    _keepAliveTimer?.cancel();
    final delay = _retryDelay;
    if (delay != null && !delay.isCompleted) delay.complete();
    _wsChannel?.close();
  }
}
