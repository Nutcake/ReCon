import 'dart:io';
import 'dart:ui';

import 'package:background_downloader/background_downloader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/clients/inventory_client.dart';
import 'package:recon/models/records/record.dart';
import 'package:share_plus/share_plus.dart';

class InventoryBrowserAppBar extends StatefulWidget {
  const InventoryBrowserAppBar({super.key});

  @override
  State<InventoryBrowserAppBar> createState() => _InventoryBrowserAppBarState();
}

class _MoveRecordsDialog extends StatefulWidget {
  const _MoveRecordsDialog({required this.inventoryClient});

  final InventoryClient inventoryClient;

  @override
  State<_MoveRecordsDialog> createState() => _MoveRecordsDialogState();
}

class _MoveRecordsDialogState extends State<_MoveRecordsDialog> {
  late final Record _rootRecord = Record.inventoryRoot();
  late Record _currentDirectory = _rootRecord;
  late List<Record> _breadcrumbs = [_rootRecord];
  late Future<List<Record>> _recordsFuture;
  bool _creatingFolder = false;

  @override
  void initState() {
    super.initState();
    _recordsFuture =
        widget.inventoryClient.getDirectoryRecords(_currentDirectory);
  }

  void _reloadCurrentDirectory() {
    setState(() {
      _recordsFuture =
          widget.inventoryClient.getDirectoryRecords(_currentDirectory);
    });
  }

  void _navigateTo(Record directory) {
    setState(() {
      _currentDirectory = directory;
      _breadcrumbs = [..._breadcrumbs, directory];
      _recordsFuture =
          widget.inventoryClient.getDirectoryRecords(_currentDirectory);
    });
  }

  void _navigateToBreadcrumb(int index) {
    setState(() {
      _currentDirectory = _breadcrumbs[index];
      _breadcrumbs = _breadcrumbs.sublist(0, index + 1);
      _recordsFuture =
          widget.inventoryClient.getDirectoryRecords(_currentDirectory);
    });
  }

  Future<void> _promptCreateFolder() async {
    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final controller = TextEditingController();
        String? errorText;
        return StatefulBuilder(
          builder: (BuildContext stateContext, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text("New folder"),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Folder name",
                  errorText: errorText,
                ),
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() {
                      errorText = null;
                    });
                  }
                },
                onSubmitted: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isEmpty) {
                    setDialogState(() {
                      errorText = "Name cannot be empty.";
                    });
                    return;
                  }
                  Navigator.pop(dialogContext, trimmed);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () {
                    final trimmed = controller.text.trim();
                    if (trimmed.isEmpty) {
                      setDialogState(() {
                        errorText = "Name cannot be empty.";
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, trimmed);
                  },
                  child: const Text("Create"),
                ),
              ],
            );
          },
        );
      },
    );
    if (name == null) {
      return;
    }
    setState(() {
      _creatingFolder = true;
    });
    try {
      await widget.inventoryClient
          .createDirectory(parent: _currentDirectory, name: name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Created '$name'.")),
        );
      }
      _reloadCurrentDirectory();
    } catch (e, s) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create folder: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _creatingFolder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Move selected records"),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        _breadcrumbs.length,
                        (index) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (index != 0)
                              const Icon(Icons.chevron_right, size: 16),
                            TextButton(
                              onPressed: index == _breadcrumbs.length - 1
                                  ? null
                                  : () => _navigateToBreadcrumb(index),
                              child: Text(
                                _breadcrumbs[index].name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _creatingFolder ? null : _promptCreateFolder,
                  icon: _creatingFolder
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.create_new_folder_outlined),
                  label: const Text("New folder"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: FutureBuilder<List<Record>>(
                future: _recordsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Failed to load directories:\n${snapshot.error}",
                            textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _reloadCurrentDirectory,
                          child: const Text("Retry"),
                        ),
                      ],
                    );
                  }
                  final directories = (snapshot.data ?? [])
                      .where(
                          (record) => record.recordType == RecordType.directory)
                      .toList()
                    ..sort((a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                  return ListView.builder(
                    itemCount: (_currentDirectory != _rootRecord ? 1 : 0) +
                        directories.length,
                    itemBuilder: (context, index) {
                      if (_currentDirectory != _rootRecord && index == 0) {
                        return ListTile(
                          leading: const Icon(Icons.arrow_upward),
                          title: const Text("Up"),
                          onTap: () {
                            if (_breadcrumbs.length > 1) {
                              _navigateToBreadcrumb(_breadcrumbs.length - 2);
                            }
                          },
                        );
                      }
                      final directory = directories[
                          index - (_currentDirectory != _rootRecord ? 1 : 0)];
                      return ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(directory.name),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _navigateTo(directory),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _currentDirectory),
          child: Text("Move here (${_currentDirectory.name})"),
        ),
      ],
    );
  }
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
                                  color: !iClient.sortReverse
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  "Ascending",
                                  style: TextStyle(
                                    color: !iClient.sortReverse
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: true,
                            child: Row(
                              children: [
                                Icon(Icons.arrow_downward,
                                    color: iClient.sortReverse
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  "Descending",
                                  style: TextStyle(
                                    color: iClient.sortReverse
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
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
                                        color: iClient.sortMode == e
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                        toBeginningOfSentenceCase(e.name) ??
                                            e.name,
                                        style: TextStyle(
                                          color: iClient.sortMode == e
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
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
                    if (iClient.selectedRecordCount == 1 &&
                        ((iClient.selectedRecords.firstOrNull?.isLink ??
                                false) ||
                            (iClient.selectedRecords.firstOrNull?.isItem ??
                                false)))
                      IconButton(
                        onPressed: () {
                          Share.share(iClient.selectedRecords.first.assetUri);
                        },
                        icon: const Icon(Icons.share),
                      ),
                    if (iClient.onlyFilesSelected) ...[
                      IconButton(
                        onPressed: () async {
                          final selectedRecords = iClient.selectedRecords;

                          final assetUris = selectedRecords
                              .map((record) => record.assetUri)
                              .toList();
                          final thumbUris = selectedRecords
                              .map((record) => record.thumbnailUri)
                              .toList();

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
                                        "Asset${iClient.selectedRecordCount != 1 ? "s" : ""} (${assetUris.map(p.extension).toList().unique().join(", ")})",
                                      ),
                                    ),
                                    ListTile(
                                      onTap: () {
                                        Navigator.of(context).pop(thumbUris);
                                      },
                                      leading: const Icon(Icons.image),
                                      title: Text(
                                        "Thumbnail${iClient.selectedRecordCount != 1 ? "s" : ""} (${thumbUris.map(p.extension).toList().unique().join(", ")})",
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                          if (selectedUris == null) return;

                          final directory = await FilePicker.platform
                              .getDirectoryPath(dialogTitle: "Download to...");
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
                                  content:
                                      Text("Selected directory is invalid"),
                                ),
                              );
                            }
                            return;
                          }

                          for (final record in selectedRecords) {
                            final uri = selectedUris == thumbUris
                                ? record.thumbnailUri
                                : record.assetUri;
                            final filename =
                                "${record.id.split("-")[1]}-${record.formattedName}${p.extension(uri)}";
                            try {
                              final downloadTask = DownloadTask(
                                url: Aux.resdbToHttp(uri),
                                allowPause: true,
                                baseDirectory: BaseDirectory.temporary,
                                filename: filename,
                                updates: Updates.statusAndProgress,
                              );
                              final downloadStatus =
                                  await FileDownloader().download(downloadTask);
                              if (downloadStatus.status ==
                                  TaskStatus.complete) {
                                final tempDirectory =
                                    await _tempDirectoryFuture;
                                final file = File(
                                    "${tempDirectory.path}/${record.id.split("-")[1]}-${record.formattedName}${p.extension(uri)}");
                                if (file.existsSync()) {
                                  final newFile = File("$directory/$filename");
                                  await file.copy(newFile.absolute.path);
                                  await file.delete();
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          "Downloaded ${record.formattedName}"),
                                    ),
                                  );
                                } else {
                                  throw downloadStatus.exception ??
                                      "Unknown Error";
                                }
                              }
                            } catch (e, s) {
                              FlutterError.reportError(
                                  FlutterErrorDetails(exception: e, stack: s));
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
                          final target = await showDialog<Record?>(
                            context: context,
                            builder: (context) =>
                                _MoveRecordsDialog(inventoryClient: iClient),
                          );
                          if (target == null) {
                            return;
                          }
                          final copyCount = iClient.selectedRecordCount;
                          try {
                            await iClient.copySelectedRecordsTo(target);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "Copied $copyCount item${copyCount == 1 ? "" : "s"}."),
                                ),
                              );
                            }
                          } catch (e, s) {
                            FlutterError.reportError(
                                FlutterErrorDetails(exception: e, stack: s));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Failed to copy records: $e"),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.copy_all_outlined),
                        tooltip: "Copy to...",
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      IconButton(
                        onPressed: () async {
                          final target = await showDialog<Record?>(
                            context: context,
                            builder: (context) =>
                                _MoveRecordsDialog(inventoryClient: iClient),
                          );
                          if (target == null) {
                            return;
                          }
                          final movedCount = iClient.selectedRecordCount;
                          try {
                            await iClient.moveSelectedRecordsTo(target);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "Moved $movedCount item${movedCount == 1 ? "" : "s"}."),
                                ),
                              );
                            }
                          } catch (e, s) {
                            FlutterError.reportError(
                                FlutterErrorDetails(exception: e, stack: s));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text("Failed to move records: $e")),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.drive_file_move_outline),
                        tooltip: "Move to...",
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                    ],
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
                                  content: const Text(
                                      "This action cannot be undone!"),
                                  actionsAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
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
                                                    await iClient
                                                        .deleteSelectedRecords();
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              "Failed to delete one or more records: $e"),
                                                        ),
                                                      );
                                                    }
                                                    setState(() {
                                                      loading = false;
                                                    });
                                                  }
                                                  if (context.mounted) {
                                                    Navigator.of(context)
                                                        .pop(true);
                                                  }
                                                  await iClient
                                                      .reloadCurrentDirectory();
                                                },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Theme.of(context)
                                                .colorScheme
                                                .error,
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
