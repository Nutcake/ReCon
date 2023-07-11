import 'dart:math';

import 'package:contacts_plus_plus/client_holder.dart';
import 'package:contacts_plus_plus/clients/session_client.dart';
import 'package:contacts_plus_plus/clients/settings_client.dart';
import 'package:contacts_plus_plus/models/session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SessionFilterDialog extends StatefulWidget {
  const SessionFilterDialog({required this.lastFilter, super.key});

  final SessionFilterSettings lastFilter;

  @override
  State<StatefulWidget> createState() => _SessionFilterDialogState();
}

class _SessionFilterDialogState extends State<SessionFilterDialog> {
  final TextEditingController _sessionNameController = TextEditingController();
  final TextEditingController _hostNameController = TextEditingController();
  late SessionFilterSettings _currentFilter;

  @override
  void didUpdateWidget(covariant SessionFilterDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    _currentFilter = widget.lastFilter;
    if (oldWidget.lastFilter != widget.lastFilter) {
      _sessionNameController.text = widget.lastFilter.name;
      _hostNameController.text = widget.lastFilter.hostName;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.lastFilter;
    _sessionNameController.text = widget.lastFilter.name;
    _hostNameController.text = widget.lastFilter.hostName;
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    _hostNameController.dispose();
    super.dispose();
  }

  Future<void> _updateSettings() async {
    final settingsClient = ClientHolder.of(context).settingsClient;
    await settingsClient.changeSettings(settingsClient.currentSettings.copyWith(
      sessionViewLastMinimumUsers: _currentFilter.minActiveUsers,
      sessionViewLastIncludeEnded: _currentFilter.includeEnded,
      sessionViewLastIncludeEmpty: _currentFilter.includeEmptyHeadless,
      sessionViewLastIncludeIncompatible: _currentFilter.includeIncompatible,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(24),
      title: const Text("Filter"),
      content: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: _sessionNameController,
                  maxLines: 1,
                  onChanged: (value) {
                    _currentFilter = _currentFilter.copyWith(name: value);
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    labelText: 'Session Name',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: _hostNameController,
                  onChanged: (value) {
                    _currentFilter = _currentFilter.copyWith(hostName: value);
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    labelText: 'Host Name',
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Text("Minimum Users"),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _currentFilter =
                            _currentFilter.copyWith(minActiveUsers: max(0, _currentFilter.minActiveUsers - 1));
                      });
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    "${_currentFilter.minActiveUsers}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _currentFilter = _currentFilter.copyWith(
                            minActiveUsers: _currentFilter.minActiveUsers + 1, includeEmptyHeadless: false);
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              SessionFilterCheckbox(
                label: "Include Ended",
                value: _currentFilter.includeEnded,
                onChanged: (value) {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(includeEnded: value);
                  });
                },
              ),
              SessionFilterCheckbox(
                label: "Include Empty Headless",
                value: _currentFilter.includeEmptyHeadless && _currentFilter.minActiveUsers == 0,
                onChanged: _currentFilter.minActiveUsers > 0
                    ? null
                    : (value) {
                        setState(() {
                          _currentFilter = _currentFilter.copyWith(includeEmptyHeadless: value);
                        });
                      },
              ),
              SessionFilterCheckbox(
                label: "Include Incompatible",
                value: _currentFilter.includeIncompatible,
                onChanged: (value) {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(includeIncompatible: value);
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            Provider.of<SessionClient>(context, listen: false).filterSettings = _currentFilter;
            Navigator.of(context).pop();
            await _updateSettings();
          },
          child: const Text("Okay"),
        ),
      ],
    );
  }
}

class SessionFilterCheckbox extends StatelessWidget {
  const SessionFilterCheckbox({required this.label, this.onChanged, this.value, super.key});

  final String label;
  final void Function(bool? value)? onChanged;
  final bool? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
