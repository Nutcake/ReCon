import 'package:contacts_plus_plus/clients/audio_cache_client.dart';
import 'package:contacts_plus_plus/clients/messaging_client.dart';
import 'package:contacts_plus_plus/models/users/friend.dart';
import 'package:contacts_plus_plus/widgets/default_error_widget.dart';
import 'package:contacts_plus_plus/widgets/friends/friend_online_status_indicator.dart';
import 'package:contacts_plus_plus/widgets/messages/message_input_bar.dart';
import 'package:contacts_plus_plus/widgets/messages/messages_session_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'message_bubble.dart';

class MessagesList extends StatefulWidget {
  const MessagesList({super.key});

  @override
  State<StatefulWidget> createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> with SingleTickerProviderStateMixin {
  final ScrollController _sessionListScrollController = ScrollController();

  bool _showSessionListScrollChevron = false;
  bool _sessionListOpen = true;

  double get _shevronOpacity => _showSessionListScrollChevron ? 1.0 : 0.0;

  @override
  void dispose() {
    _sessionListScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _sessionListScrollController.addListener(() {
      if (_sessionListScrollController.position.maxScrollExtent > 0 && !_showSessionListScrollChevron) {
        setState(() {
          _showSessionListScrollChevron = true;
        });
      }
      if (_sessionListScrollController.position.atEdge &&
          _sessionListScrollController.position.pixels > 0 &&
          _showSessionListScrollChevron) {
        setState(() {
          _showSessionListScrollChevron = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBarColor = Theme.of(context).colorScheme.surface;
    return Consumer<MessagingClient>(builder: (context, mClient, _) {
      final friend = mClient.selectedFriend ?? Friend.empty();
      final cache = mClient.getUserMessageCache(friend.id);
      final sessions = friend.userStatus.activeSessions;

      return Scaffold(
        appBar: AppBar(
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FriendOnlineStatusIndicator(userStatus: friend.userStatus),
              const SizedBox(
                width: 8,
              ),
              Text(friend.username),
              if (friend.isHeadless)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.dns,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSecondaryContainer.withAlpha(150),
                  ),
                ),
            ],
          ),
          actions: [
            if (sessions.isNotEmpty)
              AnimatedRotation(
                turns: _sessionListOpen ? -1 / 4 : 1 / 4,
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _sessionListOpen = !_sessionListOpen;
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ),
            const SizedBox(
              width: 4,
            )
          ],
          scrolledUnderElevation: 0.0,
        ),
        body: Column(
          children: [
            if (sessions.isNotEmpty)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    SizeTransition(sizeFactor: animation, axis: Axis.vertical, child: child),
                child: sessions.isEmpty || !_sessionListOpen
                    ? null
                    : Container(
                        constraints: const BoxConstraints(maxHeight: 64),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(width: 1, color: Colors.black),
                          ),
                        ),
                        child: Stack(
                          children: [
                            ListView.builder(
                              controller: _sessionListScrollController,
                              scrollDirection: Axis.horizontal,
                              itemCount: sessions.length,
                              itemBuilder: (context, index) => SessionTile(session: sessions[index]),
                            ),
                            AnimatedOpacity(
                              opacity: _shevronOpacity,
                              curve: Curves.easeOut,
                              duration: const Duration(milliseconds: 200),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.only(left: 16, right: 4, top: 1, bottom: 1),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        appBarColor.withOpacity(0),
                                        appBarColor,
                                        appBarColor,
                                      ],
                                    ),
                                  ),
                                  height: double.infinity,
                                  child: const Icon(Icons.chevron_right),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
              ),
            Expanded(
              child: Stack(
                children: [
                  Builder(
                    builder: (context) {
                      if (cache == null) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [LinearProgressIndicator()],
                        );
                      }
                      if (cache.error != null) {
                        return DefaultErrorWidget(
                          message: cache.error.toString(),
                          onRetry: () {
                            setState(() {
                              mClient.deleteUserMessageCache(friend.id);
                            });
                            mClient.loadUserMessageCache(friend.id);
                          },
                        );
                      }
                      if (cache.messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.message_outlined),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  "There are no messages here\nWhy not say hello?",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              )
                            ],
                          ),
                        );
                      }
                      return Provider(
                        create: (BuildContext context) => AudioCacheClient(),
                        child: ListView.builder(
                          reverse: true,
                          physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
                          itemCount: cache.messages.length,
                          itemBuilder: (context, index) {
                            final entry = cache.messages[index];
                            if (index == cache.messages.length - 1) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: MessageBubble(
                                  message: entry,
                                ),
                              );
                            }
                            return MessageBubble(
                              message: entry,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            MessageInputBar(
              recipient: friend,
              disabled: cache == null || cache.error != null,
              onMessageSent: () {
                setState(() {});
              },
            ),
          ],
        ),
      );
    });
  }
}
