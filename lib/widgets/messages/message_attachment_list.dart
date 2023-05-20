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
                colors: [Colors.transparent, Colors.transparent, Colors.transparent, Theme.of(context).colorScheme.background],
                stops: [0.0, 0.0, _showShadow ? 0.96 : 1.0, 1.0], // 10% purple, 80% transparent, 10% purple
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
                          icon:  switch (file.$1) {
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
        IconButton(
          onPressed: widget.disabled ? null : () async {
            final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
            if (result != null) {
              setState(() {
                _loadedFiles.addAll(
                    result.files.map((e) => e.path != null ? (FileType.image, File(e.path!)) : null)
                        .whereNotNull());
              });
            }
          },
          icon: const Icon(Icons.add_photo_alternate),
        ),
        IconButton(
          onPressed: widget.disabled ? null : () async {
            final picture = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MessageCameraView()));
            if (picture != null) {
              _loadedFiles.add(picture);
              await widget.onChange(_loadedFiles);
            }
          },
          icon: const Icon(Icons.add_a_photo),
        ),
        IconButton(
          onPressed: widget.disabled ? null : () async {
            final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: true);
            if (result != null) {
              setState(() {
                _loadedFiles.addAll(
                    result.files.map((e) => e.path != null ? (FileType.any, File(e.path!)) : null).whereNotNull());
              });
            }
          },
          icon: const Icon(Icons.file_present_rounded),
        ),
      ],
    );
  }
}