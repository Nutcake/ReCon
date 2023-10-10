import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _popupIsOpen = false;
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
                    .surfaceVariant
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
                                          setState(() {
                                            _loadedFiles.remove(file);
                                          });
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
                                  .onSurfaceVariant,
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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.decelerate,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axis: Axis.horizontal,
              //position: Tween<Offset>(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(animation),
              child: child,
            ),
          ),
          child: _popupIsOpen ? Row(
            key: const ValueKey("popup-buttons"),
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
                  final picture = await ImagePicker().pickImage(source: ImageSource.camera);
                  if (picture != null) {
                    final file = File(picture.path);
                    if (await file.exists()) {
                      setState(() {
                      _loadedFiles.add((FileType.image, file));
                      });
                      await widget.onChange(_loadedFiles);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to load image file")));
                      }
                    }
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
                },
                icon: const Icon(Icons.file_present_rounded,),
              ),
            ],
          ) : const SizedBox.shrink(),
        ),
        Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: IconButton(onPressed: () {
            setState(() {
              _popupIsOpen = !_popupIsOpen;
            });
          }, icon: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: _popupIsOpen ? 3/8 : 0,
            child: const Icon(Icons.add),
          )),
        )
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