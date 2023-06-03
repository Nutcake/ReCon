import 'package:flutter/material.dart';

class SessionListAppBar extends StatelessWidget {
  const SessionListAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Sessions"),
      actions: [
        IconButton(
          onPressed: () {

          },
          icon: const Icon(Icons.filter_alt_outlined),
        )
      ],
    );
  }
}
