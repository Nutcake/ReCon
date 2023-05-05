import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/models/personal_profile.dart';
import 'package:contacts_plus_plus/widgets/generic_avatar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyProfileDialog extends StatelessWidget {
  const MyProfileDialog({required this.profile, super.key});

  final PersonalProfile profile;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    DateFormat dateFormat = DateFormat.yMd();
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.username, style: tt.titleLarge),
                    Text(profile.email, style: tt.labelMedium?.copyWith(color: Colors.white54),)
                  ],
                ),
                GenericAvatar(imageUri: Aux.neosDbToHttp(profile.userProfile.iconUrl), radius: 24,)
              ],
            ),
            const SizedBox(height: 16,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("User ID: ", style: tt.labelLarge,), Text(profile.id)],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("2FA: ", style: tt.labelLarge,), Text(profile.twoFactor ? "Enabled" : "Disabled")],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("Patreon Supporter: ", style: tt.labelLarge,), Text(profile.isPatreonSupporter ? "Yes" : "No")],
            ),
            if (profile.publicBanExpiration?.isAfter(DateTime.now()) ?? false)
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text("Ban Expiration: ", style: tt.labelLarge,),
                Text(dateFormat.format(profile.publicBanExpiration!))],
            ),
            StorageIndicator(usedBytes: profile.usedBytes, maxBytes: profile.maxBytes,),
          ],
        ),
      ),
    );
  }
}

class StorageIndicator extends StatelessWidget {
  const StorageIndicator({required this.usedBytes, required this.maxBytes, super.key});

  final int usedBytes;
  final int maxBytes;

  @override
  Widget build(BuildContext context) {
    final value = usedBytes/maxBytes;
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Storage:", style: Theme.of(context).textTheme.titleMedium),
              Text("${(usedBytes * 1e-9).toStringAsFixed(2)}/${(maxBytes * 1e-9).toStringAsFixed(2)} GiB"),
            ],
          ),
          const SizedBox(height: 8,),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 12,
              color: value > 0.95 ? Theme.of(context).colorScheme.error : null,
              value: value,
            ),
          )
        ],
      ),
    );
  }
}