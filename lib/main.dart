import 'dart:developer';

import 'package:contacts_plus_plus/widgets/home_screen.dart';
import 'package:contacts_plus_plus/widgets/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:logging/logging.dart';
import 'api_client.dart';
import 'models/authentication_data.dart';

void main() {
  Logger.root.onRecord.listen((event) => log(event.message, name: event.loggerName));
  runApp(Phoenix(child: const ContactsPlusPlus()));
}

class ContactsPlusPlus extends StatefulWidget {
  const ContactsPlusPlus({super.key});

  @override
  State<ContactsPlusPlus> createState() => _ContactsPlusPlusState();
}

class _ContactsPlusPlusState extends State<ContactsPlusPlus> {
  final Typography _typography = Typography.material2021(platform: TargetPlatform.android);
  AuthenticationData _authData = AuthenticationData.unauthenticated();

  @override
  Widget build(BuildContext context) {
    return ClientHolder(
      authenticationData: _authData,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Contacts++',
        theme: ThemeData(
            useMaterial3: true,
            textTheme: _typography.white,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple, brightness: Brightness.dark)
        ),
        home: _authData.isAuthenticated ?
        const FriendsList() :
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
    );
  }
}
