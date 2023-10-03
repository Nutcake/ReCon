import 'dart:developer';

import 'package:recon/apis/github_api.dart';
import 'package:recon/client_holder.dart';
import 'package:recon/clients/api_client.dart';
import 'package:recon/clients/inventory_client.dart';
import 'package:recon/clients/messaging_client.dart';
import 'package:recon/clients/session_client.dart';
import 'package:recon/clients/settings_client.dart';
import 'package:recon/models/sem_ver.dart';
import 'package:recon/widgets/homepage.dart';
import 'package:recon/widgets/login_screen.dart';
import 'package:recon/widgets/update_notifier.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'models/authentication_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterDownloader.initialize(
    debug: kDebugMode,
  );

  await Hive.initFlutter();

  final dateFormat = DateFormat.Hms();
  Logger.root.onRecord.listen(
      (event) => log("${dateFormat.format(event.time)}: ${event.message}", name: event.loggerName, time: event.time));

  final settingsClient = SettingsClient();
  await settingsClient.loadSettings();
  final newSettings =
      settingsClient.currentSettings.copyWith(machineId: settingsClient.currentSettings.machineId.valueOrDefault);
  await settingsClient.changeSettings(newSettings); // Save generated machineId to disk

  AuthenticationData cachedAuth = AuthenticationData.unauthenticated();
  try {
    cachedAuth = await ApiClient.tryCachedLogin();
  } catch (_) {}

  runApp(ReCon(settingsClient: settingsClient, cachedAuthentication: cachedAuth));
}

class ReCon extends StatefulWidget {
  const ReCon({required this.settingsClient, required this.cachedAuthentication, super.key});

  final SettingsClient settingsClient;
  final AuthenticationData cachedAuthentication;

  @override
  State<ReCon> createState() => _ReConState();
}

class _ReConState extends State<ReCon> {
  final Typography _typography = Typography.material2021(platform: TargetPlatform.android);
  late AuthenticationData _authData = widget.cachedAuthentication;
  bool _checkedForUpdate = false;

  void showUpdateDialogOnFirstBuild(BuildContext context) {
    final navigator = Navigator.of(context);
    final settings = ClientHolder.of(context).settingsClient;
    if (_checkedForUpdate) return;
    _checkedForUpdate = true;
    GithubApi.getLatestTagName().then((remoteVer) async {
      final currentVer = (await PackageInfo.fromPlatform()).version;
      SemVer currentSem;
      SemVer remoteSem;
      SemVer lastDismissedSem;

      try {
        currentSem = SemVer.fromString(currentVer);
      } catch (_) {
        currentSem = SemVer.zero();
      }

      try {
        lastDismissedSem = SemVer.fromString(settings.currentSettings.lastDismissedVersion.valueOrDefault);
      } catch (_) {
        lastDismissedSem = SemVer.zero();
      }

      try {
        remoteSem = SemVer.fromString(remoteVer);
      } catch (_) {
        return;
      }

      if (remoteSem <= lastDismissedSem && lastDismissedSem.isNotZero) {
        return;
      }

      if (remoteSem > currentSem && navigator.overlay?.context != null && context.mounted) {
        showDialog(
          context: navigator.overlay!.context,
          builder: (context) {
            return UpdateNotifier(
              remoteVersion: remoteSem,
              localVersion: currentSem,
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Phoenix(
      child: Builder(builder: (context) {
        return ClientHolder(
          settingsClient: widget.settingsClient,
          authenticationData: _authData,
          onLogout: () {
            setState(() {
              _authData = AuthenticationData.unauthenticated();
            });
            Phoenix.rebirth(context);
          },
          child: DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) => MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'ReCon',
              theme: ThemeData(
                useMaterial3: true,
                textTheme: _typography.black,
                colorScheme:
                    lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.purple, brightness: Brightness.light),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                textTheme: _typography.white,
                colorScheme: darkDynamic ?? ColorScheme.fromSeed(seedColor: Colors.purple, brightness: Brightness.dark),
              ),
              themeMode: ThemeMode.values[widget.settingsClient.currentSettings.themeMode.valueOrDefault],
              home: Builder(
                // Builder is necessary here since we need a context which has access to the ClientHolder
                builder: (context) {
                  showUpdateDialogOnFirstBuild(context);
                  final clientHolder = ClientHolder.of(context);
                  return _authData.isAuthenticated
                      ? MultiProvider(
                          providers: [
                            ChangeNotifierProvider(
                              create: (context) => MessagingClient(
                                apiClient: clientHolder.apiClient,
                                notificationClient: clientHolder.notificationClient,
                              ),
                            ),
                            ChangeNotifierProvider(
                              create: (context) => SessionClient(
                                apiClient: clientHolder.apiClient,
                                settingsClient: clientHolder.settingsClient,
                              ),
                            ),
                            ChangeNotifierProvider(
                              create: (context) => InventoryClient(
                                apiClient: clientHolder.apiClient,
                              ),
                            )
                          ],
                          child: const Home(),
                        )
                      : LoginScreen(
                          onLoginSuccessful: (AuthenticationData authData) async {
                            if (authData.isAuthenticated) {
                              setState(() {
                                _authData = authData;
                              });
                            }
                          },
                        );
                },
              ),
            ),
          ),
        );
      }),
    );
  }
}
