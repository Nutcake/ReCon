import 'package:cached_network_image/cached_network_image.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/clients/session_client.dart';
import 'package:recon/models/session.dart';
import 'package:recon/widgets/default_error_widget.dart';
import 'package:recon/widgets/formatted_text.dart';
import 'package:recon/widgets/sessions/session_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SessionList extends StatefulWidget {
  const SessionList({super.key});

  @override
  State<SessionList> createState() => _SessionListState();
}

class _SessionListState extends State<SessionList> with AutomaticKeepAliveClientMixin {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sClient = Provider.of<SessionClient>(context, listen: false);
    if (sClient.sessionsFuture == null) {
      sClient.initSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider.value(
      value: Provider.of<SessionClient>(context),
      child: Consumer<SessionClient>(
        builder: (context, sClient, child) {
          return FutureBuilder<List<Session>>(
            future: sClient.sessionsFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];
              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      sClient.reloadSessions();
                      try {
                        await sClient.sessionsFuture;
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                    child: data.isEmpty && snapshot.connectionState == ConnectionState.done
                        ? const DefaultErrorWidget(
                            title: "No Sessions Found",
                            message: "Try to adjust your filters",
                            iconOverride: Icons.public_off,
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: GridView.builder(
                              padding: const EdgeInsets.only(top: 10),
                              itemCount: data.length,
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 256,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                                childAspectRatio: .8,
                              ),
                              itemBuilder: (context, index) {
                                final session = data[index];
                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => SessionView(session: session)));
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              topRight: Radius.circular(16),
                                            ),
                                            child: Hero(
                                              tag: session.id,
                                              child: CachedNetworkImage(
                                                imageUrl: Aux.resdbToHttp(session.thumbnailUrl),
                                                fit: BoxFit.cover,
                                                errorWidget: (context, url, error) => const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 64,
                                                  ),
                                                ),
                                                placeholder: (context, uri) => const Center(child: CircularProgressIndicator()),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border(top: BorderSide()),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: FormattedText(
                                                        session.formattedName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(
                                                  height: 4,
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        "${session.sessionUsers.length.toString().padLeft(2, "0")}/${session.maxUsers.toString().padLeft(2, "0")} Online",
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting) const LinearProgressIndicator(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
