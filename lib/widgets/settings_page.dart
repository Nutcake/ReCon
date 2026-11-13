import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:recon/client_holder.dart';
import 'package:url_launcher/url_launcher.dart';

const languages = <(String, String, Locale)>[
  ('English', 'English', Locale('en')),
  ('Chinese', '中文', Locale('zh-cn')),
  ('Esperanto', 'Esperanto', Locale('eo')),
  ('French', 'Français', Locale('fr')),
  ('German', 'Deutsch', Locale('de')),
  ('Japanese', '日本語', Locale('ja')),
  ('Korean', '한국어', Locale('ko')),
  ('Russian', 'Русский', Locale('ru')),
  ('Spanish', 'Español', Locale('es')),
  ('Test', 'Test', Locale('af')),
];

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sClient = ClientHolder.of(context).settingsClient;
    return Scaffold(
      appBar: AppBar(
        title: const Text('settings.title').tr(),
      ),
      body: ListView(
        children: [
          ListSectionHeader(leadingText: 'settings.notifications.title'.tr()),
          BooleanSettingsTile(
            title: 'settings.notifications.enabled'.tr(),
            initialState: !sClient.currentSettings.notificationsDenied.valueOrDefault,
            onChanged: (value) async => sClient.changeSettings(sClient.currentSettings.copyWith(notificationsDenied: !value)),
          ),
          ListSectionHeader(leadingText: 'settings.appearance.title'.tr()),
          ListTile(
            trailing: StatefulBuilder(
              builder: (context, setState) {
                return DropdownButton<ThemeMode>(
                  items: ThemeMode.values
                      .map(
                        (mode) => DropdownMenuItem<ThemeMode>(
                          value: mode,
                          child: Text(
                            toBeginningOfSentenceCase(mode.name),
                          ),
                        ),
                      )
                      .toList(),
                  value: ThemeMode.values[sClient.currentSettings.themeMode.valueOrDefault],
                  onChanged: (value) async {
                    final currentSetting = sClient.currentSettings.themeMode.value;
                    if (currentSetting != value?.index) {
                      await sClient.changeSettings(sClient.currentSettings.copyWith(themeMode: value?.index));
                      if (context.mounted) {
                        Phoenix.rebirth(context);
                      }
                    }
                    setState(() {});
                  },
                );
              },
            ),
            title: const Text('settings.appearance.theme').tr(),
          ),
          ListSectionHeader(leadingText: 'settings.system.title'.tr()),
          DropdownButtonFormField<Locale>(
            initialValue: context.locale,
            decoration: InputDecoration(
              labelText: 'settings.system.language'.tr(),
              prefixIcon: Icon(Icons.language),
              border: OutlineInputBorder(),
            ),
            items: [
              for (final language in languages)
                DropdownMenuItem(
                  value: language.$3,
                  child: Text(language.$2),
                ),
            ],
            onChanged: (locale) {
              if (locale != null) {
                context.setLocale(locale);
              }
            },
          ),
          ListTile(
            trailing: const Icon(Icons.info_outline),
            title: const Text('settings.system.about').tr(),
            onTap: () async {
              final version = (await PackageInfo.fromPlatform()).version;
              if (context.mounted) {
                showAboutDialog(
                  context: context,
                  applicationVersion: version,
                  applicationIcon: InkWell(
                    onTap: () async {
                      if (!await launchUrl(
                          Uri.parse("https://github.com/Nutcake/ReCon"),
                          mode: LaunchMode.externalApplication)) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('settings.system.failedToOpenLink'.tr()))
                          );
                        }
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      constraints: const BoxConstraints(maxWidth: 64),
                      child: Image.asset("assets/images/logo512.png"),
                    ),
                  ),
                  applicationLegalese: "Created by Nutcake with love <3",
                );
              }
            },
          ),
          ListTile(
            trailing: const Icon(Icons.logout),
            title: const Text('settings.system.signout').tr(),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'settings.system.signout.confirm'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('general.no').tr()),
                    TextButton(
                      onPressed: () async {
                        await ClientHolder.of(context).apiClient.logout();
                      },
                      child: const Text('general.yes').tr(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ListSectionHeader extends StatelessWidget {
  const ListSectionHeader({required this.leadingText, this.trailingText, this.showLine = true, super.key});

  final String leadingText;
  final String? trailingText;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(leadingText, style: textTheme),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.white12,
              height: showLine ? 1 : 0,
            ),
          ),
          if (trailingText != null)
            Text(
              trailingText!,
              style: textTheme,
            ),
        ],
      ),
    );
  }
}

class BooleanSettingsTile extends StatefulWidget {
  const BooleanSettingsTile({required this.title, required this.initialState, required this.onChanged, super.key});

  final String title;
  final bool initialState;
  final Function(bool) onChanged;

  @override
  State<StatefulWidget> createState() => _BooleanSettingsTileState();
}

class _BooleanSettingsTileState extends State<BooleanSettingsTile> {
  late bool state = widget.initialState;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      trailing: Switch(
        onChanged: (value) async {
          await widget.onChanged(value);
          setState(() {
            state = value;
          });
        },
        value: state,
      ),
      title: Text(widget.title),
      onTap: () async {
        await widget.onChanged(!state);
        setState(() {
          state = !state;
        });
      },
    );
  }
}
