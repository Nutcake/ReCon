import 'dart:io';

import 'package:camera/camera.dart';
import 'package:contacts_plus_plus/widgets/default_error_widget.dart';
import 'package:flutter/material.dart';

class MessageCameraView extends StatefulWidget {
  const MessageCameraView({super.key});

  @override
  State<StatefulWidget> createState() => _MessageCameraViewState();

}

class _MessageCameraViewState extends State<MessageCameraView> {
  final List<CameraDescription> _cameras = [];
  late final CameraController _cameraController;
  Future? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    availableCameras().then((List<CameraDescription> cameras) {
      _cameras.clear();
      _cameras.addAll(cameras);
      _cameraController = CameraController(cameras.first, ResolutionPreset.high);
      setState(() {
        _initializeControllerFuture = _cameraController.initialize();
      });
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Take a picture"),
      ),
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          // Can't use hasData since the future returns void.
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(child: CameraPreview(_cameraController)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(onPressed: () async {
                      final sMsgr = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(context);
                      try {
                        await _initializeControllerFuture;
                        final image = await _cameraController.takePicture();
                        nav.pop(File(image.path));
                      } catch (e) {
                        sMsgr.showSnackBar(SnackBar(content: Text("Failed to capture image: $e")));
                      }
                    }, icon: const Icon(Icons.circle_outlined))
                  ],
                )
              ],
            );
          } else if (snapshot.hasError) {
            return DefaultErrorWidget(
              message: snapshot.error.toString(),
            );
          } else {
            return const Center(child: CircularProgressIndicator(),);
          }
        },
      ),
    );
  }

}
