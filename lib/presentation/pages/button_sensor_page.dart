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
import '../providers/device_provider.dart';
import 'device_settings_page.dart';
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
        _error = 'No IP address';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _loading = true;
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

  /// Human-readable label for a referer (btn1 -> "Button 1", etc.).
  static String _refererLabel(String referer) {
    switch (referer) {
      case 'btn1':
        return 'Button 1';
      case 'btn2':
        return 'Button 2';
      case 'btn3':
        return 'Button 3';
      case 'btn4':
        return 'Button 4';
      case 'temp':
        return 'Temperature';
      case 'humi':
        return 'Humidity';
      default:
        return referer[0].toUpperCase() + referer.substring(1);
    }
  }

  /// Human-readable label for an action.
  static String _actionLabel(String action) {
    switch (action) {
      case 'generic':
        return 'Generic';
      case 'single':
        return 'Single press';
      case 'double':
        return 'Double press';
      case 'long':
        return 'Long press';
      case 'over':
        return 'Over threshold';
      case 'under':
        return 'Under threshold';
      default:
        return action[0].toUpperCase() + action.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            tooltip: 'Settings',
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
            if (_error != null)
              Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!),
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (_state?.temperature != null)
                  SensorCard(
                    label: 'Temperature',
                    value:
                        (_state!.temperature! + widget.device.temperatureOffset)
                            .toStringAsFixed(1),
                    unit: '°C',
                    icon: Icons.thermostat,
                  ),
                if (_state?.humidity != null)
                  SensorCard(
                    label: 'Humidity',
                    value: _state!.humidity!.toStringAsFixed(1),
                    unit: '%',
                    icon: Icons.water_drop,
                  ),
                if (_state?.battery != null)
                  SensorCard(
                    label: 'Battery',
                    value: '${_state!.battery!.percent}%',
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
            const Text(
              'Action URLs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final (referer, actions) in _refererActions) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  _refererLabel(referer),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              for (final action in actions)
                ListTile(
                  dense: true,
                  title: Text(_actionLabel(action)),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () => _configure(referer, action, devices),
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
      _snack('$referer/$action → $url');
    } catch (e) {
      _snack(e.toString());
    }
  }
}
