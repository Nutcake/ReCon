import 'package:contacts_plus/widgets/home_screen.dart';
import 'package:contacts_plus/widgets/login_screen.dart';
import 'package:flutter/material.dart';
import 'api_client.dart';
import 'models/authentication_data.dart';

void main() {
  runApp(ContactsPlus());
}

class ContactsPlus extends StatelessWidget {
  ContactsPlus({super.key});
  final Typography _typography = Typography.material2021(platform: TargetPlatform.android);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contacts+',
      theme: ThemeData(
        textTheme: _typography.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple, brightness: Brightness.dark)
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
  final ApiClient _apiClient = ApiClient();

  @override
  Widget build(BuildContext context) {
    if (_apiClient.isAuthenticated) {
      return const HomeScreen();
    } else {
      return LoginScreen(
        onLoginSuccessful: (AuthenticationData authData) {
          if (authData.isAuthenticated) {
            setState(() {
              _apiClient.authenticationData = authData;
            });
          }
        },
      );
    }
  }
}