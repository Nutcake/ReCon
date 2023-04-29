import 'package:contacts_plus/apis/message_api.dart';
import 'package:contacts_plus/main.dart';
import 'package:contacts_plus/models/friend.dart';
import 'package:contacts_plus/models/message.dart';
import 'package:flutter/material.dart';

class Messages extends StatefulWidget {
  const Messages({required this.friend, super.key});

  final Friend friend;

  @override
  State<StatefulWidget> createState() => _MessagesState();

}

class _MessagesState extends State<Messages> {
  Future<Iterable<Message>>? _messagesFuture;
  late final MessageApi _messageApi;

  void _refreshMessages() {
    _messagesFuture = _messageApi.getUserMessages(userId: widget.friend.id)..then((value) => value.toList());
  }

  @override
  void initState() {
    super.initState();
    _messageApi = MessageApi(
      apiClient: AuthenticatedClient
      .staticOf(context)
      .client,
    );
    _refreshMessages();
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = AuthenticatedClient.of(context).client;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friend.username),
      ),
      body: FutureBuilder(
        future: _messagesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data as Iterable<Message>;
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final entry = data.elementAt(index);
                if (entry.senderId == apiClient.userId) {
                  return MyMessageBubble(message: entry);
                } else {
                  return OtherMessageBubble(message: entry);
                }
              },
            );
          } else if (snapshot.hasError) {
            return Column(
              children: [
                Text("Failed to load messages:\n${snapshot.error}"),
                TextButton.icon(
                  onPressed: () {

                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                ),
              ],
            );
          } else {
            return const LinearProgressIndicator();
          }
        },
      ),
    );
  }
}

class MyMessageBubble extends StatelessWidget {
  const MyMessageBubble({required this.message, super.key});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          margin: const EdgeInsets.only(left:16),
          padding: const EdgeInsets.all(12),
          child: Text(message.content, softWrap: true,),
        ),
      ],
    );
  }
}


class OtherMessageBubble extends StatelessWidget {
  const OtherMessageBubble({required this.message, super.key});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          color: Theme.of(context).colorScheme.secondaryContainer,
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.all(12),
          child: Text(message.content, softWrap: true,),
        ),
      ],
    );
  }
}