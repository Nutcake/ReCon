import 'package:contacts_plus_plus/apis/contact_api.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/client_holder.dart';
import 'package:contacts_plus_plus/models/users/user.dart';
import 'package:contacts_plus_plus/widgets/generic_avatar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserListTile extends StatefulWidget {
  const UserListTile({required this.user, required this.isFriend, required this.onChanged, super.key});

  final User user;
  final bool isFriend;
  final Function()? onChanged;

  @override
  State<UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<UserListTile> {
  final DateFormat _regDateFormat = DateFormat.yMMMMd('en_US');
  late bool _localAdded = widget.isFriend;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;
    final style = _localAdded ? IconButton.styleFrom(
      foregroundColor: colorScheme.onBackground,
      side: BorderSide(
        color: colorScheme.error,
        width: 2
      ),
    ) : IconButton.styleFrom(
      foregroundColor: colorScheme.onBackground,
        side: BorderSide(
          color: colorScheme.primary,
          width: 2
        ),
    );
    return ListTile(
      leading: GenericAvatar(imageUri: Aux.resdbToHttp(widget.user.userProfile?.iconUrl),),
      title: Text(widget.user.username),
      subtitle: Text(_regDateFormat.format(widget.user.registrationDate)),
      trailing: IconButton(
        splashRadius: 24,
        iconSize: 20,
        icon: _localAdded ? const Icon(Icons.person_remove) : const Icon(Icons.person_add),
        style: style,
        onPressed: _loading ? null : () async {
          setState(() {
            _loading = true;
          });
          try {
            if (_localAdded) {
              await ContactApi.removeUserAsFriend(ClientHolder
                  .of(context)
                  .apiClient, user: widget.user);
            } else {
              await ContactApi.addUserAsFriend(ClientHolder
                  .of(context)
                  .apiClient, user: widget.user);
            }
            setState(() {
              _loading = false;
              _localAdded = !_localAdded;
            });
            widget.onChanged?.call();
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
        },
      ),
    );
  }
}