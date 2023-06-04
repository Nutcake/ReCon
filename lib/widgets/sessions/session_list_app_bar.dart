import 'package:contacts_plus_plus/clients/session_client.dart';
import 'package:contacts_plus_plus/widgets/sessions/session_filter_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SessionListAppBar extends StatefulWidget {
  const SessionListAppBar({super.key});

  @override
  State<SessionListAppBar> createState() => _SessionListAppBarState();
}

class _SessionListAppBarState extends State<SessionListAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Sessions"),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.black,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: IconButton(
            onPressed: () async {
              final sessionClient = Provider.of<SessionClient>(context, listen: false);
              await showDialog(
                context: context,
                builder: (context) => Provider.value(
                  value: sessionClient,
                  child: SessionFilterDialog(
                    lastFilter: sessionClient.filterSettings,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.filter_alt_outlined),
          ),
        )
      ],
    );
  }
}
