import 'dart:isolate';
import 'dart:ui';

import 'package:recon/auxiliary.dart';
import 'package:recon/clients/inventory_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

class InventoryBrowserAppBar extends StatefulWidget {
  const InventoryBrowserAppBar({super.key});

  @override
  State<InventoryBrowserAppBar> createState() => _InventoryBrowserAppBarState();
}

class _InventoryBrowserAppBarState extends State<InventoryBrowserAppBar> {
  final ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      // Not useful yet? idk...
      String id = data[0];
      DownloadTaskStatus status = DownloadTaskStatus(data[1]);
      int progress = data[2];
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryClient>(
      builder: (BuildContext context, InventoryClient iClient, Widget? child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: !iClient.isAnyRecordSelected
              ? AppBar(
                  key: const ValueKey("default-appbar"),
                  title: const Text("Inventory"),
                )
              : AppBar(
                  key: const ValueKey("selection-appbar"),
                  title: Text("${iClient.selectedRecordCount} Selected"),
                  leading: IconButton(
                    onPressed: () {
                      iClient.clearSelectedRecords();
                    },
                    icon: const Icon(Icons.close),
                  ),
                  actions: [
                    if (iClient.onlyFilesSelected)
                      IconButton(
                        onPressed: () async {
                          final selectedRecords = iClient.selectedRecords;

                          final assetUris = selectedRecords.map((record) => record.assetUri).toList();
                          final thumbUris = selectedRecords.map((record) => record.thumbnailUri).toList();

                          final selectedUris = await showDialog<List<String>>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                icon: const Icon(Icons.download),
                                title: const Text("Download what?"),
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Divider(),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).pop(assetUris);
                                      },
                                      icon: const Icon(Icons.data_object),
                                      label: Text(
                                        "Asset${iClient.selectedRecordCount != 1 ? "s" : ""} (${assetUris.map((e) => extension(e)).toList().unique().join(", ")})",
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).pop(thumbUris);
                                      },
                                      icon: const Icon(Icons.image),
                                      label: Text(
                                        "Thumbnail${iClient.selectedRecordCount != 1 ? "s" : ""} (${thumbUris.map((e) => extension(e)).toList().unique().join(", ")})",
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                          if (selectedUris == null) return;

                          final directory = await FilePicker.platform.getDirectoryPath(dialogTitle: "Download to...");
                          if (directory == null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Selection aborted."),
                                ),
                              );
                            }
                            return;
                          }
                          if (directory == "/") {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Selected directory is invalid"),
                                ),
                              );
                            }
                            return;
                          }
                          for (var record in selectedRecords) {
                            final uri = selectedUris == thumbUris ? record.thumbnailUri : record.thumbnailUri;
                            await FlutterDownloader.enqueue(
                              url: Aux.resdbToHttp(uri),
                              savedDir: directory,
                              showNotification: true,
                              openFileFromNotification: false,
                              fileName:
                                  "${record.id.split("-")[1]}-${record.formattedName.toString()}${extension(uri)}",
                            );
                          }
                          iClient.clearSelectedRecords();
                        },
                        icon: const Icon(Icons.download),
                      ),
                    const SizedBox(
                      width: 4,
                    ),
                    IconButton(
                      onPressed: () async {
                        var loading = false;
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  icon: const Icon(Icons.delete),
                                  title: Text(iClient.selectedRecordCount == 1
                                      ? "Really delete this Record?"
                                      : "Really delete ${iClient.selectedRecordCount} Records?"),
                                  content: const Text("This action cannot be undone!"),
                                  actionsAlignment: MainAxisAlignment.spaceBetween,
                                  actions: [
                                    TextButton(
                                      onPressed: loading
                                          ? null
                                          : () {
                                              Navigator.of(context).pop(false);
                                            },
                                      child: const Text("Cancel"),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (loading)
                                          const SizedBox.square(
                                            dimension: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        TextButton(
                                          onPressed: loading
                                              ? null
                                              : () async {
                                                  setState(() {
                                                    loading = true;
                                                  });
                                                  try {
                                                    await iClient.deleteSelectedRecords();
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text("Failed to delete one or more records: $e"),
                                                        ),
                                                      );
                                                    }
                                                    setState(() {
                                                      loading = false;
                                                    });
                                                  }
                                                  if (context.mounted) {
                                                    Navigator.of(context).pop(true);
                                                  }
                                                  iClient.reloadCurrentDirectory();
                                                },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Theme.of(context).colorScheme.error,
                                          ),
                                          child: const Text("Delete"),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.delete),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                  ],
                ),
        );
      },
    );
  }
}
