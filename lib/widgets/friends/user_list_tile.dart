import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:recon/auxiliary.dart';
import 'package:recon/clients/messaging_client.dart';
import 'package:recon/models/users/friend.dart';
import 'package:recon/models/users/friend_status.dart';
import 'package:recon/models/users/user.dart';
import 'package:recon/widgets/generic_avatar.dart';

class UserListTile extends StatefulWidget {
  const UserListTile({required this.user, required this.onChanged, super.key});

  final User user;
  final FutureOr<void> Function()? onChanged;

  @override
  State<UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<UserListTile> {
  final DateFormat _regDateFormat = DateFormat.yMMMMd('en_US');
  ContactStatus? _statusOverride;
  bool _loading = false;
  Friend? _asFriend;

  ContactStatus get _status => _asFriend?.contactStatus ?? ContactStatus.searchResult;

  @override
  void didUpdateWidget(covariant UserListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      final mClient = Provider.of<MessagingClient>(context, listen: false);
      _asFriend = mClient.getAsFriend(widget.user.id);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mClient = Provider.of<MessagingClient>(context, listen: false);
    _asFriend = mClient.getAsFriend(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    final mClient = Provider.of<MessagingClient>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, style, action) = switch (_statusOverride ?? _status) {
      ContactStatus.none || ContactStatus.searchResult || ContactStatus.ignored => (
          const Icon(Icons.person_add),
          IconButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
          () async {
            final success = await mClient.addContact(widget.user);
            if (success) {
              setState(() {
                _statusOverride = ContactStatus.accepted;
              });
            }
            return success;
          },
        ),
      ContactStatus.requested || ContactStatus.accepted => (
          Icon(Icons.person_remove),
          IconButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(
              color: colorScheme.error,
              width: 2,
            ),
          ),
          () async {
            if (_asFriend == null) {
              throw "This user is not on your friends-list";
            }
            final success = await mClient.removeContact(_asFriend!);
            if (success) {
              setState(() {
                _statusOverride = ContactStatus.ignored;
              });
            }
          },
        ),
      ContactStatus.blocked => (
          Icon(Icons.block),
          IconButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(
              color: colorScheme.error,
              width: 2,
            ),
          ),
          null,
        ),
    };
    return ListTile(
      leading: GenericAvatar(
        imageUri: Aux.resdbToHttp(widget.user.userProfile?.iconUrl),
      ),
      title: Text(widget.user.username),
      subtitle: Text(_regDateFormat.format(widget.user.registrationDate)),
      trailing: IconButton(
        splashRadius: 24,
        iconSize: 20,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _loading
              ? SizedBox.square(
                  key: ValueKey("loading"),
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : icon,
        ),
        style: style,
        onPressed: _loading
            ? null
            : () async {
                setState(() {
                  _loading = true;
                });
                try {
                  final result = await action?.call() ?? false;
                  if (result) {
                    await widget.onChanged?.call();
                  }
                } catch (e, s) {
                  FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Failed to add contact:\n$e",
                          softWrap: true,
                          maxLines: null,
                        ),
                      ),
                    );
                  }
                }
                setState(() {
                  _loading = false;
                });
              },
      ),
    );
  }
}
