import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class CameraImageView extends StatelessWidget {
  const CameraImageView({required this.file, super.key});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          PhotoView(
            imageProvider: FileImage(
              file,
            ),
            initialScale: PhotoViewComputedScale.covered,
            minScale: PhotoViewComputedScale.contained,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        side: BorderSide(width: 1, color: Theme.of(context).colorScheme.error)
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text("Cancel",),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        side: BorderSide(width: 1, color: Theme.of(context).colorScheme.primary)
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text("Okay"),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}