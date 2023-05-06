import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateNotifier extends StatelessWidget {
  const UpdateNotifier({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Update Available", style: Theme
          .of(context)
          .textTheme
          .titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("There is a new version available for download!"),
          const SizedBox(height: 24,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () {
                  launchUrl(Uri.parse("https://github.com/Nutcake/contacts-plus-plus/releases/latest"),
                    mode: LaunchMode.externalApplication,
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  backgroundColor: Theme.of(context).colorScheme.secondary
                ),
                icon: const Icon(Icons.download),
                label: const Text("Get it on Github"),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("I'll do it later."))
      ],
    );
  }
}