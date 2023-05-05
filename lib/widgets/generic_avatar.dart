import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class GenericAvatar extends StatelessWidget {
  const GenericAvatar({this.imageUri="", super.key, this.placeholderIcon=Icons.person, this.radius});

  final String imageUri;
  final IconData placeholderIcon;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return imageUri.isEmpty ? CircleAvatar(
      radius: radius,
      backgroundColor: Colors.transparent,
      child: Icon(placeholderIcon),
    ) : CachedNetworkImage(
      imageBuilder: (context, imageProvider) {
        return CircleAvatar(
          foregroundImage: imageProvider,
          backgroundColor: Colors.transparent,
          radius: radius,
        );
      },
      imageUrl: imageUri,
      placeholder: (context, url) {
        return CircleAvatar(
          backgroundColor: Colors.white54,
          radius: radius,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(color: Colors.black38, strokeWidth: 2),
          ),
        );
      },
      errorWidget: (context, error, what) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.transparent,
        child: Icon(placeholderIcon),
      ),
    );
  }

}