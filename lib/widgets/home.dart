
import 'package:contacts_plus_plus/client_holder.dart';
import 'package:contacts_plus_plus/clients/messaging_client.dart';
import 'package:contacts_plus_plus/widgets/friends/friends_list.dart';
import 'package:contacts_plus_plus/widgets/sessions/sessions_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController(initialPage: 1);
  ClientHolder? _clientHolder;
  late MessagingClient _mClient;
  int _currentPageIndex = 1;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final clientHolder = ClientHolder.of(context);
    if (_clientHolder != clientHolder) {
      _clientHolder = clientHolder;
      _mClient = MessagingClient(
        apiClient: clientHolder.apiClient,
        notificationClient: clientHolder.notificationClient,
        settingsClient: clientHolder.settingsClient,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentPageIndex,
          onDestinationSelected: (int index) async {
            setState(() {
              _currentPageIndex = index;
            });
            await _pageController.animateToPage(index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCirc,
            );
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.folder_copy), label: "Inventory"),
            NavigationDestination(icon: Icon(Icons.chat), label: "Contacts"),
            NavigationDestination(icon: Icon(Icons.location_city), label: "Sessions")
          ],
        ),
        appBar: FriendsListAppBar(mClient: _mClient,),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: [
            const Center(child: Text("Not implemented yet"),),
            ChangeNotifierProvider
                .value( // This doesn't need to be a proxy provider since the arguments should never change during it's lifetime.
              value: _mClient,
              child: const FriendsList(),
            ),
            const SessionsList(),
          ],
        )
    );
  }

  @override
  bool get wantKeepAlive => true;
}