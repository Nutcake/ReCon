
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SettingsAppBar extends StatelessWidget {
  const SettingsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('settings.title').tr(),
    );
  }
}
