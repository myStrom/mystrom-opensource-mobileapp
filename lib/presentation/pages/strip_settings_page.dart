import 'package:flutter/material.dart';

import '../../core/network/device_http_client.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/control_strip.dart';

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
  String? _error;

  static const _modeDescriptions = {
    'colors': 'WRGB strip — full color control (HSV or WRGB)',
    'channels': '4 independent dimmable channels (e.g. 4 white strips)',
    'cold_warm': '2 warm + 2 cold white channels (W+R = warm, G+B = cold)',
  };

  @override
  void initState() {
    super.initState();
    _control = ControlStrip(
      DeviceRemoteDataSource(DeviceHttpClient(token: widget.device.token)),
    );
    _loadChMode();
  }

  Future<void> _loadChMode() async {
    if (widget.device.bestIp == null) {
      setState(() {
        _loading = false;
        _error = 'No IP address';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Channel mode set to: $mode')));
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('strip_settings_back_button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Strip Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Card(
              color: Colors.red.shade100,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!),
              ),
            ),
          const Text('Channel Mode'),
          const SizedBox(height: 12),
          ..._modeDescriptions.entries.map((entry) {
            final isSelected = _chMode == entry.key;
            return Card(
              key: Key('strip_chmode_${entry.key}'),
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: ListTile(
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(entry.value),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () => _setMode(entry.key),
              ),
            );
          }),
          const SizedBox(height: 24),
          const Text(
            'Changing the channel mode affects how the strip is controlled. '
            'The control page will adapt automatically.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
