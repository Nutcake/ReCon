
import 'dart:async';

import 'package:contacts_plus_plus/apis/session_api.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/client_holder.dart';
import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/models/session.dart';
import 'package:contacts_plus_plus/widgets/default_error_widget.dart';
import 'package:contacts_plus_plus/widgets/friends/expanding_input_fab.dart';
import 'package:contacts_plus_plus/widgets/sessions/session_tile.dart';
import 'package:flutter/material.dart';

class SessionsList extends StatefulWidget {
  const SessionsList({super.key});

  @override
  State<StatefulWidget> createState() => _SessionsListState();

}

class _SessionsListState extends State<SessionsList> with AutomaticKeepAliveClientMixin {
  Timer? _refreshDelay;
  Future<List<Session>>? _sessionsFuture;
  String _searchFilter = "";

  ClientHolder? _clientHolder;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final clientHolder = ClientHolder.of(context);
    if (_clientHolder != clientHolder) {
      _clientHolder = clientHolder;
      final apiClient = _clientHolder!.apiClient;
      _refreshSessions(apiClient);
    }
  }

  void _refreshSessions(ApiClient client) {
    if (_refreshDelay?.isActive ?? false) return;
    _sessionsFuture = SessionApi.getSessions(client);
    _refreshDelay = Timer(const Duration(seconds: 30), (){});
  }

  List<Session> _filterSessions(List<Session> sessions, {String text=""}) {
    return sessions.where((element) => element.name.looseMatch(text)).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        RefreshIndicator(
          onRefresh: () async {
            _refreshSessions(ClientHolder
                .of(context)
                .apiClient);
            await _sessionsFuture; // Keep showing indicator until done;
          },
          child: FutureBuilder(
            future: _sessionsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final sessions = _filterSessions(snapshot.data as List<Session>, text: _searchFilter);
                return GridView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    return LargeSessionTile(session: sessions[index]);
                  },
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 256),
                );
              } else if (snapshot.hasError) {
                return DefaultErrorWidget(
                  title: "Failed to load sessions",
                  message: snapshot.error.toString(),
                  onRetry: () =>
                      _refreshSessions(ClientHolder
                          .of(context)
                          .apiClient),
                );
              } else {
                return const LinearProgressIndicator();
              }
            },
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ExpandingInputFab(
            onInputChanged: (String text) {
              setState(() {
                _searchFilter = text;
              });
            },
            onExpansionChanged: (expanded) {
              if (!expanded) {
                setState(() {
                  _searchFilter = "";
                });
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}