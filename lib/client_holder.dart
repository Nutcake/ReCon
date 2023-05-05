
import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/clients/messaging_client.dart';
import 'package:contacts_plus_plus/clients/notification_client.dart';
import 'package:contacts_plus_plus/clients/settings_client.dart';
import 'package:contacts_plus_plus/models/authentication_data.dart';
import 'package:flutter/material.dart';

class ClientHolder extends InheritedWidget {
  final ApiClient apiClient;
  final SettingsClient settingsClient;
  late final MessagingClient messagingClient;
  final NotificationClient notificationClient = NotificationClient();

  ClientHolder({
    super.key,
    required AuthenticationData authenticationData,
    required this.settingsClient,
    required super.child
  }) : apiClient = ApiClient(authenticationData: authenticationData) {
    messagingClient = MessagingClient(apiClient: apiClient, notificationClient: notificationClient);
  }

  static ClientHolder? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ClientHolder>();
  }

  static ClientHolder of(BuildContext context) {
    final ClientHolder? result = maybeOf(context);
    assert(result != null, 'No AuthenticatedClient found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant ClientHolder oldWidget) =>
      oldWidget.apiClient != apiClient
          || oldWidget.settingsClient != settingsClient
          || oldWidget.messagingClient != messagingClient;
}
