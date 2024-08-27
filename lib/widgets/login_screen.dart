import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:recon/client_holder.dart';
import 'package:recon/clients/api_client.dart';
import 'package:recon/models/authentication_data.dart';
import 'package:recon/widgets/translucent_glass.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.onLoginSuccessful, this.cachedUsername, super.key});

  final String? cachedUsername;
  final Function(AuthenticationData)? onLoginSuccessful;

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _totpController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final FocusNode _passwordFocusNode;
  late final FocusNode _totpFocusNode;

  bool _isLoading = false;
  String _error = "";
  bool _needsTotp = false;

  double get _errorOpacity => _error.isEmpty ? 0.0 : 1.0;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.cachedUsername ?? "";
    _passwordFocusNode = FocusNode();
    _totpFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _totpFocusNode.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _error = "Please enter a valid username/password combination.";
      });
      return;
    }
    setState(() {
      _error = "";
      _isLoading = true;
    });
    try {
      final authData = await ApiClient.tryLogin(
        username: _usernameController.text,
        password: _passwordController.text,
        oneTimePad: _totpController.text.isEmpty ? null : _totpController.text,
      );
      if (!authData.isAuthenticated) {
        setState(() {
          _error = "Login unsuccessful: Server sent invalid response.";
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _error = "";
        _isLoading = false;
      });
      await loginSuccessful(authData);
    } catch (e, s) {
      setState(() {
        if (e == ApiClient.totpKey) {
          if (_needsTotp == false) {
            _error = "Please enter your 2FA-Code";
            _totpFocusNode.requestFocus();
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              _scrollController.animateTo(_scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 400), curve: Curves.easeOutCirc);
            });
          } else {
            _error = "The given 2FA code is not valid.";
          }
          _needsTotp = true;
        } else {
          _error = "Login unsuccessful: $e.";
        }
        if (kDebugMode) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: e,
            stack: s,
          ));
        }
        _isLoading = false;
      });
    }
  }

  Future<void> loginSuccessful(AuthenticationData authData) async {
    final settingsClient = ClientHolder.of(context).settingsClient;
    final notificationManager = FlutterLocalNotificationsPlugin();
    if (settingsClient.currentSettings.notificationsDenied.value == null) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("This app needs to ask your permission to send background notifications."),
              content: const Text("Are you okay with that?"),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await settingsClient
                        .changeSettings(settingsClient.currentSettings.copyWith(notificationsDenied: true));
                  },
                  child: const Text("No"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final requestResult = switch (Platform.operatingSystem) {
                      "android" => await notificationManager
                          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
                          ?.requestNotificationsPermission(),
                      "fuschia" => null, // "fuschia" is not supported by flutter_local_notifications
                      "ios" => await notificationManager
                          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
                          ?.requestPermissions(alert: true, badge: true, sound: true),
                      "linux" => null, // don't want to deal with this right now
                      "macos" => await notificationManager
                          .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
                          ?.requestPermissions(alert: true, badge: true, sound: true),
                      "windows" => null, // also don't want to deal with this right now
                      _ => null,
                    };
                    await settingsClient.changeSettings(settingsClient.currentSettings
                        .copyWith(notificationsDenied: requestResult == null ? false : !requestResult));
                  },
                  child: const Text("Yes"),
                )
              ],
            );
          },
        );
      }
    }
    await widget.onLoginSuccessful?.call(authData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: TranslucentGlass(
              border: Border(
                bottom: TranslucentGlass.defaultBorderSide(context),
              ),
              gradient: TranslucentGlass.defaultTopGradient(context),
              child: AppBar(
                backgroundColor: Colors.transparent,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      child: Image.asset(
                        "assets/images/logo.png",
                        width: 28,
                        filterQuality: FilterQuality.medium,
                        isAntiAlias: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text("ReCon")
                  ],
                ),
              ))),
      body: Builder(builder: (context) {
        return ListView(
          controller: _scrollController,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Center(
                child: Text("Sign In", style: Theme.of(context).textTheme.headlineMedium),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
              child: TextField(
                controller: _usernameController,
                onEditingComplete: () => _passwordFocusNode.requestFocus(),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  labelText: 'Username',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
              child: TextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                onEditingComplete: submit,
                obscureText: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(32)),
                  labelText: 'Password',
                ),
              ),
            ),
            if (_needsTotp)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
                child: TextField(
                  controller: _totpController,
                  focusNode: _totpFocusNode,
                  onEditingComplete: submit,
                  obscureText: false,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    labelText: '2FA Code',
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TextButton.icon(
                      onPressed: submit,
                      icon: const Icon(Icons.login),
                      label: const Text("Login"),
                    ),
            ),
            Center(
              child: AnimatedOpacity(
                opacity: _errorOpacity,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
                  child: Text(_error, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.red)),
                ),
              ),
            )
          ],
        );
      }),
    );
  }
}
