import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/clients/inventory_client.dart';
import 'package:recon/models/inventory/resonite_directory.dart';
import 'package:recon/models/records/record.dart';
import 'package:recon/widgets/default_error_widget.dart';
import 'package:recon/widgets/inventory/object_inventory_tile.dart';
import 'package:recon/widgets/inventory/path_inventory_tile.dart';

class InventoryBrowser extends StatefulWidget {
  const InventoryBrowser({super.key});

  @override
  State<StatefulWidget> createState() => _InventoryBrowserState();
}

class _InventoryBrowserState extends State<InventoryBrowser> with AutomaticKeepAliveClientMixin {
  static const Duration _refreshLimit = Duration(seconds: 60);
  Timer? _refreshLimiter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final iClient = Provider.of<InventoryClient>(context, listen: false);
    if (iClient.directoryFuture == null) {
      iClient.loadInventoryRoot();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<InventoryClient>(builder: (BuildContext context, InventoryClient iClient, Widget? child) {
      return FutureBuilder<ResoniteDirectory>(
          future: iClient.directoryFuture,
          builder: (context, snapshot) {
            final currentDir = snapshot.data;
            return PopScope(
              canPop: currentDir?.isRoot ?? true,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) {
                  iClient.navigateUp();
                }
              },
              child: RefreshIndicator(
                onRefresh: () async {
                  if (_refreshLimiter?.isActive ?? false) return;
                  try {
                    await iClient.reloadCurrentDirectory();
                    _refreshLimiter = Timer(_refreshLimit, () {});
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Refresh failed: $e")));
                    }
                  }
                },
                child: Builder(
                  builder: (context) {
                    if (snapshot.hasError) {
                      FlutterError.reportError(
                          FlutterErrorDetails(exception: snapshot.error!, stack: snapshot.stackTrace));
                      return DefaultErrorWidget(
                        message: snapshot.error.toString(),
                        onRetry: () {
                          iClient.loadInventoryRoot();
                          iClient.forceNotify();
                        },
                      );
                    }
                    final directory = snapshot.data;
                    final records = directory?.records ?? [];
                    records.sort(
                      (Record a, Record b) => iClient.sortMode.sortFunction(a, b, reverse: iClient.sortReverse),
                    );
                    final paths = records
                        .where((element) =>
                            element.recordType == RecordType.link || element.recordType == RecordType.directory)
                        .toList();
                    final objects = records
                        .where((element) =>
                            element.recordType != RecordType.link && element.recordType != RecordType.directory)
                        .toList();
                    final pathSegments = directory?.absolutePathSegments ?? [];
                    return Stack(
                      children: [
                        ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              child: Wrap(
                                children: pathSegments
                                    .mapIndexed(
                                      (idx, segment) => Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (idx != 0) const Icon(Icons.chevron_right),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                            child: TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: idx == pathSegments.length - 1
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Theme.of(context).colorScheme.onSurface,
                                              ),
                                              onPressed: () {
                                                iClient.navigateUp(times: pathSegments.length - 1 - idx);
                                              },
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                                                ),
                                                child: Text(
                                                  segment,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  softWrap: true,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: paths.length,
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 256,
                                childAspectRatio: 3.5,
                                crossAxisSpacing: 0,
                                mainAxisSpacing: 0,
                              ),
                              itemBuilder: (context, index) {
                                final record = paths[index];
                                return PathInventoryTile(
                                  record: record,
                                  selected: iClient.isRecordSelected(record),
                                  onLongPress: () async {
                                    iClient.toggleRecordSelected(record);
                                  },
                                  onTap: iClient.isAnyRecordSelected
                                      ? () {
                                          iClient.toggleRecordSelected(record);
                                        }
                                      : () async {
                                          try {
                                            await iClient.navigateTo(record);
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text("Failed to open directory: $e")),
                                              );
                                            }
                                          }
                                        },
                                );
                              },
                            ),
                            GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: objects.length,
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 256,
                                childAspectRatio: 1,
                                crossAxisSpacing: 0,
                                mainAxisSpacing: 0,
                              ),
                              itemBuilder: (context, index) {
                                final record = objects[index];
                                return ObjectInventoryTile(
                                  record: record,
                                  selected: iClient.isRecordSelected(record),
                                  onTap: iClient.isAnyRecordSelected
                                      ? () async {
                                          iClient.toggleRecordSelected(record);
                                        }
                                      : () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => Scaffold(
                                                appBar: AppBar(
                                                  title: Text(record.name),
                                                  leading: IconButton(
                                                    icon: Icon(Icons.arrow_back),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                ),
                                                body: PhotoView(
                                                  minScale: PhotoViewComputedScale.contained,
                                                  imageProvider: CachedNetworkImageProvider(Aux.resdbToHttp(record.thumbnailUri)),
                                                  heroAttributes: PhotoViewHeroAttributes(tag: record.id),
                                                ),
                                              ),
                                            )
                                          );
                                        },
                                  onLongPress: () async {
                                    iClient.toggleRecordSelected(record);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: snapshot.connectionState == ConnectionState.waiting
                                ? const LinearProgressIndicator()
                                : null,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: snapshot.connectionState == ConnectionState.waiting
                                ? Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.black38,
                                  )
                                : null,
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
            );
          });
    });
  }

  @override
  bool get wantKeepAlive => true;
}
