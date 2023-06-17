import 'package:contacts_plus_plus/models/records/record.dart';
import 'package:contacts_plus_plus/widgets/formatted_text.dart';
import 'package:flutter/material.dart';

class PathInventoryTile extends StatelessWidget {
  const PathInventoryTile({required this.record, this.selected = false, this.onTap, this.onLongPress, super.key});

  final Record record;
  final Function()? onTap;
  final Function()? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide(
          color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
          width: 1,
        ),
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        alignment: Alignment.centerLeft,
      ),
      onLongPress: onLongPress,
      onPressed: onTap,
      icon: record.recordType == RecordType.directory ? const Icon(Icons.folder) : const Icon(Icons.link),
      label: FormattedText(
        record.formattedName,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
