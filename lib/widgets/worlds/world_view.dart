import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/models/records/record.dart';
import 'package:recon/widgets/formatted_text.dart';
import 'package:recon/widgets/panorama.dart';
import 'package:recon/widgets/settings_page.dart';
import 'package:share_plus/share_plus.dart';

class WorldView extends StatefulWidget {
  const WorldView({required this.world, super.key});

  final Record world;

  @override
  State<WorldView> createState() => _WorldViewState();
}

class _WorldViewState extends State<WorldView> {
  final _dateFormat = DateFormat("yyyy/MM/dd HH:mm:ss");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_outlined,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: FormattedText(
          widget.world.formattedName,
          maxLines: 1,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share("resrec:///${widget.world.ownerId}/${widget.world.id}");
            },
          ),
        ],
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        children: <Widget>[
          SizedBox(
            height: 192,
            child: CachedNetworkImage(
              imageUrl: Aux.resdbToHttp(widget.world.thumbnailUri),
              imageBuilder: (context, image) {
                return Material(
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: const Text("Session Preview"),
                            ),
                            body: Center(
                              child: Panorama(
                                sensitivity: 2,
                                minZoom: 0.5,
                                zoom: 0.5,
                                child: Image(image: image),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        SizedBox.expand(
                          child: Image(
                            image: image,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Icon(Icons.panorama_photosphere),
                          ),
                        ),
                      ],
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
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListSectionHeader(
                  leadingText: "Description:",
                  showLine: false,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8),
                  child: widget.world.formattedDescription?.isEmpty ?? true
                      ? Text("No description", style: Theme.of(context).textTheme.labelLarge)
                      : FormattedText(
                          widget.world.formattedDescription!,
                          style: Theme.of(context).textTheme.labelLarge?.apply(fontStyle: FontStyle.italic),
                        ),
                ),
                const ListSectionHeader(
                  leadingText: "Tags:",
                  showLine: false,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                  child: Text(
                    widget.world.tags.isEmpty ? "None" : widget.world.tags.join(", "),
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
                        "Created at: ",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        _dateFormat.format(widget.world.creationTime),
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
                        "Last modified at: ",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        _dateFormat.format(widget.world.lastModificationTime),
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
                        "Visits: ",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        widget.world.visits.toString(),
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
                        "Rating: ",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        widget.world.rating.toString(),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
