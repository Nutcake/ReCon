
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:contacts_plus_plus/api_client.dart';
import 'package:contacts_plus_plus/config.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  final ApiClient _apiClient;
  final Map<String, MessageCache> _messageCache = {};
  final Map<String, Function> _updateListeners = {};
  WebSocketChannel? _wsChannel;

  NeosHub({required ApiClient apiClient})
      : _apiClient = apiClient {
    start();
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

  Future<void> start() async {
    if (!_apiClient.isAuthenticated) {
      log("Hub not authenticated.");
      return;
    }
    final response = await http.post(
      Uri.parse("${Config.neosHubUrl}/negotiate"),
      headers: _apiClient.authorizationHeader,
    );

    ApiClient.checkResponse(response);
    final body = jsonDecode(response.body);
    final url = (body["url"] as String?)?.replaceFirst("https://", "wss://");
    final wsToken = body["accessToken"];

    if (url == null || wsToken == null) {
      throw "Invalid response from server";
    }

    _wsChannel = WebSocketChannel.connect(Uri.parse("$url&access_token=$wsToken"));
    _wsChannel!.stream.listen(_handleEvent);
    _wsChannel!.sink.add(_negotiationPacket);
    log("[Hub]: Connected!");
  }

  void registerListener(String userId, Function function) => _updateListeners[userId] = function;
  void unregisterListener(String userId) => _updateListeners.remove(userId);
  void notifyListener(String userId) => _updateListeners[userId]?.call();

  void _handleEvent(event) {
    final body = jsonDecode((event.toString().replaceAll(eofChar, "")));
    final int rawType = body["type"] ?? 0;
    if (rawType > EventType.values.length) {
      log("[Hub]: Unhandled event type $rawType: $body");
      return;
    }
    switch (EventType.values[rawType]) {
      case EventType.unknown:
        log("[Hub]: Unknown event received: $rawType");
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
        log("Unknown event-target in message: $body");
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
    if (_wsChannel == null) throw "Neos Hub is not connected";
    final msgBody = message.toMap();
    final data = {
      "type": EventType.message.index,
      "target": "SendMessage",
      "arguments": [
        msgBody
      ],
    };
    final cache = await getCache(message.recipientId);
    cache.messages.add(message);
    _wsChannel!.sink.add(jsonEncode(data)+eofChar);
    notifyListener(message.recipientId);
  }
}
