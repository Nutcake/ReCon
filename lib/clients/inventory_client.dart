import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:recon/apis/record_api.dart';
import 'package:recon/clients/api_client.dart';
import 'package:recon/clients/settings_client.dart';
import 'package:recon/models/inventory/membership.dart';
import 'package:recon/models/inventory/resonite_directory.dart';
import 'package:recon/models/records/record.dart';
import 'package:recon/models/records/record_version.dart';

enum SortMode {
  name,
  date,
  resonite;

  int sortFunction(Record a, Record b, {bool reverse = false}) {
    final func = switch (this) {
      SortMode.name => (Record x, Record y) => x.formattedName.toString().toLowerCase().compareTo(y.formattedName.toString().toLowerCase()),
      SortMode.date => (Record x, Record y) => x.creationTime.compareTo(y.creationTime),
      SortMode.resonite => (Record x, Record y) {
        if (x.isItem && !y.isItem) return 1;
        if (!x.isItem && y.isItem) return -1;
        return x.isItem ? x.creationTime.compareTo(y.creationTime) : x.name.toLowerCase().compareTo(y.name.toLowerCase());
      },
    };
    if (reverse) {
      return func(b, a);
    }
    return func(a, b);
  }

  static const Map<SortMode, IconData> _iconsMap = {
    SortMode.name: Icons.sort_by_alpha,
    SortMode.date: Icons.access_time_outlined,
    SortMode.resonite: Icons.star_border_purple500_sharp,
  };

  IconData get icon => _iconsMap[this] ?? Icons.question_mark;
}

class InventoryClient extends ChangeNotifier {
  final ApiClient apiClient;
  final SettingsClient settingsClient;
  final Map<String, Record> _selectedRecords = {};
  List<Membership>? memberships;

  Future<ResoniteDirectory>? _currentDirectory;
  SortMode _sortMode = SortMode.resonite;
  bool _sortReverse = false;
  Membership? _selectedGroup;

  InventoryClient({required this.apiClient, required this.settingsClient}) {
    RecordApi.getMemberships(apiClient).then((value) {
      memberships = value;
      notifyListeners();
    });
  }

  SortMode get sortMode => _sortMode;

  bool get sortReverse => _sortReverse;

  Membership? get selectedGroup => _selectedGroup;

  set sortMode(SortMode mode) {
    if (_sortMode != mode) {
      _sortMode = mode;
      _ensureDirectorySorted();
      notifyListeners();
    }
  }

  set sortReverse(bool reverse) {
    if (_sortReverse != reverse) {
      _sortReverse = reverse;
      _ensureDirectorySorted();
      notifyListeners();
    }
  }

  set selectedGroup(Membership group) {
    _selectedGroup = group;
    loadInventoryRoot();
    notifyListeners();
  }

  List<Record> get selectedRecords => _selectedRecords.values.toList();

  Future<ResoniteDirectory>? get directoryFuture => _currentDirectory;

  Future<void> saveRecord(Record record, Record Function(Record current) modify) async {
    final current = await RecordApi.getRecord(apiClient, ownerId: record.ownerId, recordId: record.id, includeDeleted: true);
    if (current.isDeleted) return;

    final changed = modify(current);
    final toSave = changed.copyWith(
      lastModificationTime: DateTime.now().toUtc(),
      version: RecordVersion(
        globalVersion: current.version.globalVersion,
        localVersion: current.version.localVersion + 1,
        lastModifyingUserId: apiClient.userId,
        lastModifyingMachineId: settingsClient.currentSettings.machineId.valueOrDefault,
      ),
    );
    await RecordApi.upsertRecord(apiClient, record: toSave);
  }

  bool canWrite(String ownerId) {
    if (ownerId.isEmpty) return false;
    if (ownerId == "G-Resonite") return false;
    if (ownerId == apiClient.userId) return true;
    return (memberships ?? []).any((m) => m.groupId == ownerId);
  }

  Future<void> setPublicRecursively(Record dirRecord, bool isPublic) async {
    if (dirRecord.recordType == RecordType.link || !canWrite(dirRecord.ownerId)) {
      return;
    }
    if (dirRecord.isPublic != isPublic) {
      await saveRecord(dirRecord, (current) => current.copyWith(isPublic: isPublic));
    }
    final children = await RecordApi.getRecordsAt(apiClient, ownerId: dirRecord.ownerId, path: "${dirRecord.path}\\${dirRecord.name}");
    for (final child in children) {
      if (child.recordType == RecordType.directory) {
        await setPublicRecursively(child, isPublic);
      } else if (child.recordType != RecordType.link && child.isPublic != isPublic) {
        await saveRecord(child, (current) => current.copyWith(isPublic: isPublic));
      }
    }
  }

  void _ensureDirectorySorted() {
    _currentDirectory = _currentDirectory?.then((value) {
      value.children.sort((a, b) => _sortMode.sortFunction(a.record, b.record, reverse: _sortReverse));
      return value;
    });
  }

  bool get isAnyRecordSelected => _selectedRecords.isNotEmpty;

  bool isRecordSelected(Record record) => _selectedRecords.containsKey(record.id);

  int get selectedRecordCount => _selectedRecords.length;

  bool get onlyFilesSelected => _selectedRecords.values.every((element) => element.recordType != RecordType.link && element.recordType != RecordType.directory);

  void clearSelectedRecords() {
    _selectedRecords.clear();
    notifyListeners();
  }

  Future<void> deleteSelectedRecords() async {
    for (final record in _selectedRecords.values) {
      await RecordApi.deleteRecord(apiClient, ownerId: record.ownerId, recordId: record.id);
    }
    _selectedRecords.clear();
    unawaited(reloadCurrentDirectory());
  }

  void toggleRecordSelected(Record record) {
    if (_selectedRecords.containsKey(record.id)) {
      _selectedRecords.remove(record.id);
    } else {
      _selectedRecords[record.id] = record;
    }
    notifyListeners();
  }

  Future<List<Record>> _getDirectory(Record record) async {
    final List<Record> records;
    if (record.recordType == RecordType.link) {
      final linkRecord = await RecordApi.getRecordByUri(apiClient, resrecUri: record.assetUri);
      records = await RecordApi.getRecordsAt(apiClient, path: "${linkRecord.path}\\${linkRecord.name}", ownerId: linkRecord.ownerId);
    } else {
      records = await RecordApi.getRecordsAt(apiClient, path: "${record.path}${record.isRoot ? "" : "\\${record.name}"}", ownerId: record.ownerId);
    }
    return records;
  }

  void loadInventoryRoot() {
    final rootRecord = _selectedGroup != null
        ? Record.inventoryRoot(ownerId: _selectedGroup!.groupId).copyWith(name: _selectedGroup!.groupName)
        : Record.inventoryRoot(ownerId: apiClient.userId);

    final rootFuture = _getDirectory(rootRecord).then((records) {
      final rootDir = ResoniteDirectory(record: rootRecord, children: []);
      rootDir.children.addAll(records.map((e) => ResoniteDirectory.fromRecord(record: e, parent: rootDir)).toList());
      return rootDir;
    });
    _currentDirectory = rootFuture;
    _ensureDirectorySorted();
  }

  void forceNotify() => notifyListeners();

  Future<void> reloadCurrentDirectory() async {
    final dir = await _currentDirectory;

    if (dir == null) {
      throw "Failed to reload: No directory loaded.";
    }

    _currentDirectory = _getDirectory(dir.record)
        .then((records) {
          final children = records.map((record) => ResoniteDirectory.fromRecord(record: record, parent: dir)).toList();
          final newDir = ResoniteDirectory(record: dir.record, children: children, parent: dir.parent);

          final parentIdx = dir.parent?.children.indexOf(dir) ?? -1;
          if (parentIdx != -1) {
            dir.parent?.children[parentIdx] = newDir;
          }
          return newDir;
        })
        .onError((error, stackTrace) {
          return dir;
        });
    _ensureDirectorySorted();
    notifyListeners();
  }

  Future<void> navigateTo(Record record) async {
    final dir = await _currentDirectory;

    if (dir == null) {
      throw "Failed to open: No directory loaded.";
    }

    if (record.recordType != RecordType.directory && record.recordType != RecordType.link) {
      throw "Failed to open: Record is not a directory.";
    }

    final childDir = dir.findChildByRecord(record);
    if (childDir == null) {
      throw "Failed to open: Record is not a child of current directory.";
    }

    Object? caughtError;

    if (childDir.isLoaded) {
      _currentDirectory = Future.value(childDir);
    } else {
      _currentDirectory = _getDirectory(record)
          .then((records) {
            childDir.children.clear();
            childDir.children.addAll(records.map((record) => ResoniteDirectory.fromRecord(record: record, parent: childDir)));
            return childDir;
          })
          .onError((error, stackTrace) {
            caughtError = error;
            return dir;
          });
    }
    _ensureDirectorySorted();
    notifyListeners();
    await _currentDirectory;
    // Dirty hack to throw the error here instead of letting the FutureBuilder handle it. This means we can keep showing
    // the previous directory while also being able to display the error as a snackbar.
    if (caughtError != null) {
      throw caughtError!;
    }
  }

  Future<void> navigateUp({int times = 1}) async {
    if (times == 0) return;

    var dir = await _currentDirectory;
    if (dir == null) {
      throw "Failed to navigate up: No directory loaded.";
    }
    if (dir.record.isRoot) {
      throw "Failed navigate up: Already at root";
    }

    for (var i = 0; i < times; i++) {
      dir = dir?.parent;
    }
    _selectedRecords.clear();
    _currentDirectory = Future.value(dir);
    _ensureDirectorySorted();
    notifyListeners();
  }
}
