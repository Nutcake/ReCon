import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:recon/client_holder.dart';
import 'package:recon/models/sem_ver.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateNotifier extends StatelessWidget {
  const UpdateNotifier({required this.remoteVersion, required this.localVersion, super.key});

  final SemVer remoteVersion;
  final SemVer localVersion;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('update.title'.tr(), style: Theme
          .of(context)
          .textTheme
          .titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('update.description'.tr()),
          const SizedBox(height: 8,),
          Row(
            children: [
              Text('update.localVersion'.tr(args: [localVersion.toString()])),
            ],
          ),
          Row(
            children: [
              Text('update.remoteVersion'.tr(args: [remoteVersion.toString()])),
            ],
          ),
          const SizedBox(height: 24,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () {
                  launchUrl(Uri.parse("https://github.com/Nutcake/ReCon/releases/latest"),
                    mode: LaunchMode.externalApplication,
                  );
                },
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    foregroundColor: Theme
                        .of(context)
                        .colorScheme
                        .onSecondary,
                    backgroundColor: Theme
                        .of(context)
                        .colorScheme
                        .secondary
                ),
                icon: const Icon(Icons.download),
                label: Text('update.openDownload'.tr()),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final sClient = ClientHolder
                .of(context)
                .settingsClient;
            sClient.changeSettings(sClient.currentSettings.copyWith(lastDismissedVersion: remoteVersion.toString()));
            Navigator.of(context).pop();
          },
          child: Text('update.dismiss'.tr()),
        ),
      ],
    );
  }
}