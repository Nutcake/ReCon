import 'dart:async';
import 'dart:developer';

import 'package:contacts_plus/config.dart';
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
    return MessageType.values.firstWhere((element) => element.name.toLowerCase() == name.toLowerCase(),
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

class Message extends Comparable {
  final String id;
  final String recipientId;
  final String senderId;
  final MessageType type;
  final String content;
  final DateTime sendTime;
  final MessageState state;

  Message({required this.id, required this.recipientId, required this.senderId, required this.type,
    required this.content, required this.sendTime, this.state=MessageState.local});

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
      state: withState ?? (map["readTime"] != null ? MessageState.read : MessageState.local)
    );
  }

  Message copy() => copyWith();

  Message copyWith({String? id, String? recipientId, String? senderId, MessageType? type, String? content,
    DateTime? sendTime, MessageState? state}) {
    return Message(id: id ?? this.id, recipientId: recipientId ?? this.recipientId, senderId: senderId ?? this.senderId,
        type: type ?? this.type, content: content ?? this.content, sendTime: sendTime ?? this.sendTime,
        state: state ?? this.state
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
  int compareTo(other) {
    return other.sendTime.compareTo(sendTime);
  }
}

class MessageCache {
  final List<Message> _messages;

  List<Message> get messages => _messages;

  MessageCache({required List<Message> messages})
      : _messages = messages;
}