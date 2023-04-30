import 'package:contacts_plus/models/message.dart';
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
    return ClientHolder(
      authenticationData: _authData,
      child: MessageCacheHolder(
        messageCache: _messageCache,
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
            onLoginSuccessful: (AuthenticationData authData) {
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

class ClientHolder extends InheritedWidget {
  final ApiClient client;

  ClientHolder({super.key, required AuthenticationData authenticationData, required super.child})
      : client = ApiClient(authenticationData: authenticationData);

  static ClientHolder? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ClientHolder>();
  }

  static ClientHolder of(BuildContext context) {
    final ClientHolder? result = maybeOf(context);
    assert(result != null, 'No AuthenticatedClient found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant ClientHolder oldWidget) => oldWidget.client != client;
}


class MessageCacheHolder extends InheritedWidget {
  const MessageCacheHolder({super.key, required Map<String, MessageCache> messageCache, required super.child})
      : _messageCache = messageCache;

  final Map<String, MessageCache> _messageCache;

  MessageCache? getCache(String index) => _messageCache[index];

  void setCache(String index, List<Message> messages) {
    _messageCache[index]?.invalidate();
    _messageCache[index] = MessageCache(messages: messages);
  }

  static MessageCacheHolder? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MessageCacheHolder>();
  }

  static MessageCacheHolder of(BuildContext context) {
    final MessageCacheHolder? result = maybeOf(context);
    assert(result != null, 'No MessageCacheHolder found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

}