import 'dart:io';

import 'package:flutter/material.dart';
import 'package:html/parser.dart' as htmlparser;
import 'package:path/path.dart' as p;
import 'package:recon/config.dart';

class Aux {
  static String resdbToHttp(String? resdb) {
    if (resdb == null || resdb.isEmpty) return "";
    if (resdb.startsWith("http")) return resdb;
    final filename = p.basenameWithoutExtension(resdb);
    return "${Config.skyfrostAssetsUrl}/$filename";
  }
}

extension Unique<E, Id> on List<E> {
  List<E> unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = <Id>{};
    final list = inplace ? this : List<E>.from(this)
      ..retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}

extension StringX on String {
  String stripHtml() {
    final document = htmlparser.parse(this);
    return htmlparser.parse(document.body?.text).documentElement?.text ?? "";
  }

  // This won't be accurate since userIds can't contain certain characters that usernames can
  // but it's fine for just having a name to display
  String stripUid() => startsWith("U-") ? substring(2) : this;

  String? get asNullable => isEmpty ? null : this;
}

extension Format on Duration {
  String format() {
    final hh = (inHours).toString().padLeft(2, '0');
    final mm = (inMinutes % 60).toString().padLeft(2, '0');
    final ss = (inSeconds % 60).toString().padLeft(2, '0');
    if (inHours == 0) {
      return "$mm:$ss";
    } else {
      return "$hh:$mm:$ss";
    }
  }
}

extension DateTimeX on DateTime {
  static DateTime epoch = DateTime.fromMillisecondsSinceEpoch(0);
  static DateTime one = DateTime(1);
}

extension ColorX on Color {
  Color invert() {
    final ir = 1.0 - r;
    final ig = 1.0 - g;
    final ib = 1.0 - b;

    return Color.fromARGB((a * 255).round(), (ir * 255).round(), (ig * 255).round(), (ib * 255).round());
  }
}

class EventNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}