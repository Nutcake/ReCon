import 'package:flutter/material.dart';
import 'package:recon/models/records/record.dart';
import 'package:recon/widgets/formatted_text.dart';

class PathInventoryTile extends StatelessWidget {
  const PathInventoryTile({required this.record, this.selected = false, this.onTap, this.onLongPress, super.key});

  final Record record;
  final Function()? onTap;
  final Function()? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Row(
            children: [
              if (record.recordType == RecordType.directory) const Icon(Icons.folder) else const Icon(Icons.link),
              const SizedBox(
                width: 4,
              ),
              Expanded(
                child: FormattedText(
                  record.formattedName,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
