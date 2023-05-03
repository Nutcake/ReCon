import 'dart:convert';
import 'dart:io';
import 'package:contacts_plus_plus/apis/message_api.dart';
import 'package:http/http.dart' as http;

import 'package:contacts_plus_plus/api_client.dart';
import 'package:contacts_plus_plus/config.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:logging/logging.dart';

enum EventType {
  unknown,
  message,
}

enum EventTarget {
  unknown,
  messageSent,
  messageReceived,
  messagesRead;

  factory EventTarget.parse(String? text) {
    if (text == null) return EventTarget.unknown;
    return EventTarget.values.firstWhere((element) => element.name.toLowerCase() == text.toLowerCase(),
      orElse: () => EventTarget.unknown,
    );
  }
}

class NeosHub {
  static const String eofChar = "";
  static const String _negotiationPacket = "{\"protocol\":\"json\", \"version\":1}$eofChar";
  static const List<int> _reconnectTimeoutsSeconds = [0, 5, 10, 20, 60];
  final ApiClient _apiClient;
  final Map<String, MessageCache> _messageCache = {};
  final Map<String, Function> _updateListeners = {};
  final Logger _logger = Logger("NeosHub");
  WebSocket? _wsChannel;
  bool _isConnecting = false;

  NeosHub({required ApiClient apiClient})
      : _apiClient = apiClient {
    start();
  }

  void _sendData(data) {
    if (_wsChannel == null) throw "Neos Hub is not connected";
    _wsChannel!.add(jsonEncode(data)+eofChar);
  }

  Future<MessageCache> getCache(String userId) async {
    var cache = _messageCache[userId];
    if (cache == null){
      cache = MessageCache(apiClient: _apiClient, userId: userId);
      await cache.loadInitialMessages();
      _messageCache[userId] = cache;
    }
    return cache;
  }

  Future<void> checkUnreads() async {
    final unreads = await MessageApi.getUserMessages(_apiClient, unreadOnly: true);
    for (var message in unreads) {
      throw UnimplementedError();
    }
  }

  void _onDisconnected(error) {
    _logger.warning("Neos Hub connection died with error '$error', reconnecting...");
    start();
  }

  Future<void> start() async {
    if (!_apiClient.isAuthenticated) {
      _logger.info("Tried to connect to Neos Hub without authentication, this is probably fine for now.");
      return;
    }
    if (_isConnecting) {
      return;
    }
    _isConnecting = true;
    _wsChannel = await _tryConnect();
    _isConnecting = false;
    _logger.info("Connected to Neos Hub.");
    _wsChannel!.done.then((error) => _onDisconnected(error));
    _wsChannel!.listen(_handleEvent, onDone: () => _onDisconnected("Connection closed."), onError: _onDisconnected);
    _wsChannel!.add(_negotiationPacket);
  }

  Future<WebSocket> _tryConnect() async {
    int attempts = 0;
    while (true) {
      try {
        final http.Response response;
        try {
          response = await http.post(
            Uri.parse("${Config.neosHubUrl}/negotiate"),
            headers: _apiClient.authorizationHeader,
          );
          ApiClient.checkResponse(response);
        } catch (e) {
          throw "Failed to acquire connection info from Neos API: $e";
        }
        final body = jsonDecode(response.body);
        final url = (body["url"] as String?)?.replaceFirst("https://", "wss://");
        final wsToken = body["accessToken"];

        if (url == null || wsToken == null) {
          throw "Invalid response from server.";
        }
        return await WebSocket.connect("$url&access_token=$wsToken");
      } catch (e) {
        final timeout = _reconnectTimeoutsSeconds[attempts.clamp(0, _reconnectTimeoutsSeconds.length - 1)];
        _logger.severe(e);
        _logger.severe("Retrying in $timeout seconds");
        await Future.delayed(Duration(seconds: timeout));
        attempts++;
      }
    }
  }

  void registerListener(String userId, Function function) => _updateListeners[userId] = function;
  void unregisterListener(String userId) => _updateListeners.remove(userId);
  void notifyListener(String userId) => _updateListeners[userId]?.call();

  void _handleEvent(event) {
    final body = jsonDecode((event.toString().replaceAll(eofChar, "")));
    final int rawType = body["type"] ?? 0;
    if (rawType > EventType.values.length) {
      _logger.info("Unhandled event type $rawType: $body");
      return;
    }
    switch (EventType.values[rawType]) {
      case EventType.unknown:
        _logger.info("[Hub]: Unknown event received: $rawType: $body");
        break;
      case EventType.message:
        _handleMessageEvent(body);
        break;
    }
  }

  void _handleMessageEvent(body) async {
    final target = EventTarget.parse(body["target"]);
    final args = body["arguments"];
    switch (target) {
      case EventTarget.unknown:
        _logger.info("Unknown event-target in message: $body");
        return;
      case EventTarget.messageSent:
        final msg = args[0];
        final message = Message.fromMap(msg, withState: MessageState.sent);
        final cache = await getCache(message.recipientId);
        cache.addMessage(message);
        notifyListener(message.recipientId);
        break;
      case EventTarget.messageReceived:
        final msg = args[0];
        final message = Message.fromMap(msg);
        final cache = await getCache(message.senderId);
        cache.addMessage(message);
        notifyListener(message.senderId);
        break;
      case EventTarget.messagesRead:
        final messageIds = args[0]["ids"] as List;
        final recipientId = args[0]["recipientId"];
        final cache = await getCache(recipientId ?? "");
        for (var id in messageIds) {
          cache.setMessageState(id, MessageState.read);
        }
        notifyListener(recipientId);
        break;
    }
  }

  void sendMessage(Message message) async {
    final msgBody = message.toMap();
    final data = {
      "type": EventType.message.index,
      "target": "SendMessage",
      "arguments": [
        msgBody
      ],
    };
    _sendData(data);
    final cache = await getCache(message.recipientId);
    cache.messages.add(message);
    notifyListener(message.recipientId);
  }

  void markMessagesRead(MarkReadBatch batch) {
    final msgBody = batch.toMap();
    final data = {
      "type": EventType.message.index,
      "target": "MarkMessagesRead",
      "arguments": [
        msgBody
      ],
    };
    _sendData(data);
  }
}
