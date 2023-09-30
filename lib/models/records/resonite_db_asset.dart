import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class ResoniteDBAsset {
  final String hash;
  final int bytes;

  const ResoniteDBAsset({required this.hash, required this.bytes});

  factory ResoniteDBAsset.fromMap(Map map) {
    return ResoniteDBAsset(hash: map["hash"] ?? "", bytes: map["bytes"] ?? -1);
  }

  factory ResoniteDBAsset.fromData(Uint8List data) {
    final digest = sha256.convert(data);
    return ResoniteDBAsset(hash: digest.toString().replaceAll("-", "").toLowerCase(), bytes: data.length);
  }

  Map toMap() {
    return {
      "hash": hash,
      "bytes": bytes,
    };
  }
}