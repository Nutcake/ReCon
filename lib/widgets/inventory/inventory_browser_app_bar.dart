import 'dart:io';
import 'dart:ui';

import 'package:background_downloader/background_downloader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/clients/inventory_client.dart';
import 'package:share_plus/share_plus.dart';

class InventoryBrowserAppBar extends StatefulWidget {
  const InventoryBrowserAppBar({super.key});

  @override
  State<InventoryBrowserAppBar> createState() => _InventoryBrowserAppBarState();
}

class _InventoryBrowserAppBarState extends State<InventoryBrowserAppBar> {
  final Future<Directory> _tempDirectoryFuture = getTemporaryDirectory();

  @pragma('vm:entry-point')
  static void downloadCallback(TaskUpdate event) {
    final id = event.task.taskId;
    final status = event is TaskStatusUpdate ? event.status : null;
    final progress = event is TaskProgressUpdate ? event.progress : null;
    final send = IsolateNameServer.lookupPortByName('downloader_send_port');

    send?.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryClient>(
      builder: (context, iClient, _) {
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
                  actions: [
                    PopupMenuButton(
                      icon: const Icon(Icons.swap_vert),
                      onSelected: (value) {
                        iClient.sortReverse = value;
                      },
                      itemBuilder: (context) {
                        return [
                          PopupMenuItem(
                            value: false,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  color: !iClient.sortReverse ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  "Ascending",
                                  style: TextStyle(
                                    color: !iClient.sortReverse ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: true,
                            child: Row(
                              children: [
                                Icon(Icons.arrow_downward, color: iClient.sortReverse ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  "Descending",
                                  style: TextStyle(
                                    color: iClient.sortReverse ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: PopupMenuButton(
                        icon: const Icon(Icons.sort),
                        onSelected: (value) {
                          iClient.sortMode = value;
                        },
                        itemBuilder: (context) {
                          return SortMode.values
                              .map(
                                (e) => PopupMenuItem(
                                  value: e,
                                  child: Row(
                                    children: [
                                      Icon(
                                        e.icon,
                                        color: iClient.sortMode == e ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                        toBeginningOfSentenceCase(e.name) ?? e.name,
                                        style: TextStyle(
                                          color: iClient.sortMode == e ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList();
                        },
                      ),
                    ),
                  ],
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
                    if (iClient.selectedRecordCount == 1 && ((iClient.selectedRecords.firstOrNull?.isLink ?? false) || (iClient.selectedRecords.firstOrNull?.isItem ?? false)))
                      IconButton(
                        onPressed: () {
                          Share.share(iClient.selectedRecords.first.assetUri);
                        },
                        icon: const Icon(Icons.share),
                      ),
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
                                    const SizedBox(height: 8),
                                    ListTile(
                                      onTap: () {
                                        Navigator.of(context).pop(assetUris);
                                      },
                                      leading: const Icon(Icons.data_object),
                                      title: Text(
                                        "Asset${iClient.selectedRecordCount != 1 ? "s" : ""} (${assetUris.map(extension).toList().unique().join(", ")})",
                                      ),
                                    ),
                                    ListTile(
                                      onTap: () {
                                        Navigator.of(context).pop(thumbUris);
                                      },
                                      leading: const Icon(Icons.image),
                                      title: Text(
                                        "Thumbnail${iClient.selectedRecordCount != 1 ? "s" : ""} (${thumbUris.map(extension).toList().unique().join(", ")})",
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

                          for (final record in selectedRecords) {
                            final uri = selectedUris == thumbUris ? record.thumbnailUri : record.assetUri;
                            final filename = "${record.id.split("-")[1]}-${record.formattedName}${extension(uri)}";
                            try {
                              final downloadTask = DownloadTask(
                                url: Aux.resdbToHttp(uri),
                                allowPause: true,
                                baseDirectory: BaseDirectory.temporary,
                                filename: filename,
                                updates: Updates.statusAndProgress,
                              );
                              final downloadStatus = await FileDownloader().download(downloadTask);
                              if (downloadStatus.status == TaskStatus.complete) {
                                final tempDirectory = await _tempDirectoryFuture;
                                final file = File("${tempDirectory.path}/${record.id.split("-")[1]}-${record.formattedName}${extension(uri)}");
                                if (file.existsSync()) {
                                  final newFile = File("$directory/$filename");
                                  await file.copy(newFile.absolute.path);
                                  await file.delete();
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Downloaded ${record.formattedName}"),
                                    ),
                                  );
                                } else {
                                  throw downloadStatus.exception ?? "Unknown Error";
                                }
                              }
                            } catch (e, s) {
                              FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Failed to download '${record.formattedName}':\n$e",
                                    ),
                                  ),
                                );
                              }
                            }
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
                                  title: Text(iClient.selectedRecordCount == 1 ? "Really delete this Record?" : "Really delete ${iClient.selectedRecordCount} Records?"),
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
                                                  await iClient.reloadCurrentDirectory();
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
