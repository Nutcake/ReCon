import 'package:contacts_plus_plus/apis/user_api.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/models/user.dart';
import 'package:contacts_plus_plus/widgets/generic_avatar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserListTile extends StatefulWidget {
  const UserListTile({required this.user, required this.isFriend, required this.onChange, super.key});

  final User user;
  final bool isFriend;
  final Function()? onChange;

  @override
  State<UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<UserListTile> {
  final DateFormat _regDateFormat = DateFormat.yMMMMd('en_US');
  late bool _localAdded = widget.isFriend;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: GenericAvatar(imageUri: Aux.neosDbToHttp(widget.user.userProfile?.iconUrl),),
      title: Text(widget.user.username),
      subtitle: Text(_regDateFormat.format(widget.user.registrationDate)),
      trailing: IconButton(
        onPressed: _loading ? null : () async {
          setState(() {
            _loading = true;
          });
          try {
            if (_localAdded) {
              await UserApi.removeUserAsFriend(ClientHolder.of(context).apiClient, user: widget.user);
            } else {
              await UserApi.addUserAsFriend(ClientHolder.of(context).apiClient, user: widget.user);
            }
          } catch (e, s) {
            FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 5),
                content: Text(
                  "Something went wrong: $e",
                  softWrap: true,
                  maxLines: null,
                ),
              ),
            );
            setState(() {
              _loading = false;
            });
            return;
          }
          setState(() {
            _loading = false;
            _localAdded = !_localAdded;
          });
          widget.onChange?.call();
        },
        splashRadius: 24,
        icon: _localAdded ? const Icon(Icons.person_remove_alt_1) : const Icon(Icons.person_add_alt_1),
      ),
    );
  }
}