import 'package:flutter/material.dart';

import '../../domain/entities/device_entity.dart';
import '../../core/network/device_auth.dart';
import '../../core/network/device_http_client.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../l10n/app_localizations.dart';

/// Dialog shown when adding a device. Lets the user override the default
/// name and pick a custom color for the device card.
class AddDeviceDialog extends StatefulWidget {
  const AddDeviceDialog({super.key, required this.device});

  final DeviceEntity device;

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  late final TextEditingController _nameController;
  int? _selectedColor;
  final _tokenController = TextEditingController();
  bool _rememberToken = false;
  bool _busy = false;
  String? _error;

  static const List<Color> _palette = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.device.displayName);
    _selectedColor = widget.device.colorValue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final ip = widget.device.bestIp;
    if (ip == null) {
      setState(() => _error = l10n.noIpAddress);
      return;
    }
    final auth = DeviceAuth.shared;
    auth?.bind(ip, widget.device.mac);
    final token = _tokenController.text;
    if (token.isNotEmpty &&
        (token.length > 255 || token.runes.any((c) => c < 32 || c > 126))) {
      setState(() => _error = l10n.tokenInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final client = DeviceHttpClient();
    try {
      if (token.isNotEmpty) {
        if (!await client.verifyToken(ip, token)) {
          if (mounted) setState(() => _error = l10n.tokenRejected);
          return;
        }
        await auth?.accept(ip, token, remember: _rememberToken);
      } else {
        await DeviceRemoteDataSource(client).getInfo(ip);
      }
      if (!mounted) return;
      final name = _nameController.text.trim();
      Navigator.pop(
        context,
        AddDeviceResult(
          customName: name.isEmpty ? null : name,
          colorValue: _selectedColor,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _error = l10n.tokenConnectionFailed);
    } finally {
      client.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addDevice),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.name,
                hintText: l10n.nameHintExample,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('add_token_field'),
              controller: _tokenController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(labelText: l10n.deviceToken),
            ),
            CheckboxListTile(
              key: const Key('add_remember_token'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.rememberToken),
              value: _rememberToken,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _rememberToken = v!),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            Text(l10n.color, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _palette)
                  GestureDetector(
                    onTap: () => setState(() => _selectedColor = c.toARGB32()),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == c.toARGB32()
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: _selectedColor == c.toARGB32()
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('add_device_submit'),
          onPressed: _busy ? null : _submit,
          child: Text(l10n.add),
        ),
      ],
    );
  }
}

/// Result returned by [AddDeviceDialog].
class AddDeviceResult {
  final String? customName;
  final int? colorValue;

  const AddDeviceResult({this.customName, this.colorValue});
}
