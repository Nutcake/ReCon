import 'dart:developer';
import 'dart:io' show Platform;

import 'package:contacts_plus_plus/apis/github_api.dart';
import 'package:contacts_plus_plus/client_holder.dart';
import 'package:contacts_plus_plus/clients/messaging_client.dart';
import 'package:contacts_plus_plus/clients/settings_client.dart';
import 'package:contacts_plus_plus/models/sem_ver.dart';
import 'package:contacts_plus_plus/widgets/friends/friends_list.dart';
import 'package:contacts_plus_plus/widgets/login_screen.dart';
import 'package:contacts_plus_plus/widgets/update_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'models/authentication_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await Workmanager().initialize(
        callbackDispatcher, // The top level function, aka callbackDispatcher
        isInDebugMode: true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
    );
  }

  Logger.root.onRecord.listen((event) => log(event.message, name: event.loggerName, time: event.time));
  final settingsClient = SettingsClient();
  await settingsClient.loadSettings();
  runApp(Phoenix(child: ContactsPlusPlus(settingsClient: settingsClient,)));
}

@pragma('vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) async {
    debugPrint("Native called background task: $task"); //simpleTask will be emitted here.
    if (task == MessagingClient.taskName) {
      final unreads = MessagingClient.backgroundCheckUnreads(inputData);
    }
    return Future.value(true);
  });
}

class ContactsPlusPlus extends StatefulWidget {
  const ContactsPlusPlus({required this.settingsClient, super.key});

  final SettingsClient settingsClient;

  @override
  State<ContactsPlusPlus> createState() => _ContactsPlusPlusState();
}

class _ContactsPlusPlusState extends State<ContactsPlusPlus> {
  final Typography _typography = Typography.material2021(platform: TargetPlatform.android);
  AuthenticationData _authData = AuthenticationData.unauthenticated();
  bool _checkedForUpdate = false;

  void showUpdateDialogOnFirstBuild(BuildContext context) {
    final navigator = Navigator.of(context);
    final settings = ClientHolder
        .of(context)
        .settingsClient;
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

      if (remoteSem > currentSem && navigator.overlay?.context != null) {
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
    return ClientHolder(
      settingsClient: widget.settingsClient,
      authenticationData: _authData,
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Contacts++',
          theme: ThemeData(
              useMaterial3: true,
              textTheme: _typography.white,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple, brightness: Brightness.dark)
          ),
          home: Builder( // Builder is necessary here since we need a context which has access to the ClientHolder
            builder: (context) {
              showUpdateDialogOnFirstBuild(context);
              final clientHolder = ClientHolder.of(context);
              return _authData.isAuthenticated ?
              ChangeNotifierProvider( // This doesn't need to be a proxy provider since the arguments should never change during it's lifetime.
                create: (context) =>
                    MessagingClient(
                      apiClient: clientHolder.apiClient,
                      notificationClient: clientHolder.notificationClient,
                    ),
                child: const FriendsList(),
              ) :
              LoginScreen(
                onLoginSuccessful: (AuthenticationData authData) async {
                  if (authData.isAuthenticated) {
                    setState(() {
                      _authData = authData;
                    });
                  }
                },
              );
            }
          )
      ),
    );
  }
}
