import 'package:flutter/material.dart';

class GenericAvatar extends StatelessWidget {
  const GenericAvatar({this.imageUri = "", super.key, this.placeholderIcon = Icons.person, this.radius, this.foregroundColor});

  final String imageUri;
  final IconData placeholderIcon;
  final double? radius;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final placeholder = CircleAvatar(
      key: const ValueKey("avatar-placeholder"),
      radius: radius,
      foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.onSecondaryContainer,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      child: Icon(
        placeholderIcon,
        color: foregroundColor,
      ),
    );
    return imageUri.isEmpty
        ? placeholder
        : ClipRRect(
            borderRadius: BorderRadiusGeometry.all(Radius.circular(64)),
            child: Image.network(
              imageUri,
              width: 40,
              height: 40,
              cacheHeight: 40,
              cacheWidth: 40,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: frame == null
                    ? placeholder
                    : CircleAvatar(
                        key: const ValueKey("avatar-loaded"),
                        radius: radius,
                        foregroundColor: Colors.transparent,
                        backgroundColor: Colors.transparent,
                        child: child,
                      ),
              ),
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
          );
  }
}
