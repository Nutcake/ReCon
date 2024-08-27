import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:recon/apis/user_api.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/client_holder.dart';
import 'package:recon/color_palette.dart';
import 'package:recon/models/personal_profile.dart';
import 'package:recon/widgets/blend_mask.dart';
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
    final ThemeData theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    DateFormat dateFormat = DateFormat.yMd();

    return Dialog(
      clipBehavior: Clip.antiAlias,
      backgroundColor: colorScheme.background,
      child: FutureBuilder(
        future: _personalProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final profile = snapshot.data as PersonalProfile;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.background.withOpacity(0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GenericAvatar(
                          imageUri: Aux.resdbToHttp(profile.userProfile.iconUrl),
                          radius: 32,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.username, style: textTheme.titleLarge),
                            Text(
                              profile.accountType.label,
                              style: textTheme.labelMedium?.copyWith(color: profile.accountType.color),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Account Info",
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              color: colorScheme.background.withOpacity(0.4),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "User ID",
                                              style: textTheme.titleSmall,
                                            ),
                                            Text(profile.id,
                                                style: textTheme.bodySmall?.copyWith(color: const Color(0xFFE1E1E0)))
                                          ],
                                        ),
                                        IconButton(
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: profile.id));
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                  content: Text("User ID copied to clipboard"),
                                                  behavior: SnackBarBehavior.floating));
                                            },
                                            icon: const Icon(Icons.copy_outlined))
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Email",
                                              style: textTheme.titleSmall,
                                            ),
                                            Text(profile.email,
                                                style: textTheme.bodySmall?.copyWith(color: const Color(0xFFE1E1E0)))
                                          ],
                                        ),
                                        IconButton(
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: profile.email));
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                  content: Text("Email copied to clipboard"),
                                                  behavior: SnackBarBehavior.floating));
                                            },
                                            icon: const Icon(Icons.copy_outlined))
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Patreon Supporter",
                                          style: textTheme.titleSmall,
                                        ),
                                        Text(profile.isPatreonSupporter ? "Yes" : "No",
                                            style: textTheme.bodySmall?.copyWith(color: const Color(0xFFE1E1E0)))
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Two Factor Authentication",
                                          style: textTheme.titleSmall,
                                        ),
                                        Text(profile.twoFactor ? "Enabled" : "Disabled",
                                            style: textTheme.bodySmall?.copyWith(color: const Color(0xFFE1E1E0)))
                                      ],
                                    ),
                                  ])),
                        ),
                      ],
                    ),
                  ),
                  if (profile.publicBanExpiration?.isAfter(DateTime.now()) ?? false)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Ban Expiration: ",
                          style: textTheme.labelLarge,
                        ),
                        Text(dateFormat.format(profile.publicBanExpiration!))
                      ],
                    ),
                  const SizedBox(
                    height: 12,
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
    final ThemeData theme = Theme.of(context);
    final value = usedBytes / maxBytes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Storage", style: theme.textTheme.titleMedium),
          const SizedBox(
            height: 8,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(children: [
              LinearProgressIndicator(
                value: value,
                minHeight: 48,
                color: value >= 0.95 ? palette.hero.red.withOpacity(0.7) : palette.hero.cyan,
                backgroundColor: value >= 0.95 ? palette.hero.red.withOpacity(0.3) : palette.sub.cyan,
              ),
              Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  child: BlendMask(
                    blendMode: BlendMode.srcATop,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "${(value * 100).toStringAsFixed(0)}%",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: palette.neutrals.light, fontWeight: FontWeight.bold),
                        ),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Displayed in GiB instead of GB for consistency with Resonite
                              Text(
                                "${(usedBytes * 9.3132257461548e-10).toStringAsFixed(2)} GB of ${(maxBytes * 9.3132257461548e-10).toStringAsFixed(2)} GB",
                                style: theme.textTheme.bodyMedium?.copyWith(color: palette.neutrals.light),
                              ),
                              Text(
                                "Storage Space Used",
                                style:
                                    theme.textTheme.labelSmall?.copyWith(color: palette.neutrals.light, fontSize: 10),
                              ),
                            ]),
                      ],
                    ),
                  )),
            ]),
          )
        ],
      ),
    );
  }
}
