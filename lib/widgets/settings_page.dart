import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          ListTile(
            shape: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.secondaryContainer, width: 0.5),
              top: BorderSide(color: Theme.of(context).colorScheme.secondaryContainer, width: 0.5)
            ),
            trailing: const Icon(Icons.logout),
            title: const Text("Sign out"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) =>
                    AlertDialog(
                      title: Text("Are you sure you want to sign out?", style: Theme
                          .of(context)
                          .textTheme
                          .titleLarge,),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("No")),
                        TextButton(
                          onPressed: () async {
                            await ClientHolder.of(context).apiClient.logout(context);
                          },
                          child: const Text("Yes"),
                        ),
                      ],
                    ),
              );
            },
          ),
          ListTile(
            shape: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.secondaryContainer, width: 0.5),
                top: BorderSide(color: Theme.of(context).colorScheme.secondaryContainer, width: 0.5)
            ),
            trailing: const Icon(Icons.info_outline),
            title: const Text("About Contacts++"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationVersion: "0.0.1",
                applicationIcon: InkWell(
                  onTap: () async {
                    if (!await launchUrl(Uri.parse("https://github.com/Nutcake/contacts-plus-plus"), mode: LaunchMode.externalApplication)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to open link.")));
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    constraints: const BoxConstraints(maxWidth: 64),
                    child: Image.asset("assets/images/logo512.png"),
                  ),
                ),
                applicationLegalese: "Created by Nutcake with love <3",
              );
            },
          )
        ],
      ),
    );
  }
}