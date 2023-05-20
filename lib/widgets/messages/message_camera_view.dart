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
  int _cameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  Future? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    availableCameras().then((List<CameraDescription> cameras) {
      _cameras.clear();
      _cameras.addAll(cameras);
      if (cameras.isEmpty) {
        _initializeControllerFuture = Future.error("Failed to initialize camera");
      } else {
        _cameraController = CameraController(cameras.first, ResolutionPreset.high);
        _cameraIndex = 0;
        _initializeControllerFuture = _cameraController.initialize().whenComplete(() => _cameraController.setFlashMode(_flashMode));
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _cameraController.setFlashMode(FlashMode.off).whenComplete(() => _cameraController.dispose());
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
            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(child: CameraPreview(_cameraController)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: _cameras.isEmpty ? null : () async {
                            setState(() {
                              _cameraIndex = (_cameraIndex+1) % _cameras.length;
                            });
                            _cameraController.setDescription(_cameras[_cameraIndex]);
                          },
                          iconSize: 32,
                          icon: const Icon(Icons.switch_camera),
                        ),
                        const SizedBox(width: 64, height: 72,),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (Widget child, Animation<double> animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: RotationTransition(
                                  turns: Tween<double>(begin: 0.6, end: 1).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: switch (_flashMode) {
                            FlashMode.off =>
                                IconButton(
                                  key: const ValueKey("button-flash-off"),
                                  iconSize: 32,
                                  onPressed: () async {
                                    _flashMode = FlashMode.auto;
                                    await _cameraController.setFlashMode(_flashMode);
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.flash_off),
                                ),
                            FlashMode.auto =>
                                IconButton(
                                  key: const ValueKey("button-flash-auto"),
                                  iconSize: 32,
                                  onPressed: () async {
                                    _flashMode = FlashMode.always;
                                    await _cameraController.setFlashMode(_flashMode);
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.flash_auto),
                                ),
                            FlashMode.always =>
                                IconButton(
                                  key: const ValueKey("button-flash-always"),
                                  iconSize: 32,
                                  onPressed: () async {
                                    _flashMode = FlashMode.torch;
                                    await _cameraController.setFlashMode(_flashMode);
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.flash_on),
                                ),
                            FlashMode.torch =>
                                IconButton(
                                  key: const ValueKey("button-flash-torch"),
                                  iconSize: 32,
                                  onPressed: () async {
                                    _flashMode = FlashMode.off;
                                    await _cameraController.setFlashMode(_flashMode);
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.flashlight_on),
                                ),
                          },
                        ),
                      ],
                    )
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .surface,
                      borderRadius: BorderRadius.circular(64),
                    ),
                    margin: const EdgeInsets.all(16),
                    child: IconButton(
                      onPressed: () async {
                        final sMsgr = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);
                        try {
                          await _initializeControllerFuture;
                          final image = await _cameraController.takePicture();
                          nav.pop(File(image.path));
                        } catch (e) {
                          sMsgr.showSnackBar(SnackBar(content: Text("Failed to capture image: $e")));
                        }
                      },
                      style: IconButton.styleFrom(
                        foregroundColor: Theme
                            .of(context)
                            .colorScheme
                            .primary,
                      ),
                      icon: const Icon(Icons.camera),
                      iconSize: 64,
                    ),
                  ),
                ),
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
