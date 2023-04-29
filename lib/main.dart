import 'package:contacts_plus/widgets/home_screen.dart';
import 'package:contacts_plus/widgets/login_screen.dart';
import 'package:flutter/material.dart';
import 'api_client.dart';
import 'models/authentication_data.dart';

void main() {
  runApp(const ContactsPlus());
}

class ContactsPlus extends StatelessWidget {
  const ContactsPlus({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contacts+',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange, brightness: Brightness.dark)
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AuthenticationData _authenticationData = AuthenticationData.unauthenticated();

  @override
  Widget build(BuildContext context) {
    if (_authenticationData.isAuthenticated) {
      return AuthenticatedClient(
        authenticationData: _authenticationData,
        child: const HomeScreen(),
      );
    } else {
      return LoginScreen(
        onLoginSuccessful: (AuthenticationData authData) {
          if (authData.isAuthenticated) {
            setState(() {
              _authenticationData = authData;
            });
          }
        },
      );
    }
  }
}

class AuthenticatedClient extends InheritedWidget {
  final ApiClient client;

  AuthenticatedClient({super.key, required AuthenticationData authenticationData, required super.child})
      : client = ApiClient(authenticationData: authenticationData);

  static AuthenticatedClient? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthenticatedClient>();
  }

  static AuthenticatedClient of(BuildContext context) {
    final AuthenticatedClient? result = maybeOf(context);
    assert(result != null, 'No AuthenticatedClient found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant AuthenticatedClient oldWidget) => oldWidget.client != client;
}