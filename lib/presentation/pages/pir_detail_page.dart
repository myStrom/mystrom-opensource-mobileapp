import 'package:flutter/material.dart';

import '../../core/network/device_http_client.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/pir_state.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/read_sensors.dart';
import '../../l10n/app_localizations.dart';
import '../utils/number_format.dart';
import '../widgets/sensor_card.dart';
import 'device_settings_page.dart';
import 'scheduler_page.dart';

/// PIR sensor page (WMS): motion, light, temperature + action URL config.
class PirDetailPage extends StatefulWidget {
  const PirDetailPage({super.key, required this.device});

  final DeviceEntity device;

  @override
  State<PirDetailPage> createState() => _PirDetailPageState();
}

class _PirDetailPageState extends State<PirDetailPage> {
  late final ReadSensors _sensors;
  PirStateModel? _state;
  bool _loading = true;
  bool _noIpError = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sensors = ReadSensors(
      DeviceRemoteDataSource(DeviceHttpClient(token: widget.device.token)),
    );
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
      final s = await _sensors.getPir(widget.device.bestIp!);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            key: const Key('pir_scheduler_button'),
            icon: const Icon(Icons.schedule),
            tooltip: l10n.schedulerTooltip,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SchedulerPage(device: widget.device),
              ),
            ),
          ),
          IconButton(
            key: const Key('detail_settings_button'),
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
                SensorCard(
                  label: l10n.motion,
                  value: _state?.motion == true ? l10n.yes : l10n.no,
                  icon: _state?.motion == true
                      ? Icons.directions_run
                      : Icons.nightlight_round,
                ),
                if (_state?.lightLux != null)
                  SensorCard(
                    label: l10n.light,
                    value: formatDecimal(context, _state!.lightLux!, 1),
                    unit: l10n.unitLux,
                    icon: Icons.wb_sunny,
                  ),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
