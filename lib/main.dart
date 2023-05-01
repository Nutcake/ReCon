import 'package:contacts_plus/models/message.dart';
import 'package:contacts_plus/neos_hub.dart';
import 'package:contacts_plus/widgets/home_screen.dart';
import 'package:contacts_plus/widgets/login_screen.dart';
import 'package:flutter/material.dart';
import 'api_client.dart';
import 'models/authentication_data.dart';

void main() {
  runApp(const ContactsPlus());
}

class ContactsPlus extends StatefulWidget {
  const ContactsPlus({super.key});

  @override
  State<ContactsPlus> createState() => _ContactsPlusState();
}

class _ContactsPlusState extends State<ContactsPlus> {
  final Typography _typography = Typography.material2021(platform: TargetPlatform.android);
  AuthenticationData _authData = AuthenticationData.unauthenticated();
  final Map<String, MessageCache> _messageCache = {};

  @override
  Widget build(BuildContext context) {
    return HubHolder(
      messageCache: _messageCache,
      authenticationData: _authData,
      child: ClientHolder(
        authenticationData: _authData,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Contacts+',
          theme: ThemeData(
            useMaterial3: true,
            textTheme: _typography.white,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple, brightness: Brightness.dark)
          ),
          home: _authData.isAuthenticated ?
          const HomeScreen() :
          LoginScreen(
            onLoginSuccessful: (AuthenticationData authData) async {
              if (authData.isAuthenticated) {
                setState(() {
                  _authData = authData;
                });
              }
            },
          ),
        ),
      ),
    );
  }
}
