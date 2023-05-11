import 'package:cached_network_image/cached_network_image.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/models/session.dart';
import 'package:contacts_plus_plus/string_formatter.dart';
import 'package:contacts_plus_plus/widgets/messages/messages_session_header.dart';
import 'package:flutter/material.dart';

class LargeSessionTile extends StatelessWidget {
  const LargeSessionTile({required this.session, super.key});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final formattedName = StringFormatter.tryFormat(session.name, baseStyle: const TextStyle(color: Colors.white));
    return InkWell(
      onTap: (){
        showDialog(context: context, builder: (context) => SessionPopup(session: session));
      },
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              Aux.neosDbToHttp(session.thumbnail),
            ),
            fit: BoxFit.cover,
          )
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    color: Theme.of(context).colorScheme.background.withAlpha(200),
                    child: formattedName != null ? RichText(text: formattedName, maxLines: 4, overflow: TextOverflow.ellipsis)
                        : Text(session.name.overflow, maxLines: 4, overflow: TextOverflow.ellipsis,),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              color: Theme.of(context).colorScheme.background.withAlpha(200),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${session.sessionUsers.length}/${session.maxUsers}"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

}