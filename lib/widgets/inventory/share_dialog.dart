import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:recon/clients/inventory_client.dart';
import 'package:recon/models/records/record.dart';
import 'package:share_plus/share_plus.dart';

class ShareDialog extends StatefulWidget {
  const ShareDialog({required this.record, super.key});

  final Record record;

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  bool _loading = false;
  bool _isPublic = false;
  String? _error;
  String? _copyButtonOverride;

  @override
  void initState() {
    super.initState();
    _isPublic = widget.record.isPublic;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;

    return AlertDialog(
      title: Text("inventory.share.shareDir").tr(),
      content: Column(
        mainAxisSize: .min,
        children: [
          if (_isPublic)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextButton.icon(
                onPressed: _loading
                    ? null
                    : () async {
                        final shareUrl = "resrec:///${widget.record.ownerId}/${widget.record.id}";
                        if (isDesktop) {
                          await Clipboard.setData(ClipboardData(text: shareUrl));
                          if (mounted) {
                            setState(() {
                              _copyButtonOverride = "inventory.share.copied".tr();
                            });
                            await Future.delayed(const Duration(seconds: 2));
                            if (mounted) {
                              setState(() {
                                _copyButtonOverride = null;
                              });
                            }
                          }
                        } else {
                          await SharePlus.instance.share(ShareParams(text: shareUrl));
                        }
                      },
                label: Text(_copyButtonOverride ?? (isDesktop ? "inventory.share.copyUrlButton" : "inventory.share.shareUrlButton").tr()),
                icon: Icon(_copyButtonOverride != null ? Icons.check : (isDesktop ? Icons.copy : Icons.share)),
              ),
            ),
          Padding(padding: const EdgeInsets.all(8.0), child: Text(_isPublic ? "inventory.share.makePrivate" : "inventory.share.makePublic").tr()),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading
                ? null
                : () async {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    final iClient = Provider.of<InventoryClient>(context, listen: false);
                    try {
                      await iClient.setPublicRecursively(widget.record, !_isPublic);
                      _isPublic = !_isPublic;
                    } catch (e) {
                      _error = e.toString();
                    }
                    if (mounted) {
                      setState(() {
                        _loading = false;
                      });
                    }
                  },
            icon: Icon(_isPublic ? Icons.privacy_tip : Icons.public),
            label: Text(_isPublic ? "inventory.share.makePrivateButton" : "inventory.share.makePublicButton").tr(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_error!, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
    );
  }
}
