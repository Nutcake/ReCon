import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recon/models/records/search_sort.dart';

class WorldListAppBar extends StatefulWidget {
  const WorldListAppBar({required this.onQueryChanged, super.key});

  final Function({
    required SearchSortParameter sortParameter,
    required SearchSortDirection sortDirection,
    required String needle,
  }) onQueryChanged;

  @override
  State<WorldListAppBar> createState() => _WorldListAppBarState();
}

class _WorldListAppBarState extends State<WorldListAppBar> {
  SearchSortParameter _sortParameter = SearchSortParameter.lastUpdateDate;
  SearchSortDirection _sortDirection = SearchSortDirection.descending;
  String _needle = "";

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Worlds"),
      actions: [
        if (_needle.isEmpty)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final textController = TextEditingController();
              final result = await showDialog<String>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Search for worlds"),
                    content: TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        hintText: "Enter tags",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(textController.text);
                        },
                        child: const Text("Search"),
                      ),
                    ],
                  );
                },
              );
              setState(() {
                _needle = result?.trim() ?? "";
              });
              widget.onQueryChanged(
                sortParameter: _sortParameter,
                sortDirection: _sortDirection,
                needle: _needle,
              );
            },
          )
        else ...[
          Text(_needle),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _needle = "";
              });
            },
          ),
        ],
        PopupMenuButton(
          icon: const Icon(Icons.sort),
          onSelected: (value) {
            setState(() {
              _sortParameter = value;
            });
            widget.onQueryChanged(
              sortParameter: value,
              sortDirection: _sortDirection,
              needle: _needle,
            );
          },
          itemBuilder: (context) => SearchSortParameter.values
              .map(
                (e) => CheckedPopupMenuItem(
                  value: e,
                  checked: e == _sortParameter,
                  child: Text(toBeginningOfSentenceCase(e.toString())),
                ),
              )
              .toList(),
        ),
        PopupMenuButton(
          icon: const Icon(Icons.swap_vert),
          onSelected: (value) {
            setState(() {
              _sortDirection = value;
            });
            widget.onQueryChanged(
              sortParameter: _sortParameter,
              sortDirection: value,
              needle: _needle,
            );
          },
          itemBuilder: (context) => SearchSortDirection.values
              .map(
                (e) => CheckedPopupMenuItem(
                  value: e,
                  checked: e == _sortDirection,
                  child: Text(toBeginningOfSentenceCase(e.toString())),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
