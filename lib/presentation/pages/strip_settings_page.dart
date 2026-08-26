import 'package:flutter/material.dart';

import '../../core/network/device_http_client.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/control_strip.dart';
import '../../l10n/app_localizations.dart';

/// Strip settings page — configure the channel mode (colors / channels / cold_warm).
///
/// - **colors**: WRGB strip like a bulb — HSV or WRGB color control
/// - **channels**: 4 independently dimmable channels (e.g. 4 white strips)
/// - **cold_warm**: 2 warm + 2 cold channels — W+R = warm, G+B = cold
class StripSettingsPage extends StatefulWidget {
  const StripSettingsPage({super.key, required this.device});

  final DeviceEntity device;

  @override
  State<StripSettingsPage> createState() => _StripSettingsPageState();
}

class _StripSettingsPageState extends State<StripSettingsPage> {
  late final ControlStrip _control;
  String? _chMode;
  bool _loading = true;
  bool _noIpError = false;
  String? _error;

  static const _modes = ['colors', 'channels', 'cold_warm'];

  @override
  void initState() {
    super.initState();
    _control = ControlStrip(
      DeviceRemoteDataSource(DeviceHttpClient(token: widget.device.token)),
    );
    _loadChMode();
  }

  String _modeDescription(AppLocalizations l10n, String mode) {
    return switch (mode) {
      'colors' => l10n.chModeColorsDesc,
      'channels' => l10n.chModeChannelsDesc,
      'cold_warm' => l10n.chModeColdWarmDesc,
      _ => '',
    };
  }

  Future<void> _loadChMode() async {
    if (widget.device.bestIp == null) {
      setState(() {
        _loading = false;
        _noIpError = true;
        _error = null;
      });
      return;
    }
    try {
      final mode = await _control.getChMode(widget.device.bestIp!);
      setState(() {
        _chMode = mode;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _setMode(String mode) async {
    if (widget.device.bestIp == null) return;
    try {
      await _control.setChMode(widget.device.bestIp!, chMode: mode);
      setState(() => _chMode = mode);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.channelModeSet(mode))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('strip_settings_back_button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.stripSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_noIpError || _error != null)
            Card(
              color: Colors.red.shade100,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_noIpError ? l10n.noIpAddress : _error!),
              ),
            ),
          Text(l10n.channelMode),
          const SizedBox(height: 12),
          for (final mode in _modes)
            Builder(
              builder: (context) {
                final isSelected = _chMode == mode;
                return Card(
                  key: Key('strip_chmode_$mode'),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    title: Text(
                      mode,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(_modeDescription(l10n, mode)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () => _setMode(mode),
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
          Text(
            l10n.chModeChangeNote,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
