import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/clients/session_client.dart';
import 'package:recon/models/session.dart';
import 'package:recon/widgets/default_error_widget.dart';
import 'package:recon/widgets/formatted_text.dart';
import 'package:recon/widgets/sessions/session_view.dart';
import 'package:recon/widgets/translucent_glass.dart';

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
    final ThemeData theme = Theme.of(context);

    super.build(context);
    return ChangeNotifierProvider.value(
      value: Provider.of<SessionClient>(context),
      child: Consumer<SessionClient>(
        builder: (BuildContext context, SessionClient sClient, Widget? child) {
          return FutureBuilder<List<Session>>(
            future: sClient.sessionsFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];
              return RefreshIndicator(
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
                child: Stack(
                  children: [
                    data.isEmpty && snapshot.connectionState == ConnectionState.done
                        ? const DefaultErrorWidget(
                            title: "No Sessions Found",
                            message: "Try to adjust your filters",
                            iconOverride: Icons.public_off,
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: GridView.builder(
                              padding: const EdgeInsets.only(top: 10),
                              itemCount: data.length,
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 256,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: .8,
                              ),
                              itemBuilder: (context, index) {
                                final session = data[index];
                                return TranslucentGlass.card(
                                  context,
                                  padding: const EdgeInsets.all(0),
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: TranslucentGlass.defaultTopGradient(context),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(builder: (context) => SessionView(session: session)));
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 5,
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
                                              placeholder: (context, uri) =>
                                                  const Center(child: CircularProgressIndicator()),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
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
                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                          color: theme.colorScheme.onSurface.withOpacity(.5),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                    if (snapshot.connectionState == ConnectionState.waiting) const LinearProgressIndicator()
                  ],
                ),
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
