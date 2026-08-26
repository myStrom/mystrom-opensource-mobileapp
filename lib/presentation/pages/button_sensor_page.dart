import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/device_http_client.dart';
import '../../core/utils/device_type.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/button_sensor_state.dart';
import '../../data/repositories/action_config_repository.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/configure_button_action.dart';
import '../../domain/usecases/read_sensors.dart';
import '../../l10n/app_localizations.dart';
import '../providers/device_provider.dart';
import 'device_settings_page.dart';
import '../utils/number_format.dart';
import '../widgets/action_url_picker.dart';
import '../widgets/battery_indicator.dart';
import '../widgets/sensor_card.dart';

/// Button-se (BP2 / BM1) page: sensors + action URL config.
class ButtonSensorPage extends StatefulWidget {
  const ButtonSensorPage({super.key, required this.device});

  final DeviceEntity device;

  @override
  State<ButtonSensorPage> createState() => _ButtonSensorPageState();
}

class _ButtonSensorPageState extends State<ButtonSensorPage> {
  late final ReadSensors _sensors;
  late final ConfigureButtonAction _config;
  ButtonSensorStateModel? _state;
  bool _loading = true;
  bool _noIpError = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final remote = DeviceRemoteDataSource(
      DeviceHttpClient(token: widget.device.token),
    );
    _sensors = ReadSensors(remote);
    _config = ConfigureButtonAction(ActionConfigRepository(remote));
    _refresh();
  }

  Future<void> _refresh() async {
    if (widget.device.bestIp == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _noIpError = true;
        _error = null;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _loading = true;
      _noIpError = false;
      _error = null;
    });
    try {
      final s = await _sensors.getButtonSe(widget.device.bestIp!);
      if (!mounted) return;
      setState(() {
        _state = s;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  List<(String, List<String>)> get _refererActions {
    if (widget.device.type == DeviceType.bp2) {
      return [
        ('btn1', ['generic', 'single', 'double', 'long']),
        ('btn2', ['generic', 'single', 'double', 'long']),
        ('btn3', ['generic', 'single', 'double', 'long']),
        ('btn4', ['generic', 'single', 'double', 'long']),
        ('temp', ['generic', 'over', 'under']),
        ('humi', ['generic', 'over', 'under']),
      ];
    }
    if (widget.device.type == DeviceType.bp1) {
      return [
        ('btn1', ['generic', 'single', 'double', 'long']),
        ('temp', ['generic', 'over', 'under']),
        ('humi', ['generic', 'over', 'under']),
      ];
    }
    // BM1
    return [
      ('temp', ['generic', 'over', 'under']),
      ('humi', ['generic', 'over', 'under']),
    ];
  }

  static String _refererLabel(AppLocalizations l10n, String referer) {
    switch (referer) {
      case 'btn1':
        return l10n.buttonN(1);
      case 'btn2':
        return l10n.buttonN(2);
      case 'btn3':
        return l10n.buttonN(3);
      case 'btn4':
        return l10n.buttonN(4);
      case 'temp':
        return l10n.temperature;
      case 'humi':
        return l10n.humidity;
      default:
        return referer[0].toUpperCase() + referer.substring(1);
    }
  }

  static String _actionLabel(AppLocalizations l10n, String action) {
    switch (action) {
      case 'generic':
        return l10n.generic;
      case 'single':
        return l10n.singlePress;
      case 'double':
        return l10n.doublePress;
      case 'long':
        return l10n.longPress;
      case 'over':
        return l10n.overThreshold;
      case 'under':
        return l10n.underThreshold;
      default:
        return action[0].toUpperCase() + action.substring(1);
    }
  }

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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (_state?.temperature != null)
                  SensorCard(
                    label: l10n.temperature,
                    value: formatDecimal(
                      context,
                      _state!.temperature! + widget.device.temperatureOffset,
                      1,
                    ),
                    unit: '°C',
                    icon: Icons.thermostat,
                  ),
                if (_state?.humidity != null)
                  SensorCard(
                    label: l10n.humidity,
                    value: l10n.percentValue(
                      formatDecimal(context, _state!.humidity!, 1),
                    ),
                    icon: Icons.water_drop,
                  ),
                if (_state?.battery != null)
                  SensorCard(
                    label: l10n.battery,
                    value: l10n.percentValue('${_state!.battery!.percent}'),
                    icon: Icons.battery_full,
                  ),
              ],
            ),
            if (_state?.battery != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: BatteryIndicator(
                  percent: _state!.battery!.percent,
                  charging: _state!.battery!.charging,
                ),
              ),
            const SizedBox(height: 24),
            Text(
              l10n.actionUrls,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final (referer, actions) in _refererActions) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  _refererLabel(l10n, referer),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              for (final action in actions)
                ListTile(
                  dense: true,
                  title: Text(_actionLabel(l10n, action)),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () => _configure(referer, action, devices, l10n),
                ),
              const Divider(),
            ],
          ],
        ),
      ),
    );
  }

  void _configure(
    String referer,
    String action,
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
      await _config.setButtonSeAction(
        ip: widget.device.bestIp!,
        referer: referer,
        action: action,
        url: url,
      );
      _snack(l10n.refererActionUrlSaved(referer, action, url));
    } catch (e) {
      _snack(e.toString());
    }
  }
}
