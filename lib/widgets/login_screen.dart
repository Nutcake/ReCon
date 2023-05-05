import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/models/authentication_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:contacts_plus_plus/client_holder.dart';

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
  late final Future<AuthenticationData> _cachedLoginFuture = ApiClient.tryCachedLogin().then((value) async {
    if (value.isAuthenticated) {
      await loginSuccessful(value);
    }
    return value;
  });
  late final FocusNode _passwordFocusNode;

  bool _isLoading = false;
  String _error = "";

  double get _errorOpacity => _error.isEmpty ? 0.0 : 1.0;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.cachedUsername ?? "";
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
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
          password: _passwordController.text
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
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s));
      setState(() {
        _error = "Login unsuccessful: $e.";
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
                    await settingsClient.changeSettings(settingsClient.currentSettings.copyWith(notificationsDenied: true));
                  },
                  child: const Text("No"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final requestResult = await notificationManager.resolvePlatformSpecificImplementation<
                        AndroidFlutterLocalNotificationsPlugin>()
                        ?.requestPermission();
                    await settingsClient.changeSettings(settingsClient.currentSettings.copyWith(notificationsDenied: requestResult == null ? false : !requestResult));
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
      appBar: AppBar(
        title: const Text("Contacts++"),
      ),
      body: FutureBuilder(
        future: _cachedLoginFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData || snapshot.hasError) {
            final authData = snapshot.data;
            if (authData?.isAuthenticated ?? false) {
              return const SizedBox.shrink();
            }
            return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text("Sign In", style: Theme
                    .of(context)
                    .textTheme
                    .headlineMedium),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
                child: TextField(
                  autofocus: true,
                  controller: _usernameController,
                  onEditingComplete: () => _passwordFocusNode.requestFocus(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                ),
              ),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                TextButton.icon(
                  onPressed: submit,
                  icon: const Icon(Icons.login),
                  label: const Text("Login"),
                ),
              AnimatedOpacity(
                opacity: _errorOpacity,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
                  child: Text(_error, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.red)),
                ),
              )
            ],
          );
          }
          return const LinearProgressIndicator();
        }
      ),
    );
  }

}