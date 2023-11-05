import 'package:collection/collection.dart';
import 'package:recon/models/records/record.dart';

class ResoniteDirectory {
  static const rootName = "Inventory";

  final Record record;
  final ResoniteDirectory? parent;
  final List<ResoniteDirectory> children;

  ResoniteDirectory({required this.record, this.parent, required this.children});

  factory ResoniteDirectory.fromRecord({required Record record, ResoniteDirectory? parent}) {
    return ResoniteDirectory(record: record, parent: parent, children: []);
  }

  @override
  String toString() {
    return record.formattedName.toString();
  }

  bool get isRoot => record.isRoot;

  String get absolutePath => "${parent?.absolutePath ?? ""}/${(record.name)}";

  List<String> get absolutePathSegments => (parent?.absolutePathSegments ?? []) + [record.formattedName.toString()];

  bool containsRecord(Record record) => children.where((element) => element.record.id == record.id).isNotEmpty;

  List<Record> get records => children.map((e) => e.record).toList();

  bool get isLoaded => children.isNotEmpty;

  ResoniteDirectory? findChildByRecord(Record record) => children.firstWhereOrNull((element) => element.record.id == record.id);
}
