import 'package:contacts_plus_plus/models/asset/record.dart';

class NeosPath {
  final String name;
  final NeosPath? parent;
  final List<NeosPath> children;
  final Record? record;

  const NeosPath({required this.name, required this.parent, required this.children, required this.record});

  String get absolute {
    if (parent == null) return name;
    return "${parent!.absolute}\\$name";
  }
}