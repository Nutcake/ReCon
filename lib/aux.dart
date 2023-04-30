import 'package:contacts_plus/config.dart';
import 'package:path/path.dart' as p;

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