
import 'dart:convert';
import 'dart:developer';
import 'package:contacts_plus/models/authentication_data.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:contacts_plus/api_client.dart';
import 'package:contacts_plus/config.dart';
import 'package:contacts_plus/models/message.dart';
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
  final AuthenticationData _authenticationData;
  final Map<String, MessageCache> _messageCache;
  final Map<String, Function> _updateListeners = {};
  WebSocketChannel? _wsChannel;

  NeosHub({required AuthenticationData authenticationData, required Map<String, MessageCache> messageCache})
      : _authenticationData = authenticationData, _messageCache = messageCache {
    start();
  }

  MessageCache? getCache(String index) => _messageCache[index];

  void setCache(String index, List<Message> messages) {
    _messageCache[index] = MessageCache(messages: messages);
  }

  Future<void> start() async {
    if (!_authenticationData.isAuthenticated) {
      log("Hub not authenticated.");
      return;
    }
    final response = await http.post(
      Uri.parse("${Config.neosHubUrl}/negotiate"),
      headers: _authenticationData.authorizationHeader,
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

  void _handleMessageEvent(body) {
    final target = EventTarget.parse(body["target"]);
    final args = body["arguments"];
    switch (target) {
      case EventTarget.unknown:
        log("Unknown event-target in message: $body");
        return;
      case EventTarget.messageSent:
        final msg = args[0];
        final message = Message.fromMap(msg, withState: MessageState.sent);
        var cache = getCache(message.recipientId);
        if (cache == null) {
          setCache(message.recipientId, [message]);
        } else {
          // Possible race condition
          final existingIndex = cache.messages.indexWhere((element) => element.id == message.id);
          if (existingIndex == -1) {
            cache.messages.add(message);
          } else {
            cache.messages[existingIndex] = message;
          }
          cache.messages.sort();
        }
        notifyListener(message.recipientId);
        break;
      case EventTarget.messageReceived:
        final msg = args[0];
        final message = Message.fromMap(msg);
        var cache = getCache(message.senderId);
        if (cache == null) {
          setCache(message.senderId, [message]);
        } else {
          cache.messages.add(message);
          cache.messages.sort();
        }
        notifyListener(message.senderId);
        break;
      case EventTarget.messagesRead:
        final messageIds = args[0]["ids"] as List;
        final recipientId = args[0]["recipientId"];
        final cache = getCache(recipientId ?? "");
        if (cache == null) return;
        for (var id in messageIds) {
          final idx = cache.messages.indexWhere((element) => element.id == id);
          if (idx == -1) continue;
          cache.messages[idx] = cache.messages[idx].copyWith(state: MessageState.read);
        }
        notifyListener(recipientId);
        break;
    }
  }

  void sendMessage(Message message) {
    if (_wsChannel == null) throw "Neos Hub is not connected";
    final msgBody = message.toMap();
    final data = {
      "type": EventType.message.index,
      "target": "SendMessage",
      "arguments": [
        msgBody
      ],
    };
    _wsChannel!.sink.add(jsonEncode(data)+eofChar);
    var cache = _messageCache[message.recipientId];
    if (cache == null) {
      setCache(message.recipientId, [message]);
      cache = getCache(message.recipientId);
    } else {
      cache.messages.add(message);
    }
    notifyListener(message.recipientId);
  }
}

class HubHolder extends InheritedWidget {
  HubHolder({super.key, required AuthenticationData authenticationData, required Map<String, MessageCache> messageCache, required super.child})
      : hub = NeosHub(authenticationData: authenticationData, messageCache: messageCache);

  final NeosHub hub;

  static HubHolder? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HubHolder>();
  }

  static HubHolder of(BuildContext context) {
    final HubHolder? result = maybeOf(context);
    assert(result != null, 'No HubHolder found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant HubHolder oldWidget) => hub._authenticationData != oldWidget.hub._authenticationData
      || hub._messageCache != oldWidget.hub._messageCache;
}