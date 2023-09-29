import 'package:cached_network_image/cached_network_image.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/models/records/record.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../formatted_text.dart';

class ObjectInventoryTile extends StatelessWidget {
  ObjectInventoryTile({required this.record, this.onTap, this.onLongPress, this.selected=false, super.key});

  final bool selected;
  final Record record;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final DateFormat _dateFormat = DateFormat.yMd();

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
        onLongPress: onLongPress,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Hero(
                  tag: record.id,
                  child: Center(
                    child: CachedNetworkImage(
                      height: double.infinity,
                      width: double.infinity,
                      imageUrl: Aux.resdbToHttp(record.thumbnailUri),
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                        ),
                      ),
                      placeholder: (context, uri) =>
                      const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FormattedText(
                            record.formattedName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.white54,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          _dateFormat.format(record.creationTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
