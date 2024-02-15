import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recon/apis/user_api.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/client_holder.dart';
import 'package:recon/models/personal_profile.dart';
import 'package:recon/widgets/default_error_widget.dart';
import 'package:recon/widgets/generic_avatar.dart';

class MyProfileDialog extends StatefulWidget {
  const MyProfileDialog({super.key});

  @override
  State<MyProfileDialog> createState() => _MyProfileDialogState();
}

class _MyProfileDialogState extends State<MyProfileDialog> {
  ClientHolder? _clientHolder;
  Future<PersonalProfile>? _personalProfileFuture;
  Future<StorageQuota>? _storageQuotaFuture;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final clientHolder = ClientHolder.of(context);
    if (_clientHolder != clientHolder) {
      _clientHolder = clientHolder;
      final apiClient = _clientHolder!.apiClient;
      _personalProfileFuture = UserApi.getPersonalProfile(apiClient);
      _storageQuotaFuture = UserApi.getStorageQuota(apiClient);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    DateFormat dateFormat = DateFormat.yMd();
    return Dialog(
      child: FutureBuilder(
        future: _personalProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final profile = snapshot.data as PersonalProfile;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GenericAvatar(
                        imageUri: Aux.resdbToHttp(profile.userProfile.iconUrl),
                        radius: 32,
                      ),
                      Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile.username, style: tt.titleLarge),
                              Text(
                                profile.accountType.label,
                                style: tt.labelMedium?.copyWith(color: profile.accountType.color),
                              ),
                            ],
                          )),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "User ID: ",
                        style: tt.labelLarge,
                      ),
                      Text(profile.id)
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Email: ",
                        style: tt.labelLarge,
                      ),
                      Text(profile.email)
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Patreon Supporter: ",
                        style: tt.labelLarge,
                      ),
                      Text(profile.isPatreonSupporter ? "Yes" : "No")
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "2FA: ",
                        style: tt.labelLarge,
                      ),
                      Text(profile.twoFactor ? "Enabled" : "Disabled")
                    ],
                  ),
                  if (profile.publicBanExpiration?.isAfter(DateTime.now()) ?? false)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Ban Expiration: ",
                          style: tt.labelLarge,
                        ),
                        Text(dateFormat.format(profile.publicBanExpiration!))
                      ],
                    ),
                  FutureBuilder(
                      future: _storageQuotaFuture,
                      builder: (context, snapshot) {
                        final storage = snapshot.data;
                        return StorageIndicator(
                          usedBytes: storage?.usedBytes ?? 0,
                          maxBytes: storage?.fullQuotaBytes ?? 1,
                        );
                      }),
                  const SizedBox(
                    height: 12,
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultErrorWidget(
                  message: snapshot.error.toString(),
                  onRetry: () {
                    setState(() {
                      _personalProfileFuture = UserApi.getPersonalProfile(ClientHolder.of(context).apiClient);
                    });
                  },
                ),
              ],
            );
          } else {
            return const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 96, horizontal: 64),
                  child: CircularProgressIndicator(),
                ),
              ],
            );
          }
        },
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
    final value = usedBytes / maxBytes;
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Storage:", style: Theme.of(context).textTheme.titleMedium),
              Text(// Displayed in GiB instead of GB for consistency with Resonite
                  "${(usedBytes * 9.3132257461548e-10).toStringAsFixed(2)}/${(maxBytes * 9.3132257461548e-10).toStringAsFixed(2)} GB"),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
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
