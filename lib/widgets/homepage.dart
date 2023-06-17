import 'package:contacts_plus_plus/widgets/friends/friends_list.dart';
import 'package:contacts_plus_plus/widgets/friends/friends_list_app_bar.dart';
import 'package:contacts_plus_plus/widgets/inventory/inventory_browser.dart';
import 'package:contacts_plus_plus/widgets/inventory/inventory_browser_app_bar.dart';
import 'package:contacts_plus_plus/widgets/sessions/session_list.dart';
import 'package:contacts_plus_plus/widgets/sessions/session_list_app_bar.dart';
import 'package:contacts_plus_plus/widgets/settings_app_bar.dart';
import 'package:contacts_plus_plus/widgets/settings_page.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const List<Widget> _appBars = [
    FriendsListAppBar(),
    SessionListAppBar(),
    InventoryBrowserAppBar(),
    SettingsAppBar()
  ];
  final PageController _pageController = PageController();

  int _selectedPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _appBars[_selectedPage],
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
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: const Border(top: BorderSide(width: 1, color: Colors.black)),
          color: Theme.of(context).colorScheme.background,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          unselectedItemColor: Theme.of(context).colorScheme.onBackground,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          currentIndex: _selectedPage,
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
            setState(() {
              _selectedPage = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: "Chat",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.public),
              label: "Sessions",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory),
              label: "Inventory",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Settings",
            ),
          ],
        ),
      ),
    );
  }
}