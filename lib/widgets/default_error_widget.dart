import 'package:flutter/material.dart';

class DefaultErrorWidget extends StatelessWidget {
  const DefaultErrorWidget({this.title, this.message, this.onRetry, this.iconOverride, super.key});

  final String? title;
  final String? message;
  final void Function()? onRetry;
  final IconData? iconOverride;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(64),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(iconOverride ?? Icons.warning, size: 32,),
            const SizedBox(height: 16,),
            Text(title ?? "Something went wrong: ",
              textAlign: TextAlign.center,
              style: Theme
                .of(context)
                .textTheme
                .titleMedium,),
            if (message != null) Padding(
              padding: const EdgeInsets.all(16),
              child: Text(message ?? "",
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) TextButton.icon(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

}