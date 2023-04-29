import 'dart:developer';

enum MessageType {
  unknown,
  text,
  sound,
}

class Message {
  final String id;
  final String recipientId;
  final String senderId;
  final MessageType type;
  final String content;

  Message({required this.id, required this.recipientId, required this.senderId, required this.type, required this.content});

  factory Message.fromMap(Map map) {
    final typeString = map["messageType"] as String?;
    final type = MessageType.values.firstWhere((element) => element.name == typeString?.toLowerCase(),
      orElse: () => MessageType.unknown,
    );
    if (type == MessageType.unknown && typeString != null) {
      log("Unknown MessageType '$typeString' in response");
    }
    return Message(
      id: map["id"],
      recipientId: map["recipient_id"],
      senderId: map["sender_id"],
      type: type,
      content: map["content"],
    );
  }
}