import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class CryptoHelper {
  static final Random _random = Random.secure();

  static List<int> randomBytes(int length) => List<int>.generate(length, (i) => _random.nextInt(256));

  static String cryptoToken([int length = 128]) => base64UrlEncode(randomBytes(length)).replaceAll("/", "_");

  static String idHash(String id) => sha256.convert(utf8.encode(id)).toString().replaceAll("-", "").toUpperCase();
}
