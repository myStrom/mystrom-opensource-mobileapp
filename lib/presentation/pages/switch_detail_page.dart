import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/device_http_client.dart';
import '../../core/utils/device_type.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/switch_state.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/control_switch.dart';
import '../../domain/usecases/set_timer.dart';
import '../../l10n/app_localizations.dart';
import '../providers/device_provider.dart';
import '../utils/device_type_l10n.dart';
import '../utils/number_format.dart';
import '../widgets/feature_tiles_row.dart';
import '../widgets/timer_controls.dart';
import 'device_settings_page.dart';
import 'history_page.dart';
import 'scheduler_page.dart';

/// Switch / plug control page (WS2, WSE, WSX, LCS).
class SwitchDetailPage extends StatefulWidget {
  const SwitchDetailPage({super.key, required this.device});

  final DeviceEntity device;

  @override
  State<SwitchDetailPage> createState() => _SwitchDetailPageState();
}

class _SwitchDetailPageState extends State<SwitchDetailPage> {
  late final ControlSwitch _control;
  late final SetTimer _timer;
  late final DeviceRemoteDataSource _remote;
  SwitchStateModel? _state;
  bool _loading = true;
  bool _noIpError = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _remote = DeviceRemoteDataSource(
      DeviceHttpClient(token: widget.device.token),
    );
    _control = ControlSwitch(_remote);
    _timer = SetTimer(_remote);
    _refresh();
  }

  @override
  void dispose() {
    super.dispose();
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
      final report = await _control.getReport(widget.device.bestIp!);
      if (!mounted) return;
      setState(() {
        _state = report;
        _loading = false;
      });
      // Fold the fresh report's energy into the persistent accumulator.
      context.read<DeviceProvider>().accumulateEnergy(
        widget.device.mac,
        report,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _setRelay(bool on) async {
    if (widget.device.lockable) {
      _snack(AppLocalizations.of(context).deviceLockedToggleDisabled);
      return;
    }
    if (widget.device.bestIp == null) return;
    try {
      final s = on
          ? await _control.turnOn(widget.device.bestIp!)
          : await _control.turnOff(widget.device.bestIp!);
      if (!mounted) return;
      setState(() => _state = _state?.copyWith(relay: s.relay) ?? s);
    } catch (e) {
      _snack(e.toString());
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final relay = _state?.relay ?? false;
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
            key: const Key('detail_settings_button'),
            icon: const Icon(Icons.settings_outlined),
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
            // ---- Device header (icon + name + room) ----
            _DeviceHeader(device: widget.device),
            const SizedBox(height: 16),

            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_noIpError || _error != null)
              Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_noIpError ? l10n.noIpAddress : _error!),
                ),
              ),

            // ---- Power card ----
            if (!_loading && !_noIpError && _error == null) ...[
              _PowerCard(
                key: const Key('switch_power_card'),
                active: relay,
                lockable: widget.device.lockable,
                onToggle: _setRelay,
                sensorText: [
                  if (_state?.power != null)
                    l10n.powerWatts(formatDecimal(context, _state!.power!, 1)),
                  if (_state?.temperature != null)
                    l10n.temperatureCelsius(
                      formatDecimal(
                        context,
                        _state!.temperature! + widget.device.temperatureOffset,
                        1,
                      ),
                    ),
                ].join(' • '),
              ),
              const SizedBox(height: 16),
            ],

            // ---- Feature tiles: Timer / Scheduler (big round tiles) ----
            if (!_loading && !_noIpError && _error == null) ...[
              FeatureTilesRow(
                device: widget.device,
                onTimer: () => _showTimerSheet(context),
                onScheduler: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SchedulerPage(device: widget.device),
                  ),
                ),
                onHistory: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryPage(device: widget.device),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ---- Energy details ----
            // Energy is reported in watt-seconds (Ws); convert to kWh.
            // The persistent accumulator (DeviceProvider) folds per-boot
            // counters across reboots. Display total = accumulated total
            // + current boot, plus the current-boot-only value.
            Builder(
              builder: (context) {
                final d = context.watch<DeviceProvider>().devices.firstWhere(
                  (e) => e.mac == widget.device.mac,
                  orElse: () => widget.device,
                );
                final totalWs = d.totalEnergyWs + d.bootEnergyWs;
                if (totalWs <= 0 && d.bootEnergyWs <= 0) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.bar_chart),
                      title: Text(l10n.totalEnergy),
                      trailing: Text(
                        l10n.energyKwh(
                          formatDecimal(context, totalWs / 3600000, 3),
                        ),
                      ),
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.restart_alt, size: 20),
                      title: Text(l10n.sinceBoot),
                      trailing: Text(
                        l10n.energyKwh(
                          formatDecimal(context, d.bootEnergyWs / 3600000, 3),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

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
}

/// Large header: device icon on the left, name + room on the right.
class _DeviceHeader extends StatelessWidget {
  const _DeviceHeader({required this.device});
  final DeviceEntity device;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = device.colorValue != null
        ? Color(device.colorValue!)
        : theme.colorScheme.primary;
    return Row(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(_iconFor(device.type), size: 48, color: color),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.displayName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                device.room?.isNotEmpty == true
                    ? device.room!
                    : device.type.localizedName(l10n),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconFor(DeviceType type) {
    if (type.isSwitch) return Icons.power;
    if (type.isStrip) return Icons.lightbulb_outline;
    if (type.isDimmer) return Icons.tune;
    if (type.isBulb) return Icons.lightbulb;
    if (type.isPir) return Icons.sensors;
    if (type.isButton) return Icons.touch_app;
    return Icons.device_unknown;
  }
}

/// Large card with a big round power button.
class _PowerCard extends StatelessWidget {
  const _PowerCard({
    super.key,
    required this.active,
    this.lockable = false,
    required this.onToggle,
    required this.sensorText,
  });

  final bool active;
  final bool lockable;
  final ValueChanged<bool> onToggle;
  final String sensorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final disabled = lockable;
    return Card(
      color: active ? Colors.blue.withValues(alpha: 0.10) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          children: [
            Text(
              l10n.power,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: active
                  ? Colors.blue
                  : theme.colorScheme.surfaceContainerHighest,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: disabled ? null : () => onToggle(!active),
                child: Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  child: Icon(
                    lockable ? Icons.lock : Icons.power_settings_new,
                    size: 48,
                    color: active ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              lockable ? l10n.locked : (active ? l10n.on : l10n.off),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: lockable
                    ? Colors.amber.shade800
                    : (active ? Colors.blue : theme.hintColor),
              ),
            ),
            if (sensorText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                sensorText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
