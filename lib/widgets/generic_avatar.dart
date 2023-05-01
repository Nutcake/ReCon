import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class GenericAvatar extends StatelessWidget {
  const GenericAvatar({this.imageUri="", super.key, this.placeholderIcon=Icons.person});

  final String imageUri;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    return imageUri.isEmpty ? CircleAvatar(
      backgroundColor: Colors.transparent,
      child: Icon(placeholderIcon),
    ) : CachedNetworkImage(
      imageBuilder: (context, imageProvider) {
        return CircleAvatar(
          foregroundImage: imageProvider,
          backgroundColor: Colors.transparent,
        );
      },
      imageUrl: imageUri,
      placeholder: (context, url) {
        return const CircleAvatar(
            backgroundColor: Colors.white54,
            child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(color: Colors.black38, strokeWidth: 2),
        ));
      },
      errorWidget: (context, error, what) => CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(placeholderIcon),
      ),
    );
  }

}