
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/models/photo_asset.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:contacts_plus_plus/string_formatter.dart';
import 'package:contacts_plus_plus/widgets/formatted_text.dart';
import 'package:contacts_plus_plus/widgets/messages/message_state_indicator.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class MessageAsset extends StatelessWidget {
  const MessageAsset({required this.message, this.foregroundColor, super.key});

  final Message message;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final content = jsonDecode(message.content);
    PhotoAsset? photoAsset;
    try {
      photoAsset = PhotoAsset.fromTags((content["tags"] as List).map((e) => "$e").toList());
    } catch (_) {}
    final formattedName = FormatNode.fromText(content["name"]);
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: Aux.neosDbToHttp(content["thumbnailUri"]),
            imageBuilder: (context, image) {
              return InkWell(
                onTap: () async {
                  await Navigator.push(
                    context, MaterialPageRoute(builder: (context) =>
                      PhotoView(
                        minScale: PhotoViewComputedScale.contained,
                        imageProvider: photoAsset == null
                            ? image
                            : CachedNetworkImageProvider(Aux.neosDbToHttp(photoAsset.imageUri)),
                        heroAttributes: PhotoViewHeroAttributes(tag: message.id),
                      ),
                  ),);
                },
                child: Hero(
                  tag: message.id,
                  child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image(image: image,)),
                ),
              );
            },
            errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, size: 128,),
            placeholder: (context, uri) => const CircularProgressIndicator(),
          ),
          const SizedBox(height: 8,),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FormattedText(
                    formattedName,
                    maxLines: null,
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: foregroundColor),
                  ),
                ),
              ),
             MessageStateIndicator(message: message, foregroundColor: foregroundColor,),
            ],
          ),
        ],
      ),
    );
  }
}