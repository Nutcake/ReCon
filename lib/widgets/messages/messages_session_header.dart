import 'package:cached_network_image/cached_network_image.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/models/session.dart';
import 'package:contacts_plus_plus/widgets/formatted_text.dart';
import 'package:contacts_plus_plus/widgets/generic_avatar.dart';
import 'package:contacts_plus_plus/widgets/sessions/session_view.dart';
import 'package:flutter/material.dart';

class SessionPopup extends StatelessWidget {
  const SessionPopup({required this.session, super.key});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final ScrollController userListScrollController = ScrollController();
    final thumbnailUri = Aux.neosDbToHttp(session.thumbnail);
    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        FormattedText(session.formattedName, style: Theme.of(context).textTheme.titleMedium),
                        session.formattedDescription.isEmpty
                            ? const Text("No description")
                            : FormattedText(session.formattedDescription, style: Theme.of(context).textTheme.labelMedium),
                        Text("Tags: ${session.tags.isEmpty ? "None" : session.tags.join(", ")}",
                          style: Theme.of(context).textTheme.labelMedium,
                          softWrap: true,
                        ),
                        Text("Access: ${session.accessLevel.toReadableString()}", style: Theme.of(context).textTheme.labelMedium),
                        Text("Users: ${session.sessionUsers.length}", style: Theme.of(context).textTheme.labelMedium),
                        Text("Maximum users: ${session.maxUsers}", style: Theme.of(context).textTheme.labelMedium),
                        Text("Headless: ${session.headlessHost ? "Yes" : "No"}", style: Theme.of(context).textTheme.labelMedium),
                      ],
                    ),
                  ),
                  if (session.sessionUsers.isNotEmpty) Expanded(
                    child: Scrollbar(
                      trackVisibility: true,
                      controller: userListScrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: userListScrollController,
                        shrinkWrap: true,
                        itemCount: session.sessionUsers.length,
                        itemBuilder: (context, index) {
                          final user = session.sessionUsers[index];
                          return ListTile(
                            dense: true,
                            title: Text(user.username, textAlign: TextAlign.end,),
                            subtitle: Text(user.isPresent ? "Active" : "Inactive", textAlign: TextAlign.end,),
                          );
                        },
                      ),
                    ),
                  ) else const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_remove_alt_1_rounded),
                          Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("No one is currently playing.", textAlign: TextAlign.center,),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child:  CachedNetworkImage(
                  imageUrl: thumbnailUri,
                  placeholder: (context, url) {
                    return const CircularProgressIndicator();
                  },
                  errorWidget: (context, error, what) => const Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.no_photography),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("Failed to load Image"),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SessionTile extends StatelessWidget {
  const SessionTile({required this.session, super.key});
  final Session session;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => SessionView(session: session)));
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GenericAvatar(imageUri: Aux.neosDbToHttp(session.thumbnail), placeholderIcon: Icons.no_photography),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormattedText(session.formattedName),
                Text("${session.sessionUsers.length.toString().padLeft(2, "0")}/${session.maxUsers.toString().padLeft(2, "0")} active users")
              ],
            ),
          )
        ],
      ),
    );
  }
}