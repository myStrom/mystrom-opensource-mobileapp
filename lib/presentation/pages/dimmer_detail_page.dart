import 'package:flutter/material.dart';

import '../../core/network/device_http_client.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/dimmer_state.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/control_dimmer.dart';
import '../../domain/usecases/set_timer.dart';
import '../../l10n/app_localizations.dart';
import '../utils/number_format.dart';
import '../widgets/feature_tiles_row.dart';
import '../widgets/timer_controls.dart';
import 'device_settings_page.dart';
import 'scheduler_page.dart';

/// Dimmer control page (WLL).
class DimmerDetailPage extends StatefulWidget {
  const DimmerDetailPage({super.key, required this.device});

  final DeviceEntity device;

  @override
  State<DimmerDetailPage> createState() => _DimmerDetailPageState();
}

class _DimmerDetailPageState extends State<DimmerDetailPage> {
  late final ControlDimmer _control;
  late final SetTimer _timer;
  DimmerStateModel? _state;
  bool _loading = true;
  bool _noIpError = false;
  String? _error;
  int _ramp = 500;
  int _value = 50;

  @override
  void initState() {
    super.initState();
    _control = ControlDimmer(
      DeviceRemoteDataSource(DeviceHttpClient(token: widget.device.token)),
    );
    _timer = SetTimer(
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
      final s = await _control.getState(widget.device.bestIp!);
      if (!mounted) return;
      setState(() {
        _state = s;
        _value = s.value;
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

  void _showTimerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: TimerControls(
          onSet: (mode, seconds) async {
            if (widget.device.bestIp == null) return;
            final timerSetMsg = AppLocalizations.of(context).timerSet;
            try {
              await _timer(widget.device.bestIp!, mode: mode, seconds: seconds);
              if (!mounted) return;
              _snack(timerSetMsg);
            } catch (e) {
              if (!mounted) return;
              _snack(e.toString());
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final on = _state?.on ?? false;
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
            SwitchListTile(
              key: const Key('dimmer_on_switch'),
              title: Text(l10n.on),
              value: on,
              onChanged: widget.device.lockable
                  ? null
                  : (v) async {
                      if (widget.device.bestIp == null) return;
                      try {
                        if (v) {
                          await _control.turnOn(
                            widget.device.bestIp!,
                            ramp: _ramp,
                          );
                        } else {
                          await _control.turnOff(
                            widget.device.bestIp!,
                            ramp: _ramp,
                          );
                        }
                        setState(() => _state = _state?.copyWith(on: v));
                      } catch (e) {
                        _snack(e.toString());
                      }
                    },
            ),
            Row(
              children: [
                Text(l10n.ramp),
                Expanded(
                  child: Slider(
                    key: const Key('dimmer_ramp_slider'),
                    min: 0,
                    max: 15000,
                    value: _ramp.toDouble().clamp(0, 15000),
                    label: l10n.rampSeconds(
                      formatDecimal(context, _ramp / 1000, 1),
                    ),
                    onChanged: (v) => setState(() => _ramp = v.round()),
                  ),
                ),
                Text(l10n.rampSeconds(formatDecimal(context, _ramp / 1000, 1))),
              ],
            ),
            Text(l10n.brightnessPercent('$_value')),
            Slider(
              key: const Key('dimmer_value_slider'),
              min: 0,
              max: 100,
              value: _value.toDouble(),
              onChanged: (v) => setState(() => _value = v.round()),
              onChangeEnd: (v) async {
                if (widget.device.bestIp == null) return;
                try {
                  await _control.setValue(
                    widget.device.bestIp!,
                    value: v.round(),
                    ramp: _ramp,
                  );
                } catch (e) {
                  _snack(e.toString());
                }
              },
            ),
            const SizedBox(height: 16),
            // ---- Feature tiles: Timer / Scheduler (big round tiles) ----
            FeatureTilesRow(
              device: widget.device,
              onTimer: () => _showTimerSheet(context),
              onScheduler: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SchedulerPage(device: widget.device),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
