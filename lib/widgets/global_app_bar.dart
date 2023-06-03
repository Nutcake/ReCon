import 'package:flutter/material.dart';

class GlobalAppBar extends StatefulWidget implements PreferredSizeWidget {
  const GlobalAppBar({super.key});

  @override
  State<StatefulWidget> createState() => _GlobalAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _GlobalAppBarState extends State<GlobalAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(

    );
  }
}