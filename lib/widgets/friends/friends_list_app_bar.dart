import 'package:contacts_plus_plus/apis/user_api.dart';
import 'package:contacts_plus_plus/client_holder.dart';
import 'package:contacts_plus_plus/clients/messaging_client.dart';
import 'package:contacts_plus_plus/models/users/online_status.dart';
import 'package:contacts_plus_plus/models/users/user_status.dart';
import 'package:contacts_plus_plus/widgets/friends/user_search.dart';
import 'package:contacts_plus_plus/widgets/my_profile_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class FriendsListAppBar extends StatefulWidget {
  const FriendsListAppBar({super.key});

  @override
  State<StatefulWidget> createState() => _FriendsListAppBarState();
}

class _FriendsListAppBarState extends State<FriendsListAppBar> with AutomaticKeepAliveClientMixin {
  Future<UserStatus>? _userStatusFuture;
  ClientHolder? _clientHolder;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final clientHolder = ClientHolder.of(context);
    if (_clientHolder != clientHolder) {
      _clientHolder = clientHolder;
      _refreshUserStatus();
    }
  }

  void _refreshUserStatus() {
    final apiClient = _clientHolder!.apiClient;
    _userStatusFuture ??= UserApi.getUserStatus(apiClient, userId: apiClient.userId).then((value) async {
      if (value.onlineStatus == OnlineStatus.offline) {
        final newStatus = value.copyWith(
            onlineStatus:
            OnlineStatus.values[_clientHolder!.settingsClient.currentSettings.lastOnlineStatus.valueOrDefault]);
        await UserApi.setStatus(apiClient, status: newStatus);
        return newStatus;
      }
      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AppBar(
      title: const Text("Contacts++"),
      systemOverlayStyle: SystemUiOverlayStyle(
        systemNavigationBarColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      actions: [
        FutureBuilder(
          future: _userStatusFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final userStatus = snapshot.data as UserStatus;
              return PopupMenuButton<OnlineStatus>(
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          Icons.circle,
                          size: 16,
                          color: userStatus.onlineStatus.color(context),
                        ),
                      ),
                      Text(toBeginningOfSentenceCase(userStatus.onlineStatus.name) ?? "Unknown"),
                    ],
                  ),
                  onSelected: (OnlineStatus onlineStatus) async {
                    try {
                      final newStatus = userStatus.copyWith(onlineStatus: onlineStatus);
                      setState(() {
                        _userStatusFuture = Future.value(newStatus.copyWith(lastStatusChange: DateTime.now()));
                      });
                      final settingsClient = _clientHolder!.settingsClient;
                      await UserApi.setStatus(_clientHolder!.apiClient, status: newStatus);
                      await settingsClient.changeSettings(
                          settingsClient.currentSettings.copyWith(lastOnlineStatus: onlineStatus.index));
                    } catch (e, s) {
                      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s));
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text("Failed to set online-status.")));
                      setState(() {
                        _userStatusFuture = Future.value(userStatus);
                      });
                    }
                  },
                  itemBuilder: (BuildContext context) => OnlineStatus.values
                      .where((element) => element == OnlineStatus.online || element == OnlineStatus.invisible)
                      .map(
                        (item) => PopupMenuItem<OnlineStatus>(
                      value: item,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 16,
                            color: item.color(context),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(toBeginningOfSentenceCase(item.name)!),
                        ],
                      ),
                    ),
                  )
                      .toList());
            } else if (snapshot.hasError) {
              return TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2)),
                onPressed: () {
                  setState(() {
                    _userStatusFuture =
                        UserApi.getUserStatus(_clientHolder!.apiClient, userId: _clientHolder!.apiClient.userId);
                  });
                },
                icon: const Icon(Icons.warning),
                label: const Text("Retry"),
              );
            } else {
              return TextButton.icon(
                style: TextButton.styleFrom(
                  disabledForegroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: null,
                icon: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 4),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                label: const Text("Loading"),
              );
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4),
          child: PopupMenuButton<MenuItemDefinition>(
            icon: const Icon(Icons.more_vert),
            onSelected: (MenuItemDefinition itemDef) async {
              await itemDef.onTap();
            },
            itemBuilder: (BuildContext context) => [
              MenuItemDefinition(
                name: "Find Users",
                icon: Icons.person_add,
                onTap: () async {
                  final mClient = Provider.of<MessagingClient>(context, listen: false);
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider<MessagingClient>.value(
                        value: mClient,
                        child: const UserSearch(),
                      ),
                    ),
                  );
                },
              ),
              MenuItemDefinition(
                name: "My Profile",
                icon: Icons.person,
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return const MyProfileDialog();
                    },
                  );
                },
              ),
            ]
                .map(
                  (item) => PopupMenuItem<MenuItemDefinition>(
                value: item,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.name),
                    Icon(item.icon),
                  ],
                ),
              ),
            )
                .toList(),
          ),
        )
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class MenuItemDefinition {
  final String name;
  final IconData icon;
  final Function() onTap;

  const MenuItemDefinition({required this.name, required this.icon, required this.onTap});
}
