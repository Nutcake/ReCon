import 'package:collection/collection.dart';
import 'package:contacts_plus_plus/stack.dart';
import 'package:contacts_plus_plus/models/records/record.dart';


class NeosPath {
  static const _root = "Inventory";
  final Stack<NeosDirectory> _pathStack = Stack<NeosDirectory>();

  String get absolute {
    if (_pathStack.isEmpty) return _root;
    var path = _pathStack.entries.join("\\");
    return "$_root\\$path";
  }

  NeosDirectory pop() => _pathStack.pop();

  void push(NeosDirectory directory) => _pathStack.push(directory);

  bool get isRoot => _pathStack.isEmpty;

  /*
  NeosDirectory get current => _pathStack.peek ?? NeosDirectory(name: _root);

  void populateCurrent(String target, Iterable<Record> records) {
    var currentDir = _pathStack.peek;
    if (currentDir?.name != target) return;
    currentDir?.records.addAll(records);
  }
   */
}

class NeosDirectory {
  static const rootName = "Inventory";

  final Record record;
  final NeosDirectory? parent;
  final List<NeosDirectory> children;

  NeosDirectory({required this.record, this.parent, required this.children});

  factory NeosDirectory.fromRecord({required Record record, NeosDirectory? parent}) {
    return NeosDirectory(record: record, parent: parent, children: []);
  }

  @override
  String toString() {
    return record.name;
  }

  bool get isRoot => record.isRoot;

  String get absolutePath => "${parent?.absolutePath ?? ""}/${(record.name)}";

  List<String> get absolutePathSegments => (parent?.absolutePathSegments ?? []) + [record.name];

  bool containsRecord(Record record) => children.where((element) => element.record.id == record.id).isNotEmpty;

  List<Record> get records => children.map((e) => e.record).toList();

  bool get isLoaded => children.isNotEmpty;

  NeosDirectory? findChildByRecord(Record record) => children.firstWhereOrNull((element) => element.record.id == record.id);
}
