import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:contacts_plus_plus/apis/session_api.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/client_holder.dart';
import 'package:contacts_plus_plus/models/session.dart';
import 'package:contacts_plus_plus/widgets/formatted_text.dart';
import 'package:contacts_plus_plus/widgets/session_view.dart';
import 'package:flutter/material.dart';

class SessionList extends StatefulWidget {
  const SessionList({super.key});

  @override
  State<SessionList> createState() => _SessionListState();
}

class _SessionListState extends State<SessionList> with AutomaticKeepAliveClientMixin {
  Future<List<Session>>? _sessionsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sessionsFuture ??= SessionApi.getSessions(ClientHolder.of(context).apiClient).then(
      (value) => value.sorted(
        (a, b) => b.sessionUsers.length.compareTo(a.sessionUsers.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Session>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GridView.builder(
                padding: const EdgeInsets.only(top: 10),
                physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
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
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (context) => SessionView(session: session)));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Hero(
                                tag: session.id,
                                child: CachedNetworkImage(
                                  imageUrl: Aux.neosDbToHttp(session.thumbnail),
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
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(.5),
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
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
