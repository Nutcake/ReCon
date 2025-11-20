import 'dart:developer';
import 'dart:isolate';
import 'dart:ui';

import 'package:background_downloader/background_downloader.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
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

import 'models/authentication_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemStatusBarContrastEnforced: true,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.top]);

  await Hive.initFlutter();

  final dateFormat = DateFormat.Hms();
  Logger.root.onRecord.listen(
    (event) => log("${dateFormat.format(event.time)}: ${event.message}", name: event.loggerName, time: event.time),
  );
  Logger.root.level = Level.WARNING;
  final settingsClient = SettingsClient();
  await settingsClient.loadSettings();
  final newSettings = settingsClient.currentSettings.copyWith(machineId: settingsClient.currentSettings.machineId.valueOrDefault);
  await settingsClient.changeSettings(newSettings); // Save generated machineId to disk

  var cachedAuth = AuthenticationData.unauthenticated();
  try {
    cachedAuth = await ApiClient.tryCachedLogin();
  } catch (_) {
    // Ignore
  }

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
  final Typography _typography = Typography.material2021(platform: defaultTargetPlatform);
  final ReceivePort _port = ReceivePort();
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

      if (remoteSem > currentSem && navigator.overlay?.context != null && mounted) {
        await showDialog(
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
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((data) {
      // Not useful yet? idk...
      // String id = data[0];
      // DownloadTaskStatus status = data[1];
      // int progress = data[2];
    });

    FileDownloader().updates.listen(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  @pragma('vm:entry-point')
  static void downloadCallback(TaskUpdate event) {}

  // Workaround for issue https://github.com/material-foundation/flutter-packages/issues/582
  // Dynamic color schemes do not generate new additional surface container colours so we have to do it manually
  (ColorScheme light, ColorScheme dark) _generateDynamicColourSchemes(
    ColorScheme lightDynamic,
    ColorScheme darkDynamic,
  ) {
    final lightBase = ColorScheme.fromSeed(seedColor: lightDynamic.primary);
    final darkBase = ColorScheme.fromSeed(seedColor: darkDynamic.primary, brightness: Brightness.dark);

    final lightAdditionalColours = _extractAdditionalColours(lightBase);
    final darkAdditionalColours = _extractAdditionalColours(darkBase);

    final lightScheme = _insertAdditionalColours(lightBase, lightAdditionalColours);
    final darkScheme = _insertAdditionalColours(darkBase, darkAdditionalColours);

    return (lightScheme.harmonized(), darkScheme.harmonized());
  }

  List<Color> _extractAdditionalColours(ColorScheme scheme) => [
        scheme.surface,
        scheme.surfaceDim,
        scheme.surfaceBright,
        scheme.surfaceContainerLowest,
        scheme.surfaceContainerLow,
        scheme.surfaceContainer,
        scheme.surfaceContainerHigh,
        scheme.surfaceContainerHighest,
      ];

  ColorScheme _insertAdditionalColours(ColorScheme scheme, List<Color> additionalColours) => scheme.copyWith(
        surface: additionalColours[0],
        surfaceDim: additionalColours[1],
        surfaceBright: additionalColours[2],
        surfaceContainerLowest: additionalColours[3],
        surfaceContainerLow: additionalColours[4],
        surfaceContainer: additionalColours[5],
        surfaceContainerHigh: additionalColours[6],
        surfaceContainerHighest: additionalColours[7],
      );

  @override
  Widget build(BuildContext context) {
    return Phoenix(
      child: Builder(
        builder: (context) {
          final apiClient = ApiClient(authenticationData: _authData)
            ..addLogoutListener(
              () {
                setState(() {
                  _authData = AuthenticationData.unauthenticated();
                });
                Phoenix.rebirth(context);
              },
            );
          return ClientHolder(
            settingsClient: widget.settingsClient,
            apiClient: apiClient,
            child: DynamicColorBuilder(
              builder: (lightDynamic, darkDynamic) {
                if (lightDynamic != null && darkDynamic != null) {
                  (lightDynamic, darkDynamic) = _generateDynamicColourSchemes(lightDynamic, darkDynamic);
                }
                return MaterialApp(
                  debugShowCheckedModeBanner: true,
                  title: 'ReCon',
                  theme: ThemeData(
                    useMaterial3: true,
                    textTheme: _typography.black,
                    colorScheme: lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.purple, brightness: Brightness.light),
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
                                    settingsClient: clientHolder.settingsClient,
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
                                ),
                              ],
                              child: AnnotatedRegion<SystemUiOverlayStyle>(
                                value: SystemUiOverlayStyle(
                                  statusBarColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                ),
                                child: const Home(),
                              ),
                            )
                          : LoginScreen(
                              onLoginSuccessful: (authData) async {
                                if (authData.isAuthenticated) {
                                  setState(() {
                                    _authData = authData;
                                  });
                                }
                              },
                            );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
