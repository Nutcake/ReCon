import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:contacts_plus_plus/apis/asset_api.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/client_holder.dart';
import 'package:contacts_plus_plus/models/asset/record.dart';
import 'package:contacts_plus_plus/models/inventory/neos_path.dart';
import 'package:contacts_plus_plus/widgets/default_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InventoryBrowser extends StatefulWidget {
  const InventoryBrowser({super.key});

  @override
  State<StatefulWidget> createState() => _InventoryBrowserState();
}

class _InventoryBrowserState extends State<InventoryBrowser> with AutomaticKeepAliveClientMixin {
  static const Duration _refreshLimit = Duration(seconds: 60);
  Timer? _refreshLimiter;
  Future<List<Record>>? _inventoryFuture;
  final NeosPath _inventoryRoot = const NeosPath(name: "Inventory", parent: null, children: [], record: null);
  late NeosPath _currentPath = _inventoryRoot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _inventoryFuture = _currentPathFuture();
  }

  Future<List<Record>> _currentPathFuture() => AssetApi.getRecordsAt(
    ClientHolder.of(context).apiClient,
    path: _currentPath.absolute,
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async {
        if (_refreshLimiter?.isActive ?? false) return;
        try {
          final records = await _currentPathFuture();
          setState(() {
            _inventoryFuture = Future.value(records);
          });
          _refreshLimiter = Timer(_refreshLimit, () {});
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Refresh failed: $e")));
        }
      },
      child: FutureBuilder(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final records = snapshot.data as List<Record>;
            records.sort((a, b) => a.name.compareTo(b.name));
            final paths = records.where((element) => element.recordType == RecordType.link
                || element.recordType == RecordType.directory).toList();
            final objects = records.where((element) =>
              element.recordType != RecordType.link && element.recordType != RecordType.directory).toList();
            return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 0, 16),
                    child: Text(
                      "${_currentPath.absolute}:",
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: paths.length,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 256,
                        childAspectRatio: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8
                      ),
                      itemBuilder: (context, index) {
                        final record = paths[index];
                        return PathInventoryTile(record: record);
                      },
                    ),
                  ),
                  const SizedBox(height: 8,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: objects.length,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 256,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final record = objects[index];
                        return ObjectInventoryTile(record: record);
                      },
                    ),
                  ),
                ]
            );
          } else if (snapshot.hasError) {
            FlutterError.reportError(FlutterErrorDetails(exception: snapshot.error!, stack: snapshot.stackTrace));
            return DefaultErrorWidget(
              message: snapshot.error.toString(),
              onRetry: () async {
                setState(() {
                  _inventoryFuture = null;
                });
                setState(() {
                  _inventoryFuture = _currentPathFuture();
                });
              },
            );
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: const [
                LinearProgressIndicator(),
                Spacer(),
              ],
            );
          }
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ObjectInventoryTile extends StatelessWidget {
  ObjectInventoryTile({required this.record, super.key});

  final Record record;
  final DateFormat _dateFormat = DateFormat.yMd();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16)),
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        padding: EdgeInsets.zero,
      ),
      onPressed: () {

      },
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: Aux.neosDbToHttp(record.thumbnailUri),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          record.formattedName == null
                              ? Text(record.name, maxLines: 2, overflow: TextOverflow.ellipsis)
                              : RichText(text: record.formattedName!, maxLines: 2, overflow: TextOverflow.ellipsis,),
                          if (record.creationTime != null) Row(
                            children: [
                              const Icon(Icons.access_time, size: 12, color: Colors.white54,),
                              const SizedBox(width: 4,),
                              Text(_dateFormat.format(record.creationTime!), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class PathInventoryTile extends StatelessWidget {
  const PathInventoryTile({required this.record, super.key});

  final Record record;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16)),
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        alignment: Alignment.centerLeft
      ),
      onPressed: () {

      },
      icon: record.recordType == RecordType.directory ? const Icon(Icons.folder) : const Icon(Icons.link),
      label: record.formattedName == null
          ? Text(record.name, maxLines: 3, overflow: TextOverflow.ellipsis)
          : RichText(text: record.formattedName!, maxLines: 3, overflow: TextOverflow.ellipsis),
    );
  }

}