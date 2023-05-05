import 'dart:convert';

import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:contacts_plus_plus/models/session.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:collection/collection.dart';

class NotificationChannel {
  final String id;
  final String name;
  final String description;

  const NotificationChannel({required this.name, required this.id, required this.description});
}

class NotificationClient {
  static const NotificationChannel _messageChannel = NotificationChannel(
    id: "messages",
    name: "Messages",
    description: "Messages received from your friends",
  );

  final fln.FlutterLocalNotificationsPlugin _notifier = fln.FlutterLocalNotificationsPlugin()
    ..initialize(
        const fln.InitializationSettings(
          android: fln.AndroidInitializationSettings("ic_notification"),
        )
    );

  Future<void> showUnreadMessagesNotification(Iterable<Message> messages) async {
    if (messages.isEmpty) return;

    final bySender = groupBy(messages, (p0) => p0.senderId);

    for (final entry in bySender.entries) {
      final uname = entry.key.stripUid();
      await _notifier.show(
        uname.hashCode,
        null,
        null,
        fln.NotificationDetails(android: fln.AndroidNotificationDetails(
          _messageChannel.id,
          _messageChannel.name,
          channelDescription: _messageChannel.description,
          importance: fln.Importance.high,
          priority: fln.Priority.max,
          actions: [], //TODO: Make clicking message notification open chat of specified user.
          styleInformation: fln.MessagingStyleInformation(
            fln.Person(
              name: uname,
              bot: false,
            ),
            groupConversation: false,
            messages: entry.value.map((message) {
              String content;
              switch (message.type) {
                case MessageType.unknown:
                  content = "Unknown Message Type";
                  break;
                case MessageType.text:
                  content = message.content;
                  break;
                case MessageType.sound:
                  content = "Audio Message";
                  break;
                case MessageType.sessionInvite:
                  try {
                    final session = Session.fromMap(jsonDecode(message.content));
                    content = "Session Invite to ${session.name}";
                  } catch (e) {
                    content = "Session Invite";
                  }
                  break;
                case MessageType.object:
                  content = "Asset";
                  break;
              }
              return fln.Message(
                content,
                message.sendTime,
                fln.Person(
                  name: uname,
                  bot: false,
                ),
              );
            }).toList(),
          ),
        ),
        ),
      );
    }
  }
}