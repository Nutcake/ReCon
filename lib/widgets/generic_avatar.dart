import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GenericAvatar extends StatelessWidget {
  const GenericAvatar({this.imageUri="", super.key});

  final String imageUri;

  @override
  Widget build(BuildContext context) {
    return imageUri.isEmpty ? const CircleAvatar(
      backgroundColor: Colors.transparent,
      child: Icon(Icons.person),
    ) : CachedNetworkImage(
      imageBuilder: (context, imageProvider) {
        return CircleAvatar(
          foregroundImage: imageProvider,
          backgroundColor: Colors.transparent,
        );
      },
      imageUrl: imageUri,
      placeholder: (context, url) {
        return const CircleAvatar(backgroundColor: Colors.white54,);
      },
      errorWidget: (context, error, what) => const CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(Icons.person),
      ),
    );
  }

}