import 'package:cached_network_image/cached_network_image.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/models/session.dart';
import 'package:contacts_plus_plus/widgets/formatted_text.dart';
import 'package:contacts_plus_plus/widgets/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class SessionView extends StatelessWidget {
  const SessionView({required this.session, super.key});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
        slivers: [
          SliverAppBar(
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_outlined,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            pinned: true,
            snap: false,
            floating: false,
            expandedHeight: 192,
            surfaceTintColor: Theme.of(context).colorScheme.surfaceVariant,
            centerTitle: true,
            title: FormattedText(
              session.formattedName,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Row(
                children: [
                  Expanded(
                      child: Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.black,
                  )),
                ],
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: CachedNetworkImage(
                imageUrl: Aux.neosDbToHttp(session.thumbnail),
                imageBuilder: (context, image) {
                  return InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoView(
                            minScale: PhotoViewComputedScale.contained,
                            imageProvider: image,
                            heroAttributes: PhotoViewHeroAttributes(tag: session.id),
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: session.id,
                      child: Image(
                        image: image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image,
                  size: 64,
                ),
                placeholder: (context, uri) => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8),
                    child: session.formattedDescription.isEmpty
                        ? Text("No description", style: Theme.of(context).textTheme.labelLarge)
                        : FormattedText(
                            session.formattedDescription,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                  ),
                  const ListSectionHeader(
                    leadingText: "Tags:",
                    showLine: false,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                    child: Text(
                      session.tags.isEmpty ? "None" : session.tags.join(", "),
                      style: Theme.of(context).textTheme.labelMedium,
                      textAlign: TextAlign.start,
                      softWrap: true,
                    ),
                  ),
                  const ListSectionHeader(
                    leadingText: "Details:",
                    showLine: false,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Access: ",
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          session.accessLevel.toReadableString(),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Headless: ",
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          session.headlessHost ? "Yes" : "No",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  ListSectionHeader(
                    leadingText: "Users",
                    trailingText:
                        "${session.sessionUsers.length.toString().padLeft(2, "0")}/${session.maxUsers.toString().padLeft(2, "0")}",
                    showLine: false,
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final user = session.sessionUsers[index % session.sessionUsers.length];
                return ListTile(
                  dense: true,
                  title: Text(
                    user.username,
                    textAlign: TextAlign.start,
                  ),
                  subtitle: Text(
                    user.isPresent ? "Active" : "Inactive",
                    textAlign: TextAlign.start,
                  ),
                );
              },
              childCount: session.sessionUsers.length,
            ),
          )
        ],
      ),
    );
  }
}
