import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsAppBar extends StatelessWidget {
  const SettingsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Settings"),
    );
  }
}
