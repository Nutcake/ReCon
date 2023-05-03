
import 'package:contacts_plus_plus/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

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
                            await ClientHolder.of(context).client.logout(context);
                          },
                          child: const Text("Yes"),
                        ),
                      ],
                    ),
              );
            },
          )
        ],
      ),
    );
  }
}