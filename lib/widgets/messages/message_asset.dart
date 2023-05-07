
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/client_holder.dart';
import 'package:contacts_plus_plus/models/photo_asset.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:contacts_plus_plus/widgets/messages/message_state_indicator.dart';
import 'package:flutter/material.dart';
import 'package:full_screen_image/full_screen_image.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

class MessageAsset extends StatelessWidget {
  MessageAsset({required this.message, super.key});

  final Message message;
  final DateFormat _dateFormat = DateFormat.Hm();


  @override
  Widget build(BuildContext context) {
    final content = jsonDecode(message.content);
    PhotoAsset? photoAsset;
    try {
      photoAsset = PhotoAsset.fromTags((content["tags"] as List).map((e) => "$e").toList());
    } catch (_) {}

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
            placeholder: (context, uri) => const CircularProgressIndicator(),
          ),
          const SizedBox(height: 8,),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(child: Text("${content["name"]}", maxLines: null, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  _dateFormat.format(message.sendTime),
                  style: Theme
                      .of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.white54),
                ),
              ),
              if (message.senderId == ClientHolder
                  .of(context)
                  .apiClient
                  .userId) Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: MessageStateIndicator(messageState: message.state),
              ),
            ],
          ),
        ],
      ),
    );
  }
}