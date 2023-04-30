import 'package:contacts_plus/api_client.dart';
import 'package:contacts_plus/apis/message_api.dart';
import 'package:contacts_plus/models/friend.dart';
import 'package:contacts_plus/models/message.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Messages extends StatefulWidget {
  const Messages({required this.friend, super.key});

  final Friend friend;

  @override
  State<StatefulWidget> createState() => _MessagesState();

}

class _MessagesState extends State<Messages> {
  Future<Iterable<Message>>? _messagesFuture;
  final TextEditingController _messageTextController = TextEditingController();

  bool _isSendable = false;

  void _refreshMessages() {
    _messagesFuture = MessageApi.getUserMessages(userId: widget.friend.id)..then((value) => value.toList());
  }

  @override
  void initState() {
    super.initState();
    _refreshMessages();
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
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
              reverse: true,
              itemCount: data.length,
              itemBuilder: (context, index) {
                final entry = data.elementAt(index);
                return entry.senderId == apiClient.userId
                      ? MyMessageBubble(message: entry)
                      : OtherMessageBubble(message: entry);
              },
            );
          } else if (snapshot.hasError) {
            return Column(
              children: [
                Text("Failed to load messages:\n${snapshot.error}"),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _refreshMessages();
                    });
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
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: TextField(
                  controller: _messageTextController,
                  maxLines: 4,
                  minLines: 1,
                  onChanged: (text) {
                    if (text.isNotEmpty && !_isSendable) {
                      setState(() {
                        _isSendable = true;
                      });
                    } else if (text.isEmpty && _isSendable) {
                      setState(() {
                        _isSendable = false;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: "Send a message to ${widget.friend.username}...",
                    hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white54),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                splashRadius: 24,
                onPressed: _isSendable ? () {} : null,
                iconSize: 28,
                icon: const Icon(Icons.send),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class MyMessageBubble extends StatelessWidget {
  MyMessageBubble({required this.message, super.key});

  final Message message;
  final DateFormat _dateFormat = DateFormat.Hm();

  @override
  Widget build(BuildContext context) {
    var content = message.content;
    if (message.type == MessageType.sessionInvite) {
      content = "<Session Invite>";
    } else if (message.type == MessageType.sound) {
      content = "<Voice Message>";
    } else if (message.type == MessageType.object) {
      content = "<Asset>";
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Theme.of(context).colorScheme.primaryContainer,
            margin: const EdgeInsets.only(left: 32, bottom: 16, right: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    content,
                    softWrap: true,
                    maxLines: null,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 6,),
                  Text(
                    _dateFormat.format(message.sendTime),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class OtherMessageBubble extends StatelessWidget {
  OtherMessageBubble({required this.message, super.key});

  final Message message;
  final DateFormat _dateFormat = DateFormat.Hm();

  @override
  Widget build(BuildContext context) {
    var content = message.content;
    if (message.type == MessageType.sessionInvite) {
      content = "<Session Invite>";
    } else if (message.type == MessageType.sound) {
      content = "<Voice Message>";
    } else if (message.type == MessageType.object) {
      content = "<Asset>";
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Flexible(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Theme
                .of(context)
                .colorScheme
                .secondaryContainer,
            margin: const EdgeInsets.only(right: 32, bottom: 16, left: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    softWrap: true,
                    maxLines: null,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 6,),
                  Text(
                    _dateFormat.format(message.sendTime),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MessageStatusIndicator extends StatelessWidget {
  const MessageStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

}