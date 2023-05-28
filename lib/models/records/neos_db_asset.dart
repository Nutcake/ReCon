import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class NeosDBAsset {
  final String hash;
  final int bytes;

  const NeosDBAsset({required this.hash, required this.bytes});

  factory NeosDBAsset.fromMap(Map map) {
    return NeosDBAsset(hash: map["hash"] ?? "", bytes: map["bytes"] ?? -1);
  }

  factory NeosDBAsset.fromData(Uint8List data) {
    final digest = sha256.convert(data);
    return NeosDBAsset(hash: digest.toString().replaceAll("-", "").toLowerCase(), bytes: data.length);
  }

  Map toMap() {
    return {
      "hash": hash,
      "bytes": bytes,
    };
  }
}