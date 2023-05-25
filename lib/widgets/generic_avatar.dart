import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class GenericAvatar extends StatelessWidget {
  const GenericAvatar({this.imageUri="", super.key, this.placeholderIcon=Icons.person, this.radius, this.foregroundColor});

  final String imageUri;
  final IconData placeholderIcon;
  final double? radius;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return imageUri.isEmpty ? CircleAvatar(
      radius: radius,
      foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(placeholderIcon, color: foregroundColor,),
    ) : CachedNetworkImage(
      imageBuilder: (context, imageProvider) {
        return CircleAvatar(
          foregroundImage: imageProvider,
          foregroundColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          radius: radius,
        );
      },
      imageUrl: imageUri,
      placeholder: (context, url) {
        return CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
          radius: radius,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(color: foregroundColor ?? Theme.of(context).colorScheme.onPrimaryContainer, strokeWidth: 2),
          ),
        );
      },
      errorWidget: (context, error, what) => CircleAvatar(
        radius: radius,
        foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(placeholderIcon, color: foregroundColor ?? Theme.of(context).colorScheme.onPrimaryContainer,),
      ),
    );
  }

}