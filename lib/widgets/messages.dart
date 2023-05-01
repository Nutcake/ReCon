import 'package:contacts_plus_plus/api_client.dart';
import 'package:contacts_plus_plus/apis/message_api.dart';
import 'package:contacts_plus_plus/models/friend.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:contacts_plus_plus/neos_hub.dart';
import 'package:contacts_plus_plus/widgets/generic_avatar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Messages extends StatefulWidget {
  const Messages({required this.friend, super.key});

  final Friend friend;

  @override
  State<StatefulWidget> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  static const double headerItemSize = 120.0;
  Future<Iterable<Message>>? _messagesFuture;
  final TextEditingController _messageTextController = TextEditingController();
  ClientHolder? _clientHolder;
  HubHolder? _cacheHolder;

  bool _headerExpanded = false;
  bool _isSendable = false;

  double get _headerHeight => _headerExpanded ? headerItemSize : 0;
  double get _chevronTurns => _headerExpanded ? -1/4 : 1/4;

  void _loadMessages() {
    final cache = _cacheHolder?.hub.getCache(widget.friend.id);
    if (cache != null) {
      _messagesFuture = Future(() => cache.messages);
    } else {
      _messagesFuture = MessageApi.getUserMessages(_clientHolder!.client, userId: widget.friend.id)
        ..then((value) {
          final list = value.toList();
          list.sort();
          _cacheHolder?.hub.setCache(widget.friend.id, list);
          _cacheHolder?.hub.registerListener(widget.friend.id, () => setState(() {}));
          return list;
        });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final clientHolder = ClientHolder.of(context);
    bool dirty = false;
    if (_clientHolder != clientHolder) {
      _clientHolder = clientHolder;
      dirty = true;
    }
    final cacheHolder = HubHolder.of(context);
    if (_cacheHolder != cacheHolder) {
      _cacheHolder = cacheHolder;
      dirty = true;
    }
    if (dirty) _loadMessages();
  }

  @override
  void dispose() {
    _cacheHolder?.hub.unregisterListener(widget.friend.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ClientHolder.of(context).client;
    var sessions = widget.friend.userStatus.activeSessions;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friend.username),
        scrolledUnderElevation: 0.0,
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        /*bottom: sessions.isEmpty ? null : PreferredSize(
          preferredSize: Size.fromHeight(_headerHeight),
          child: Column(
            children: sessions.getRange(0, _headerExpanded ? sessions.length : 1).map((e) => Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GenericAvatar(imageUri: Aux.neosDbToHttp(e.thumbnail),),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.name),
                      Text("${e.sessionUsers.length} users active"),
                    ],
                  ),
                ),
                const Spacer(),
                if (sessions.length > 1) TextButton(onPressed: (){
                  setState(() {
                    _headerExpanded = !_headerExpanded;
                  });
                }, child: Text("+${sessions.length-1}"),)
              ],
            )).toList(),
          ),
        ),*/
      ),
      body: FutureBuilder(
        future: _messagesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = _cacheHolder?.hub.getCache(widget.friend.id)?.messages ?? [];
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ListView.builder(
                reverse: true,
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final entry = data.elementAt(index);
                  return entry.senderId == apiClient.userId
                        ? MyMessageBubble(message: entry)
                        : OtherMessageBubble(message: entry);
                },
              ),
            );
          } else if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 128),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Failed to load messages:", style: Theme.of(context).textTheme.titleMedium,),
                    const SizedBox(height: 16,),
                    Text("${snapshot.error}"),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _loadMessages();
                        });
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const LinearProgressIndicator();
          }
        },
      ),
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 6),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
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
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24)
                    )
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 4.0),
              child: IconButton(
                splashRadius: 24,
                onPressed: _isSendable ? () async {
                  setState(() {
                    _isSendable = false;
                  });
                  final message = Message(
                    id: Message.generateId(),
                    recipientId: widget.friend.id,
                    senderId: apiClient.userId, type: MessageType.text,
                    content: _messageTextController.text,
                    sendTime: DateTime.now().toUtc(),
                  );
                  try {
                    if (_cacheHolder == null) {
                      throw "Hub not connected.";
                    }
                    _cacheHolder!.hub.sendMessage(message);
                    _messageTextController.clear();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to send message\n$e",
                          maxLines: null,
                        ),
                      ),
                    );
                    setState(() {
                      _isSendable = true;
                    });
                  }
                } : null,
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
            margin: const EdgeInsets.only(left: 32, bottom: 16, right: 12),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _dateFormat.format(message.sendTime),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white54),
                      ),
                      const SizedBox(width: 4,),
                      MessageStateIndicator(messageState: message.state),
                    ],
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
            margin: const EdgeInsets.only(right: 32, bottom: 16, left: 12),
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

class MessageStateIndicator extends StatelessWidget {
  const MessageStateIndicator({required this.messageState, super.key});

  final MessageState messageState;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    switch (messageState) {
      case MessageState.local:
        icon = Icons.alarm;
        break;
      case MessageState.sent:
        icon = Icons.done;
        break;
      case MessageState.read:
        icon = Icons.done_all;
        break;
    }
    return Icon(
      icon,
      size: 12,
      color: messageState == MessageState.read ? Theme.of(context).colorScheme.primary : null,
    );
  }

}