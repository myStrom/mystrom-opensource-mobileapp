import 'package:flutter/material.dart';

import '../../core/network/device_auth.dart';
import '../../l10n/app_localizations.dart';

class DeviceTokenDialog extends StatefulWidget {
  const DeviceTokenDialog({
    super.key,
    required this.verify,
    required this.deviceLabel,
  });
  final String deviceLabel;
  final Future<bool> Function(String token) verify;

  @override
  State<DeviceTokenDialog> createState() => _DeviceTokenDialogState();
}

class _DeviceTokenDialogState extends State<DeviceTokenDialog> {
  final _controller = TextEditingController();
  bool _remember = false;
  bool _busy = false;
  bool _visible = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final token = _controller.text;
    if (token.isEmpty ||
        token.length > 255 ||
        token.runes.any((c) => c < 32 || c > 126)) {
      setState(() => _error = l10n.tokenInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await widget.verify(token)) {
        if (mounted) setState(() => _error = l10n.tokenRejected);
        return;
      }
      if (mounted) {
        Navigator.pop(context, TokenInput(token, remember: _remember));
      }
    } catch (_) {
      if (mounted) setState(() => _error = l10n.tokenConnectionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(l10n.tokenRequired),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.deviceLabel),
              const SizedBox(height: 8),
              Text(l10n.tokenRequiredMessage),
              const SizedBox(height: 16),
              TextField(
                key: const Key('auth_token_field'),
                controller: _controller,
                autofocus: true,
                enabled: !_busy,
                obscureText: !_visible,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: l10n.deviceToken,
                  errorText: _error,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _visible = !_visible),
                    tooltip: _visible ? l10n.hideToken : l10n.showToken,
                    icon: Icon(
                      _visible ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                onSubmitted: _busy ? null : (_) => _submit(),
              ),
              CheckboxListTile(
                key: const Key('auth_remember_token'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.rememberToken),
                value: _remember,
                onChanged: _busy ? null : (v) => setState(() => _remember = v!),
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
            key: const Key('auth_token_submit'),
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? l10n.loadingEllipsis : l10n.save),
          ),
        ],
      ),
    );
  }
}
