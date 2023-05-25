import 'package:contacts_plus_plus/config.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:html/parser.dart' as htmlparser;

enum NeosDBEndpoint
{
  def,
  blob,
  cdn,
  videoCDN,
}

extension NeosStringExtensions on Uri {
  static String dbSignature(Uri neosdb) => neosdb.pathSegments.length < 2 ? "" : p.basenameWithoutExtension(neosdb.pathSegments[1]);
  static String? neosDBQuery(Uri neosdb) => neosdb.query.trim().isEmpty ? null : neosdb.query.substring(1);
  static bool isLegacyNeosDB(Uri uri) => !(uri.scheme != "neosdb") && uri.pathSegments.length >= 2 && p.basenameWithoutExtension(uri.pathSegments[1]).length < 30;

  Uri neosDBToHTTP(NeosDBEndpoint endpoint) {
    var signature = dbSignature(this);
    var query = neosDBQuery(this);
    if (query != null) {
      signature = "$signature/$query";
    }
    if (isLegacyNeosDB(this)) {
      return Uri.parse(Config.legacyCloudUrl + signature);
    }
    String base;
    switch (endpoint) {
      case NeosDBEndpoint.blob:
        base = Config.blobStorageUrl;
        break;
      case NeosDBEndpoint.cdn:
        base = Config.neosCdnUrl;
        break;
      case NeosDBEndpoint.videoCDN:
        base = Config.videoStorageUrl;
        break;
      case NeosDBEndpoint.def:
        base = Config.neosAssetsUrl;
    }

    return Uri.parse(base + signature);
  }
}

class Aux {
  static String neosDbToHttp(String? neosdb) {
    if (neosdb == null || neosdb.isEmpty) return "";
    if (neosdb.startsWith("http")) return neosdb;
    final filename = p.basenameWithoutExtension(neosdb);
    return "${Config.neosCdnUrl}$filename";
  }
}

extension Unique<E, Id> on List<E> {
  List<E> unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = <Id>{};
    var list = inplace ? this : List<E>.from(this);
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
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
    final r = 255 - red;
    final g = 255 - green;
    final b = 255 - blue;

    return Color.fromARGB((opacity * 255).round(), r, g, b);
  }
}