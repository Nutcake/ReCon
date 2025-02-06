import 'dart:io';

import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/clients/api_client.dart';
import 'package:recon/models/message.dart';

class AudioCacheClient {
  final Future<Directory> _directoryFuture = getTemporaryDirectory();
  final bool _isDarwin = Platform.isMacOS || Platform.isIOS;

  Future<File> cachedNetworkAudioFile(AudioClipContent clip) async {
    final directory = await _directoryFuture;
    final fileName = basenameWithoutExtension(clip.assetUri);
    final file = File("${directory.path}/$fileName.ogg");
    if (!file.existsSync()) {
      await file.create(recursive: true);
      final response = await http.get(Uri.parse(Aux.resdbToHttp(clip.assetUri)));
      ApiClient.checkResponseCode(response);
      await file.writeAsBytes(response.bodyBytes);
    }
    if (_isDarwin) {
      final wavFile = File("${directory.path}/$fileName.wav");
      final wavFileExists = wavFile.existsSync();
      if (wavFileExists && wavFile.lengthSync() == 0) {
        await wavFile.delete();
      }
      if (!wavFileExists) {
        await wavFile.create(recursive: true);
        await FFmpegKit.executeAsync("-y -acodec libvorbis -i ${file.path} -acodec pcm_s16le ${wavFile.path}");
      }
      return wavFile;
    }
    return file;
  }
}
