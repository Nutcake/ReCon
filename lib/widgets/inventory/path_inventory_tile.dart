import 'package:contacts_plus_plus/models/records/record.dart';
import 'package:contacts_plus_plus/widgets/formatted_text.dart';
import 'package:flutter/material.dart';

class PathInventoryTile extends StatelessWidget {
  const PathInventoryTile({required this.record, required this.onPressed, super.key});

  final Record record;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        alignment: Alignment.centerLeft,
      ),
      onPressed: onPressed,
      icon: record.recordType == RecordType.directory ? const Icon(Icons.folder) : const Icon(Icons.link),
      label: FormattedText(
        record.formattedName,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
