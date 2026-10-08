import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
                              title: const Text('worlds.preview').tr(),
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
                ListSectionHeader(
                  leadingText: 'worlds.description'.tr(),
                  showLine: false,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8),
                  child: widget.world.formattedDescription.isEmpty
                      ? Text('worlds.noDescription', style: Theme.of(context).textTheme.labelLarge).tr()
                      : FormattedText(
                          widget.world.formattedDescription,
                          style: Theme.of(context).textTheme.labelLarge?.apply(fontStyle: FontStyle.italic),
                        ),
                ),
                ListSectionHeader(
                  leadingText: 'worlds.tags'.tr(),
                  showLine: false,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                  child: Text(
                    widget.world.tags.isEmpty ? 'worlds.noTags'.tr() : widget.world.tags.join(", "),
                    style: Theme.of(context).textTheme.labelMedium,
                    textAlign: TextAlign.start,
                    softWrap: true,
                  ),
                ),
                ListSectionHeader(
                  leadingText: 'worlds.details'.tr(),
                  showLine: false,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'worlds.createdAt'.tr(),
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
                        'worlds.lastModified'.tr(),
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
                        'worlds.visits'.tr(),
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
                        'worlds.rating'.tr(),
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
