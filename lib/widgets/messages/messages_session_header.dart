import 'package:cached_network_image/cached_network_image.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/models/session.dart';
import 'package:contacts_plus_plus/string_formatter.dart';
import 'package:contacts_plus_plus/widgets/generic_avatar.dart';
import 'package:flutter/material.dart';

class SessionPopup extends StatelessWidget {
  const SessionPopup({required this.session, super.key});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final ScrollController userListScrollController = ScrollController();
    final thumbnailUri = Aux.neosDbToHttp(session.thumbnail);
    final formattedTitle = StringFormatter.tryFormat(session.name);
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
                        formattedTitle == null ?
                        Text(session.name, style: Theme.of(context).textTheme.titleMedium) : RichText(text: formattedTitle),
                        Text(session.description.isEmpty ? "No description." : session.description, style: Theme.of(context).textTheme.labelMedium),
                        Text("Tags: ${session.tags.isEmpty ? "None" : session.tags.join(", ")}",
                          style: Theme.of(context).textTheme.labelMedium,
                          softWrap: true,
                        ),
                        Text("Access: ${session.accessLevel.toReadableString()}"),
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
                  ) else Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
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
                  errorWidget: (context, error, what) => Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
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
    final formattedTitle = StringFormatter.tryFormat(session.name);
    return TextButton(
      onPressed: () {
        showDialog(context: context, builder: (context) => SessionPopup(session: session));
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
                formattedTitle == null ? Text(session.name) : RichText(text: formattedTitle),
                Text("${session.sessionUsers.length}/${session.maxUsers} active users")
              ],
            ),
          )
        ],
      ),
    );
  }
}