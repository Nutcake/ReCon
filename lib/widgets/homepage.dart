import 'package:flutter/material.dart';
import 'package:recon/widgets/friends/friends_list.dart';
import 'package:recon/widgets/friends/friends_list_app_bar.dart';
import 'package:recon/widgets/inventory/inventory_browser.dart';
import 'package:recon/widgets/inventory/inventory_browser_app_bar.dart';
import 'package:recon/widgets/recon_navbar.dart';
import 'package:recon/widgets/sessions/session_list.dart';
import 'package:recon/widgets/sessions/session_list_app_bar.dart';
import 'package:recon/widgets/settings_app_bar.dart';
import 'package:recon/widgets/settings_page.dart';
import 'package:recon/widgets/translucent_glass.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  static const List<Widget> _appBars = [
    FriendsListAppBar(),
    SessionListAppBar(),
    InventoryBrowserAppBar(),
    SettingsAppBar(),
    SettingsAppBar()
  ];

  static const List<ReConNavigationDestination> navigationDestinations = [
    ReConNavigationDestination(label: 'Contacts', icon: Icon(Icons.mail_outline_rounded), color: 'green'),
    ReConNavigationDestination(label: 'Sessions', icon: Icon(Icons.public), color: 'cyan'),
    ReConNavigationDestination(label: 'Inventory', icon: Icon(Icons.backpack_outlined), color: 'yellow'),
    ReConNavigationDestination(label: 'Mods', icon: Icon(Icons.settings), color: 'red'),
    ReConNavigationDestination(label: 'Settings', icon: Icon(Icons.settings), color: 'purple'),
  ];

  final PageController _pageController = PageController();

  int _selectedPage = 0;

  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 50),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
        backgroundColor: theme.colorScheme.background,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: TranslucentGlass.edgeToEdge(
            context,
            gradient: TranslucentGlass.defaultTopGradient(context),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _appBars[_selectedPage],
            ),
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            FriendsList(),
            SessionList(),
            InventoryBrowser(),
            SettingsPage(),
            SettingsPage(),
          ],
        ),
        bottomNavigationBar: ReConNavigationBar(
          animationController: animationController,
          selectedIndex: _selectedPage,
          onDestinationSelected: (int index) async {
            if (_selectedPage != index) {
              animationController.duration = const Duration(milliseconds: 100);
              await animationController.reverse(from: 1);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
              setState(() {
                _selectedPage = index;
              });
              animationController.duration = const Duration(milliseconds: 200);
              animationController.forward(from: 0);
            }
          },
          destinations: navigationDestinations,
        ));
  }
}
