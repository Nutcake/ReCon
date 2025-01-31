import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recon/apis/record_api.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/client_holder.dart';
import 'package:recon/models/records/record.dart';
import 'package:recon/models/records/search_sort.dart';
import 'package:recon/widgets/default_error_widget.dart';
import 'package:recon/widgets/formatted_text.dart';

import 'world_view.dart';

class WorldList extends StatefulWidget {
  const WorldList({super.key});

  @override
  State<WorldList> createState() => WorldListState();
}

class WorldListState extends State<WorldList> {
  static const int _pageSize = 15;
  final _dateFormat = DateFormat.yMd();
  final _scrollController = ScrollController();
  Future<List<Record>>? _recordsFuture;
  bool _hasMore = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reloadRecords();
    _scrollController
      ..removeListener(_scrollListener)
      ..addListener(_scrollListener);
  }

  Future<void> _scrollListener() async {
    if (_hasMore && _scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) {
      _hasMore = false;
      final apiClient = ClientHolder.of(context).apiClient;
      final previous = await _recordsFuture ?? [];
      _recordsFuture = Future(
        () async {
          final next = await RecordApi.searchWorldRecords(apiClient, limit: _pageSize, offset: previous.length);
          _hasMore = next.length >= _pageSize;
          return previous + next;
        },
      );
      setState(() {});
    }
  }

  void _reloadRecords() {
    final apiClient = ClientHolder.of(context).apiClient;
    setState(() {
      _recordsFuture = RecordApi.searchWorldRecords(apiClient, limit: _pageSize);
    });
  }

  void changeQuery({
    required String needle,
    required SearchSortDirection sortDirection,
    required SearchSortParameter sortParameter,
  }) {
    final apiClient = ClientHolder.of(context).apiClient;
    setState(() {
      _recordsFuture = RecordApi.searchWorldRecords(
        apiClient,
        limit: _pageSize,
        requiredTags: needle.split(" ").whereNot((element) => element.isEmpty).toList(),
        sortDirection: sortDirection,
        sortParameter: sortParameter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Record>>(
      future: _recordsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          FlutterError.reportError(FlutterErrorDetails(exception: snapshot.error!, stack: snapshot.stackTrace));
          return DefaultErrorWidget(
            title: "Failed to load Worlds",
            message: snapshot.error.toString(),
          );
        }
        final data = snapshot.data ?? [];
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                _reloadRecords();
                await _recordsFuture;
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
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 10),
                        itemCount: data.length,
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 256,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: .8,
                        ),
                        itemBuilder: (context, index) {
                          final world = data[index];
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
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => WorldView(world: world)));
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
                                        tag: world.id,
                                        child: CachedNetworkImage(
                                          imageUrl: Aux.resdbToHttp(world.thumbnailUri),
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
                                                  world.formattedName,
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
                                                  "Last modified ${_dateFormat.format(world.lastModificationTime)}",
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
  }
}
