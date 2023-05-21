import 'dart:io';

import 'package:collection/collection.dart';
import 'package:contacts_plus_plus/widgets/messages/message_camera_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class MessageAttachmentList extends StatefulWidget {
  const MessageAttachmentList({required this.onChange, required this.disabled, this.initialFiles, super.key});

  final List<(FileType, File)>? initialFiles;
  final Function(List<(FileType, File)> files) onChange;
  final bool disabled;

  @override
  State<MessageAttachmentList> createState() => _MessageAttachmentListState();
}

class _MessageAttachmentListState extends State<MessageAttachmentList> {
  final List<(FileType, File)> _loadedFiles = [];
  final ScrollController _scrollController = ScrollController();
  bool _showShadow = true;

  @override
  void initState() {
    super.initState();
    _loadedFiles.clear();
    _loadedFiles.addAll(widget.initialFiles ?? []);
    _scrollController.addListener(() {
      if (_scrollController.position.maxScrollExtent > 0 && !_showShadow) {
        setState(() {
          _showShadow = true;
        });
      }
      if (_scrollController.position.atEdge && _scrollController.position.pixels > 0
          && _showShadow) {
        setState(() {
          _showShadow = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, Colors.transparent, Colors.transparent, Theme
                    .of(context)
                    .colorScheme
                    .background
                ],
                stops: [0.0, 0.0, _showShadow ? 0.90 : 1.0, 1.0], // 10% purple, 80% transparent, 10% purple
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstOut,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: _loadedFiles.map((file) =>
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 4.0),
                        child: TextButton.icon(
                            onPressed: widget.disabled ? null : () {
                              showDialog(context: context, builder: (context) =>
                                  AlertDialog(
                                    title: const Text("Remove attachment"),
                                    content: Text(
                                        "This will remove attachment '${basename(
                                            file.$2.path)}', are you sure?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("No"),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          _loadedFiles.remove(file);
                                          await widget.onChange(_loadedFiles);
                                        },
                                        child: const Text("Yes"),
                                      )
                                    ],
                                  ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Theme
                                  .of(context)
                                  .colorScheme
                                  .onBackground,
                              side: BorderSide(
                                  color: Theme
                                      .of(context)
                                      .colorScheme
                                      .primary,
                                  width: 1
                              ),
                            ),
                            label: Text(basename(file.$2.path)),
                            icon: switch (file.$1) {
                              FileType.image => const Icon(Icons.image),
                              _ => const Icon(Icons.attach_file)
                            }
                        ),
                      ),
                  ).toList()
              ),
            ),
          ),
        ),
        PopupMenuButton<DocumentType>(
          offset: const Offset(0, -64),
          constraints: const BoxConstraints.tightFor(width: 48 * 3, height: 64),
          shadowColor: Colors.transparent,
          position: PopupMenuPosition.over,
          color: Colors.transparent,
          enableFeedback: true,
          padding: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          iconSize: 24,
          itemBuilder: (context) =>
          [
            PopupMenuItem(
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    iconSize: 24,
                    style: IconButton.styleFrom(
                        backgroundColor: Theme
                            .of(context)
                            .colorScheme
                            .surface,
                        foregroundColor: Theme
                            .of(context)
                            .colorScheme
                            .onSurface,
                        side: BorderSide(
                          width: 1,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .secondary,
                        )
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
                      if (result != null) {
                        setState(() {
                          _loadedFiles.addAll(
                              result.files.map((e) => e.path != null ? (FileType.image, File(e.path!)) : null)
                                  .whereNotNull());
                        });
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.image,),
                  ),
                  IconButton(
                    iconSize: 24,
                    style: IconButton.styleFrom(
                        backgroundColor: Theme
                            .of(context)
                            .colorScheme
                            .surface,
                        foregroundColor: Theme
                            .of(context)
                            .colorScheme
                            .onSurface,
                        side: BorderSide(
                          width: 1,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .secondary,
                        )
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final picture = await Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const MessageCameraView())) as File?;
                      if (picture != null) {
                        _loadedFiles.add((FileType.image, picture));
                        await widget.onChange(_loadedFiles);
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.camera,),
                  ),
                  IconButton(
                    iconSize: 24,
                    style: IconButton.styleFrom(
                        backgroundColor: Theme
                            .of(context)
                            .colorScheme
                            .surface,
                        foregroundColor: Theme
                            .of(context)
                            .colorScheme
                            .onSurface,
                        side: BorderSide(
                          width: 1,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .secondary,
                        )
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: true);
                      if (result != null) {
                        setState(() {
                          _loadedFiles.addAll(
                              result.files.map((e) => e.path != null ? (FileType.any, File(e.path!)) : null)
                                  .whereNotNull());
                        });
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.file_present_rounded,),
                  ),
                ],
              ),
            ),
          ],
          icon: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(64),
              border: Border.all(
                color: Theme
                    .of(context)
                    .colorScheme
                    .primary,
              ),
            ),
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

enum DocumentType {
  gallery,
  camera,
  rawFile;
}

class PopupMenuIcon<T> extends PopupMenuEntry<T> {
  const PopupMenuIcon({this.radius=24, this.value, required this.icon, this.onPressed, super.key});

  final T? value;
  final double radius;
  final Widget icon;
  final void Function()? onPressed;

  @override
  State<StatefulWidget> createState() => _PopupMenuIconState();

  @override
  double get height => radius;

  @override
  bool represents(T? value) => this.value == value;

}

class _PopupMenuIconState extends State<PopupMenuIcon> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(128),
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        margin: const EdgeInsets.all(1),
        child: InkWell(
          child: widget.icon,
        ),
      ),
    );
  }
}