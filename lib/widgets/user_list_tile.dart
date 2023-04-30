
import 'package:cached_network_image/cached_network_image.dart';
import 'package:contacts_plus/models/user.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserListTile extends StatefulWidget {
  const UserListTile({required this.user, super.key});

  final User user;

  @override
  State<UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<UserListTile> {
  final DateFormat _regDateFormat = DateFormat.yMMMMd('en_US');
  late bool _localAdded = widget.user.userProfile != null;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CachedNetworkImage(
        imageBuilder: (context, imageProvider) {
          return CircleAvatar(
            foregroundImage: imageProvider,
          );
        },
        imageUrl: widget.user.userProfile?.httpIconUri.toString() ?? "",
        placeholder: (context, url) {
          return const CircleAvatar(backgroundColor: Colors.white54,);
        },
        errorWidget: (context, error, what) => const CircleAvatar(
          backgroundColor: Colors.transparent,
          child: Icon(Icons.person),
        ),
      ),
      title: Text(widget.user.username),
      subtitle: Text(_regDateFormat.format(widget.user.registrationDate)),
      trailing: IconButton(
        onPressed: () {
          setState(() {
            _localAdded = !_localAdded;
          });
        },
        icon: _localAdded ? const Icon(Icons.person_remove_alt_1) : const Icon(Icons.person_add_alt_1),
      ),
    );
  }
}