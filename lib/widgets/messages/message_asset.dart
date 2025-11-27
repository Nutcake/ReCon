import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:recon/apis/record_api.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/client_holder.dart';
import 'package:recon/clients/inventory_client.dart';
import 'package:recon/models/inventory/resonite_directory.dart';
import 'package:recon/models/message.dart';
import 'package:recon/models/photo_asset.dart';
import 'package:recon/models/records/record.dart';
import 'package:recon/string_formatter.dart';
import 'package:recon/widgets/formatted_text.dart';
import 'package:recon/widgets/messages/message_state_indicator.dart';
import 'package:share_plus/share_plus.dart';

class MessageAsset extends StatelessWidget {
  const MessageAsset({required this.message, this.foregroundColor, super.key});

  final Message message;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final content = jsonDecode(message.content);
    final formattedName = FormatNode.fromText(content["name"]);
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: [
          SizedBox(
            height: 256,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: Aux.resdbToHttp(content["thumbnailUri"]),
              imageBuilder: (context, image) {
                return InkWell(
                  onTap: () async {
                    PhotoAsset? photoAsset;
                    try {
                      photoAsset = PhotoAsset.fromTags((content["tags"] as List).map((e) => "$e").toList());
                    } catch (_) {}
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _ImageFullScreenView(
                          message: message,
                          content: content,
                          photoAsset: photoAsset,
                          formattedName: formattedName,
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: message.id,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image(
                        image: image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
              errorWidget: (context, url, error) => const Icon(
                Icons.broken_image,
                size: 64,
              ),
              placeholder: (context, uri) => const Center(child: CircularProgressIndicator()),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FormattedText(
                    formattedName,
                    maxLines: null,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foregroundColor),
                  ),
                ),
              ),
              MessageStateIndicator(
                message: message,
                foregroundColor: foregroundColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageFullScreenView extends StatefulWidget {
  const _ImageFullScreenView({
    required this.message,
    required this.content,
    this.photoAsset,
    required this.formattedName,
  });

  final Message message;
  final Map<String, dynamic> content;
  final PhotoAsset? photoAsset;
  final FormatNode formattedName;

  @override
  State<_ImageFullScreenView> createState() => _ImageFullScreenViewState();
}

class _ImageFullScreenViewState extends State<_ImageFullScreenView> {
  final Future<Directory> _tempDirectoryFuture = getTemporaryDirectory();
  bool _isSaving = false;
  bool _isSavingToInventory = false;

  String _imageUri() {
    if (widget.photoAsset != null) {
      return widget.photoAsset!.imageUri;
    }
    return widget.content["thumbnailUri"] ?? "";
  }

  String _filename() {
    final name = widget.content["name"] ?? "image";
    final uri = _imageUri();
    final ext = path.extension(uri).isNotEmpty ? path.extension(uri) : ".jpg";
    var sanitized = name.replaceAll(RegExp(r'[<>:"|?*\\/]'), '-').replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    sanitized = sanitized.replaceAll(RegExp(r'[. ]+$'), '');
    if (sanitized.isEmpty) sanitized = "image";
    if (sanitized.length > 200) sanitized = sanitized.substring(0, 200);
    return "$sanitized$ext";
  }

  Future<File> _downloadToTemp(String imageUrl, String filename) async {
    final downloadTask = DownloadTask(
      url: imageUrl,
      allowPause: true,
      baseDirectory: BaseDirectory.temporary,
      filename: filename,
      updates: Updates.statusAndProgress,
    );
    final status = await FileDownloader().download(downloadTask);
    if (status.status != TaskStatus.complete) {
      throw status.exception ?? "Download failed";
    }
    final tempDirectory = await _tempDirectoryFuture;
    final file = File("${tempDirectory.path}/$filename");
    if (!file.existsSync()) {
      throw "Downloaded file not found";
    }
    return file;
  }

  Future<void> _saveToDevice() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final uri = _imageUri();
      if (uri.isEmpty) throw "No image URI found";
      final filename = _filename();
      final file = await _downloadToTemp(Aux.resdbToHttp(uri), filename);
      Directory? targetDirectory;
      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          targetDirectory = Directory("${externalDir.parent.path}/Download");
          if (!targetDirectory.existsSync()) {
            targetDirectory = Directory("${externalDir.parent.path}/Downloads");
          }
        }
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
        if (homeDir.isNotEmpty) {
          targetDirectory = Directory("$homeDir/Downloads");
        }
      } else {
        targetDirectory = await getApplicationDocumentsDirectory();
      }
      if (targetDirectory == null) {
        await _shareImage(file);
        return;
      }
      if (!targetDirectory.existsSync()) {
        await targetDirectory.create(recursive: true);
      }
      var finalFilename = filename;
      var counter = 1;
      while (File("${targetDirectory.path}/$finalFilename").existsSync()) {
        final base = path.basenameWithoutExtension(filename);
        final ext = path.extension(filename);
        finalFilename = "$base ($counter)$ext";
        counter++;
      }
      final savedFile = await file.copy("${targetDirectory.path}/$finalFilename");
      await file.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Saved to ${savedFile.path}")),
        );
      }
    } catch (e, s) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save image: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareImage(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: widget.content["name"] ?? "Image");
  }

  Future<void> _shareImageDirect() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final uri = _imageUri();
      if (uri.isEmpty) throw "No image URI found";
      final file = await _downloadToTemp(Aux.resdbToHttp(uri), _filename());
      await _shareImage(file);
    } catch (e, s) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to share image: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveToInventory() async {
    if (_isSavingToInventory) return;
    setState(() => _isSavingToInventory = true);
    try {
      final cHolder = ClientHolder.of(context);
      final inventoryClient = Provider.of<InventoryClient>(context, listen: false);
      final currentDir = await inventoryClient.directoryFuture;
      if (currentDir == null) {
        throw "Inventory not ready";
      }
      final record = Record.fromMap(widget.content);
      final newId = Record.generateId();
      final pathTarget = currentDir.isRoot ? ResoniteDirectory.rootName : currentDir.record.path;
      final timestamp = DateTime.now().toUtc();
      final duplicate = record.copyWith(
        id: newId,
        ownerId: cHolder.apiClient.userId,
        lastModifyingUserId: cHolder.apiClient.userId,
        lastModifyingMachineId: cHolder.settingsClient.currentSettings.machineId.valueOrDefault,
        combinedRecordId: RecordId(id: newId, ownerId: cHolder.apiClient.userId, isValid: true),
        path: pathTarget,
        url: "resrec:///${cHolder.apiClient.userId}/$newId",
        creationTime: timestamp,
        lastModificationTime: timestamp,
        fetchedOn: timestamp,
        isSynced: false,
        globalVersion: 0,
        localVersion: 1,
      );
      await RecordApi.upsertRecord(cHolder.apiClient, record: duplicate);
      await inventoryClient.reloadCurrentDirectory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved to inventory")),
        );
      }
    } catch (e, s) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save to inventory: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingToInventory = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = Aux.resdbToHttp(_imageUri());
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.formattedName.toString()),
        actions: [
          if (_isSaving || _isSavingToInventory)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            Builder(
              builder: (context) {
                try {
                  Provider.of<InventoryClient>(context, listen: false);
                  return IconButton(
                    icon: const Icon(Icons.inventory_2),
                    tooltip: "Save to inventory",
                    onPressed: _saveToInventory,
                  );
                } catch (_) {
                  return const SizedBox.shrink();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: "Save to device",
              onPressed: _saveToDevice,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: "Share",
              onPressed: _shareImageDirect,
            ),
          ],
        ],
      ),
      body: PhotoView(
        minScale: PhotoViewComputedScale.contained,
        imageProvider: CachedNetworkImageProvider(imageUrl),
        heroAttributes: PhotoViewHeroAttributes(tag: widget.message.id),
      ),
    );
  }
}
