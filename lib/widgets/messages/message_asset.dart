import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/models/message.dart';
import 'package:recon/models/photo_asset.dart';
import 'package:recon/string_formatter.dart';
import 'package:recon/widgets/formatted_text.dart';
import 'package:recon/widgets/messages/message_state_indicator.dart';

class MessageAsset extends StatelessWidget {
  const MessageAsset({required this.message, this.foregroundColor, super.key});

  final Message message;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final content = jsonDecode(message.content) as Map<String, dynamic>;
    final formattedName = FormatNode.fromText(content["name"]);
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: [
          SizedBox(
            height: 256,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: Aux.resdbToHttp(content["thumbnailUri"]),
              imageBuilder: (context, image) {
                return InkWell(
                  onTap: () async {
                    PhotoAsset? photoAsset;
                    try {
                      photoAsset = PhotoAsset.fromTags((content["tags"] as List).map((e) => "$e").toList());
                    } catch (_) {}
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoView(
                          minScale: PhotoViewComputedScale.contained,
                          imageProvider: photoAsset == null ? image : CachedNetworkImageProvider(Aux.resdbToHttp(photoAsset.imageUri)),
                          heroAttributes: PhotoViewHeroAttributes(tag: message.id),
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: message.id,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image(
                        image: image,
                        fit: BoxFit.cover,
                      ),
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
          const SizedBox(
            height: 8,
          ),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foregroundColor),
                  ),
                ),
              ),
              MessageStateIndicator(
                message: message,
                foregroundColor: foregroundColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
