import 'dart:async';
import 'dart:developer';

import 'package:recon/apis/message_api.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/clients/api_client.dart';
import 'package:recon/string_formatter.dart';
import 'package:uuid/uuid.dart';

enum MessageType {
  unknown,
  text,
  sound,
  sessionInvite,
  object;

  static const Map<MessageType, String> _mapper = {
    MessageType.text: "Text",
    MessageType.sound: "Sound",
    MessageType.sessionInvite: "SessionInvite",
    MessageType.object: "Object",
  };

  factory MessageType.fromName(String name) {
    return MessageType.values.firstWhere(
      (element) => element.name.toLowerCase() == name.toLowerCase(),
      orElse: () => MessageType.unknown,
    );
  }

  String? toName() {
    return _mapper[this];
  }
}

enum MessageState {
  local,
  sent,
  read,
}

class Message implements Comparable {
  final String id;
  final String recipientId;
  final String senderId;
  final MessageType type;
  final String content;
  final FormatNode formattedContent;
  final DateTime sendTime;
  final MessageState state;

  Message({required this.id, required this.recipientId, required this.senderId, required this.type, required this.content, required DateTime sendTime, required this.state})
      : formattedContent = FormatNode.fromText(content),
        sendTime = sendTime.toUtc();

  factory Message.fromMap(Map map, {MessageState? withState}) {
    final typeString = (map["messageType"] as String?) ?? "";
    final type = MessageType.fromName(typeString);
    if (type == MessageType.unknown && typeString.isNotEmpty) {
      log("Unknown MessageType '$typeString' in response");
    }
    return Message(
      id: map["id"],
      recipientId: map["recipientId"],
      senderId: map["senderId"],
      type: type,
      content: map["content"],
      sendTime: DateTime.parse(map["sendTime"]),
      state: withState ?? (map["readTime"] != null ? MessageState.read : MessageState.sent),
    );
  }

  Message copy() => copyWith();

  Message copyWith({String? id, String? recipientId, String? senderId, MessageType? type, String? content, DateTime? sendTime, MessageState? state}) {
    return Message(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      content: content ?? this.content,
      sendTime: sendTime ?? this.sendTime,
      state: state ?? this.state,
    );
  }

  Map toMap() => {
        "id": id,
        "recipientId": recipientId,
        "senderId": senderId,
        "ownerId": senderId,
        "messageType": type.toName(),
        "content": content,
        "sendTime": sendTime.toIso8601String(),
      };

  static String generateId() {
    return "MSG-${const Uuid().v4()}";
  }

  @override
  int compareTo(covariant Message other) {
    return other.sendTime.compareTo(sendTime);
  }
}

class MessageCache {
  final List<Message> _messages = [];
  final ApiClient _apiClient;
  final String _userId;
  Object? error;

  List<Message> get messages => _messages;

  MessageCache({required ApiClient apiClient, required String userId})
      : _apiClient = apiClient,
        _userId = userId;

  /// Adds a message to the cache, ensuring integrity of the message cache.
  /// Returns true if the message was inserted into the cache and false if an existing message was overwritten.
  bool addMessage(Message message) {
    final existingIdx = _messages.indexWhere((element) => element.id == message.id);
    if (existingIdx == -1) {
      _messages.insert(0, message);
      _ensureIntegrity();
    } else {
      _messages[existingIdx] = message;
      _messages.sort(); // Overwriting can't create duplicates, so we just need to sort.
    }
    return existingIdx == -1;
  }

  /// Sets the state of an existing message by id.
  /// Returns true if a message with the specified id exists and was modified and false if the message doesn't exist.
  bool setMessageState(String messageId, MessageState state) {
    final messageIdx = _messages.indexWhere((element) => element.id == messageId);
    if (messageIdx == -1) return false;
    _messages[messageIdx] = _messages[messageIdx].copyWith(state: state);
    return true;
  }

  Future<MessageCache> loadOlderMessages() async {
    // final olderMessages = await MessageApi.getUserMessages(_apiClient, userId: _userId, fromTime: _messages.last.sendTime);
    // Loading older messages is not conveniently supported by the Neos api from what I can tell.
    // We could just extend the amount of messages loaded from today, but that gets extremely inefficient very quickly.
    // For now, just pretend there are no more messages.
    final olderMessages = <Message>[];
    _messages.addAll(olderMessages);
    _ensureIntegrity();
    return this; //lmao
  }

  Future<void> loadMessages() async {
    error = null;
    try {
      final messages = await MessageApi.getUserMessages(_apiClient, userId: _userId);
      _messages.addAll(messages);
      _ensureIntegrity();
    } catch (e) {
      error = e;
    }
  }

  void _ensureIntegrity() {
    _messages
      ..sort()
      ..unique(id: (element) => element.id);
  }
}

class AudioClipContent {
  final String id;
  final String assetUri;

  const AudioClipContent({required this.id, required this.assetUri});

  factory AudioClipContent.fromMap(Map map) {
    return AudioClipContent(
      id: map["id"],
      assetUri: map["assetUri"],
    );
  }
}

class MarkReadBatch {
  final String senderId;
  final List<String> ids;
  final DateTime readTime;

  const MarkReadBatch({required this.senderId, required this.ids, required this.readTime});

  Map toMap() {
    return {
      "senderId": senderId,
      "ids": ids,
      "readTime": readTime.toUtc().toIso8601String(),
    };
  }
}
