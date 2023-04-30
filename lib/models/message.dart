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

class Message {
  final String id;
  final String recipientId;
  final String senderId;
  final MessageType type;
  final String content;
  final DateTime sendTime;

  Message({required this.id, required this.recipientId, required this.senderId, required this.type,
    required this.content, required this.sendTime});

  factory Message.fromMap(Map map) {
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
}

class MessageCache {
  late final Timer _timer;
  final List<Message> _messages;
  bool get isValid => _timer.isActive;

  List<Message> get messages => _messages;

  MessageCache({required List<Message> messages})
      : _messages = messages, _timer = Timer(const Duration(seconds: Config.messageCacheValiditySeconds),() {});

  void invalidate() {
    _timer.cancel();
  }
}