import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/clients/inventory_client.dart';
import 'package:contacts_plus_plus/models/inventory/neos_path.dart';
import 'package:contacts_plus_plus/models/records/record.dart';
import 'package:contacts_plus_plus/widgets/default_error_widget.dart';
import 'package:contacts_plus_plus/widgets/inventory/object_inventory_tile.dart';
import 'package:contacts_plus_plus/widgets/inventory/path_inventory_tile.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class InventoryBrowser extends StatefulWidget {
  const InventoryBrowser({super.key});

  @override
  State<StatefulWidget> createState() => _InventoryBrowserState();
}

class _InventoryBrowserState extends State<InventoryBrowser> with AutomaticKeepAliveClientMixin {
  static const Duration _refreshLimit = Duration(seconds: 60);
  final Set<String> _selectedIds = {};
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
    return ChangeNotifierProvider.value(
      value: Provider.of<InventoryClient>(context),
      child: Consumer<InventoryClient>(
        builder: (BuildContext context, InventoryClient iClient, Widget? child) {
          return FutureBuilder<NeosDirectory>(
            future: iClient.directoryFuture,
            builder: (context, snapshot) {
              final currentDir = snapshot.data;
              return WillPopScope(
                onWillPop: () async {
                  // Allow pop when at root or not loaded
                  if (currentDir?.isRoot ?? true) {
                    return true;
                  }
                  iClient.navigateUp();
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (_refreshLimiter?.isActive ?? false) return;
                    try {
                      //TODO: Reload path
                      _refreshLimiter = Timer(_refreshLimit, () {});
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Refresh failed: $e")));
                    }
                  },
                  child: Builder(
                    builder: (context) {
                      if (snapshot.hasError) {
                        FlutterError.reportError(FlutterErrorDetails(exception: snapshot.error!, stack: snapshot.stackTrace));
                        return DefaultErrorWidget(
                          message: snapshot.error.toString(),
                          onRetry: () async {
                            iClient.loadInventoryRoot();
                            await iClient.directoryFuture;
                          },
                        );
                      }
                      final directory = snapshot.data;
                      final records = directory?.records ?? [];

                      records.sort((a, b) => a.name.compareTo(b.name));
                      final paths = records
                          .where((element) => element.recordType == RecordType.link || element.recordType == RecordType.directory)
                          .toList();
                      final objects = records
                          .where((element) => element.recordType != RecordType.link && element.recordType != RecordType.directory)
                          .toList();
                      return Stack(
                        children: [
                          ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: Text(
                                  directory?.absolutePath ?? NeosDirectory.rootName,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(color: Theme
                                      .of(context)
                                      .colorScheme
                                      .primary),
                                ),
                              ),
                              GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: paths.length,
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 256, childAspectRatio: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
                                itemBuilder: (context, index) {
                                  final record = paths[index];
                                  return PathInventoryTile(
                                    record: record,
                                    onPressed: () {
                                      iClient.navigateTo(record);
                                    },
                                  );
                                },
                              ),
                              const SizedBox(
                                height: 8,
                              ),
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
                                    return ObjectInventoryTile(
                                      record: record,
                                      selected: _selectedIds.contains(record.id),
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PhotoView(
                                                  minScale: PhotoViewComputedScale.contained,
                                                  imageProvider: CachedNetworkImageProvider(
                                                      Aux.neosDbToHttp(record.thumbnailUri)),
                                                  heroAttributes: PhotoViewHeroAttributes(tag: record.id),
                                                ),
                                          ),
                                        );
                                      },
                                      onLongPress: () async {
                                        setState(() {
                                          if (_selectedIds.contains(record.id)) {
                                            _selectedIds.remove(record.id);
                                          } else {
                                            _selectedIds.add(record.id);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (snapshot.connectionState == ConnectionState.waiting)
                            Align(
                              alignment: Alignment.center,
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.black38,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                            )
                        ],
                      );
                    },
                  ),
                ),
              );
            }
          );
        }
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
