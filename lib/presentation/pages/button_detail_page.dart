import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/device_http_client.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/repositories/action_config_repository.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/configure_button_action.dart';
import '../../l10n/app_localizations.dart';
import '../providers/device_provider.dart';
import '../widgets/action_url_picker.dart';
import 'device_settings_page.dart';

/// Button action URL configuration page.
class ButtonDetailPage extends StatefulWidget {
  const ButtonDetailPage({super.key, required this.device});

  final DeviceEntity device;

  @override
  State<ButtonDetailPage> createState() => _ButtonDetailPageState();
}

class _ButtonDetailPageState extends State<ButtonDetailPage> {
  late final ConfigureButtonAction _config;

  static const _schemes = ['single', 'double', 'long', 'touch', 'generic'];

  static String _schemeLabel(AppLocalizations l10n, String scheme) {
    switch (scheme) {
      case 'single':
        return l10n.singlePress;
      case 'double':
        return l10n.doublePress;
      case 'long':
        return l10n.longPress;
      case 'touch':
        return l10n.touch;
      case 'generic':
        return l10n.generic;
      default:
        return scheme[0].toUpperCase() + scheme.substring(1);
    }
  }

  @override
  void initState() {
    super.initState();
    _config = ConfigureButtonAction(
      ActionConfigRepository(
        DeviceRemoteDataSource(DeviceHttpClient(token: widget.device.token)),
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final devices = context.watch<DeviceProvider>().devices;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('detail_back_button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.device.displayName),
        actions: [
          IconButton(
            key: const Key('button_settings_button'),
            icon: const Icon(Icons.settings),
            tooltip: l10n.settingsTooltip,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeviceSettingsPage(device: widget.device),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.actionUrls,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.actionUrlsSubtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          for (final scheme in _schemes)
            Card(
              key: Key('button_scheme_$scheme'),
              child: ListTile(
                title: Text(_schemeLabel(l10n, scheme)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _configure(scheme, devices, l10n),
              ),
            ),
        ],
      ),
    );
  }

  void _configure(
    String scheme,
    List<DeviceEntity> devices,
    AppLocalizations l10n,
  ) async {
    if (widget.device.bestIp == null) return;
    final url = await showDialog<String>(
      context: context,
      builder: (_) => ActionUrlPicker(
        devices: devices,
        onUrlGenerated: (u) => Navigator.pop(context, u),
      ),
    );
    if (url == null) return;
    try {
      await _config.setButtonAction(
        ip: widget.device.bestIp!,
        scheme: scheme,
        url: url,
      );
      _snack(l10n.schemeUrlSaved(scheme, url));
    } catch (e) {
      _snack(e.toString());
    }
  }
}
