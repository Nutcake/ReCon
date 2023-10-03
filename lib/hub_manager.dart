import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:contacts_plus_plus/config.dart';
import 'package:contacts_plus_plus/models/hub_events.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

class HubManager {
  static const String _eofChar = "";
  static const String _negotiationPacket = "{\"protocol\":\"json\", \"version\":1}$_eofChar";
  static const List<int> _reconnectTimeoutsSeconds = [0, 5, 10, 20, 60];

  final Logger _logger = Logger("Hub");
  final Map<String, dynamic> _headers = {};
  final Map<EventTarget, dynamic Function(List arguments)> _handlers = {};
  final Map<String, dynamic Function(Map result)> _responseHandlers = {};
  WebSocket? _wsChannel;
  bool _isConnecting = false;
  int _attempts = 0;

  void setHandler(EventTarget target, Function(List args) function) {
    _handlers[target] = function;
  }

  void setHeaders(Map<String, dynamic> headers) {
    _headers.addAll(headers);
  }

  void _onDisconnected(error) async {
    _wsChannel = null;
    _logger.warning("Hub connection died with error '$error', reconnecting...");
    await start();
  }

  Future<void> start() async {
    if (_isConnecting) {
      return;
    }
    _isConnecting = true;
    _wsChannel = await _tryConnect();
    _isConnecting = false;
    _logger.info("Connected to Resonite Hub.");
    _wsChannel!.done.then((error) => _onDisconnected(error));
    _wsChannel!.listen(_handleEvent, onDone: () => _onDisconnected("Connection closed."), onError: _onDisconnected);
    _wsChannel!.add(_negotiationPacket);
  }

  Future<WebSocket> _tryConnect() async {
    while (true) {
      try {
        final ws = await WebSocket.connect(Config.resoniteHubUrl.replaceFirst("https://", "wss://"), headers: _headers);
        _attempts = 0;
        return ws;
      } catch (e) {
        final timeout = _reconnectTimeoutsSeconds[_attempts.clamp(0, _reconnectTimeoutsSeconds.length - 1)];
        _logger.severe(e);
        _logger.severe("Retrying in $timeout seconds");
        await Future.delayed(Duration(seconds: timeout));
        _attempts++;
      }
    }
  }

  void _handleEvent(event) {
    final bodies = event.toString().split(_eofChar);
    final eventBodies = bodies.whereNot((element) => element.isEmpty).map((e) => jsonDecode(e));
    for (final body in eventBodies) {
      final int? rawType = body["type"];
      if (rawType == null) {
        _logger.warning("Received empty event, content was $event");
        continue;
      }
      if (rawType > EventType.values.length) {
        _logger.info("Unhandled event type $rawType: $body");
        continue;
      }
      switch (EventType.values[rawType]) {
        case EventType.streamItem:
        case EventType.completion:
          final handler = _responseHandlers[body["invocationId"]];
          handler?.call(body["result"] ?? {});
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

  void _handleInvocation(body) async {
    final target = EventTarget.parse(body["target"]);
    final args = body["arguments"] ?? [];
    final handler = _handlers[target];
    if (handler == null) {
      _logger.info("Unhandled event received");
      return;
    }
    handler(args);
  }

  void send(String target, {List arguments = const [], Function(Map data)? responseHandler}) {
    final invocationId = const Uuid().v4();
    final data = {
      "type": EventType.invocation.index,
      "invocationId": invocationId,
      "target": target,
      "arguments": arguments,
    };
    if (responseHandler != null) {
      _responseHandlers[invocationId] = responseHandler;
    }
    if (_wsChannel == null) throw "Resonite Hub is not connected";
    _wsChannel!.add(jsonEncode(data) + _eofChar);
  }

  void dispose() {
    _wsChannel?.close();
  }
}
