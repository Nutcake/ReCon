import 'package:flutter/material.dart';

class InventoryBrowserAppBar extends StatelessWidget {
  const InventoryBrowserAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Inventory"),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.black,
        ),
      ),
    );
  }
}