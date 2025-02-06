import 'package:flutter/material.dart';
import 'package:recon/clients/api_client.dart';
import 'package:recon/clients/notification_client.dart';
import 'package:recon/clients/settings_client.dart';
import 'package:recon/models/authentication_data.dart';

class ClientHolder extends InheritedWidget {
  final ApiClient apiClient;
  final SettingsClient settingsClient;
  final NotificationClient notificationClient = NotificationClient();

  ClientHolder({
    super.key,
    required AuthenticationData authenticationData,
    required this.settingsClient,
    required super.child,
    required Function() onLogout,
  }) : apiClient = ApiClient(authenticationData: authenticationData, onLogout: onLogout);

  static ClientHolder? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ClientHolder>();
  }

  static ClientHolder of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No AuthenticatedClient found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant ClientHolder oldWidget) =>
      oldWidget.apiClient != apiClient || oldWidget.settingsClient != settingsClient || oldWidget.notificationClient != notificationClient;
}
