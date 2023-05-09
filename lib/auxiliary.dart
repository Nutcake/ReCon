import 'dart:convert';
import 'dart:typed_data';

import 'package:contacts_plus_plus/config.dart';
import 'package:html/parser.dart' as htmlparser;
import 'package:uuid/uuid.dart';

enum NeosDBEndpoint
{
  def,
  blob,
  cdn,
  videoCDN,
}

class Aux {
  static String neosDbToHttp(String? neosdb) {
    if (neosdb == null || neosdb.isEmpty) return "";
    if (neosdb.startsWith("http")) return neosdb;
    final fullUri = neosdb.replaceFirst("neosdb:///", Config.neosCdnUrl);
    final lastPeriodIndex = fullUri.lastIndexOf(".");
    if (lastPeriodIndex != -1 && fullUri.length - lastPeriodIndex < 8) {
      // I feel like 8 is a good maximum for file extension length? Can neosdb Uris even come without file extensions?
      return fullUri.substring(0, lastPeriodIndex);
    }
    return fullUri;
  }

  static String toURLBase64(Uint8List data) => base64.encode(data)
      .replaceAll("+", "-")
      .replaceAll("/", "_")
      .replaceAll("=", "");

  static String generateMachineId() => Aux.toURLBase64((const Uuid().v1obj().toBytes())).toLowerCase();
}


extension Unique<E, Id> on List<E> {
  List<E> unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = <Id>{};
    var list = inplace ? this : List<E>.from(this);
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}

extension Strip on String {
  String stripHtml() {
    final document = htmlparser.parse(this);
    return htmlparser.parse(document.body?.text).documentElement?.text ?? "";
  }

  // This won't be accurate since userIds can't contain certain characters that usernames can
  // but it's fine for just having a name to display
  String stripUid() => startsWith("U-") ? substring(2) : this;
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