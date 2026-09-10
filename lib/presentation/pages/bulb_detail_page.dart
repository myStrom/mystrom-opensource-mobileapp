import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/device_http_client.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/bulb_state.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/control_bulb.dart';
import '../../domain/usecases/set_timer.dart';
import '../../l10n/app_localizations.dart';
import '../utils/hsv_utils.dart';
import '../utils/number_format.dart';
import '../widgets/color_picker_widget.dart';
import '../widgets/feature_tiles_row.dart';
import '../widgets/timer_controls.dart';
import 'device_settings_page.dart';

/// Bulb control page.
///
/// Supports three color modes shown as tabs:
/// - **Color** (hsv): Hue;Saturation;Value (0-359;0-100;0-100)
/// - **Whites** (mono): Cold/warm white channel + brightness
/// - **WRGB** (rgb): Four sliders for Warm White, Red, Green, Blue (0-255)
///
/// The active tab reflects the mode reported by the device. If the mode
/// is changed externally, the next refresh will switch tabs accordingly.
class BulbDetailPage extends StatefulWidget {
  const BulbDetailPage({super.key, required this.device});

  final DeviceEntity device;

  @override
  State<BulbDetailPage> createState() => _BulbDetailPageState();
}

class _BulbDetailPageState extends State<BulbDetailPage>
    with SingleTickerProviderStateMixin {
  late final ControlBulb _control;
  late final SetTimer _timer;
  late final TabController _tabController;
  BulbStateModel? _state;
  bool _loading = true;
  bool _noIpError = false;
  String? _error;
  int _ramp = 500;

  // Whites (mono) fields
  int _whitesIndex = 1;
  int _whitesBrightness = 100;
  Timer? _whitesDebounce;

  // WRGB fields
  int _wrgbW = 0;
  int _wrgbR = 0;
  int _wrgbG = 0;
  int _wrgbB = 0;
  Timer? _wrgbDebounce;

  // Tab order: Color (hsv) → Whites (mono) → WRGB (rgb)
  static const _modes = ['hsv', 'mono', 'rgb'];
  bool _switchingTab = false;

  @override
  void initState() {
    super.initState();
    _control = ControlBulb(
      DeviceRemoteDataSource(DeviceHttpClient(token: widget.device.token)),
    );
    _timer = SetTimer(
      DeviceRemoteDataSource(DeviceHttpClient(token: widget.device.token)),
    );
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _refresh();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _whitesDebounce?.cancel();
    _wrgbDebounce?.cancel();
    super.dispose();
  }

  /// Send mode-only request when user switches tabs manually,
  /// then refresh state so values for the new mode are populated.
  void _onTabChanged() {
    if (_switchingTab || _tabController.indexIsChanging) return;
    if (widget.device.bestIp == null) return;
    final newMode = _modes[_tabController.index];
    final currentMode = _state?.mode ?? '';
    if (newMode == currentMode) return;
    _control
        .setMode(widget.device.bestIp!, mode: newMode)
        .then((_) {
          if (!mounted) return;
          setState(() => _state = _state?.copyWith(mode: newMode));
          // Fetch fresh state so the new tab shows the device's actual values.
          _refresh();
        })
        .catchError((e) {
          _snack(e.toString());
          return null;
        });
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
        _loading = false;
        // Sync tab to device's current mode
        final modeIndex = _modes.indexOf(s.mode);
        if (modeIndex >= 0 && modeIndex != _tabController.index) {
          _switchingTab = true;
          _tabController.animateTo(modeIndex);
          _switchingTab = false;
        }
        // Populate mode-specific fields from current color
        _populateFieldsFromState(s);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _populateFieldsFromState(BulbStateModel s) {
    switch (s.mode) {
      case 'hsv':
        // ColorPickerWidget reads initial values via ValueKey rebuild
        break;
      case 'mono':
        final parts = s.color.split(';');
        if (parts.length == 2) {
          _whitesIndex = int.tryParse(parts[0]) ?? 0;
          _whitesBrightness = int.tryParse(parts[1]) ?? 100;
        }
        break;
      case 'rgb':
        // Parse WWRRGGBB hex (8 chars)
        if (s.color.length == 8) {
          _wrgbW = int.tryParse(s.color.substring(0, 2), radix: 16) ?? 0;
          _wrgbR = int.tryParse(s.color.substring(2, 4), radix: 16) ?? 0;
          _wrgbG = int.tryParse(s.color.substring(4, 6), radix: 16) ?? 0;
          _wrgbB = int.tryParse(s.color.substring(6, 8), radix: 16) ?? 0;
        }
        break;
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _sendColor(String color, String mode) async {
    if (widget.device.bestIp == null) return;
    try {
      await _control.setColor(
        widget.device.bestIp!,
        color: color,
        mode: mode,
        ramp: _ramp,
      );
      setState(
        () => _state = _state?.copyWith(color: color, mode: mode, on: true),
      );
    } catch (e) {
      _snack(e.toString());
    }
  }

  /// Schedule a whites update after debounce.
  void _scheduleWhitesUpdate() {
    _whitesDebounce?.cancel();
    _whitesDebounce = Timer(const Duration(milliseconds: 400), () {
      _sendColor('$_whitesIndex;$_whitesBrightness', 'mono');
    });
  }

  /// Schedule a WRGB update after debounce.
  void _scheduleWrgbUpdate() {
    _wrgbDebounce?.cancel();
    _wrgbDebounce = Timer(const Duration(milliseconds: 400), () {
      final hex =
          _wrgbW.toRadixString(16).padLeft(2, '0').toUpperCase() +
          _wrgbR.toRadixString(16).padLeft(2, '0').toUpperCase() +
          _wrgbG.toRadixString(16).padLeft(2, '0').toUpperCase() +
          _wrgbB.toRadixString(16).padLeft(2, '0').toUpperCase();
      _sendColor(hex, 'rgb');
    });
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
              await _timer(
                widget.device.bestIp!,
                mode: mode,
                seconds: seconds,
                path: ApiEndpoints.bulbTimer,
              );
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
    final currentMode = _state?.mode ?? 'hsv';
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
            key: const Key('bulb_settings_button'),
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
              key: const Key('bulb_on_switch'),
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
                    key: const Key('bulb_ramp_slider'),
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
            const SizedBox(height: 16),
            // ---- Feature tiles: Timer (big round tile) ----
            FeatureTilesRow(
              device: widget.device,
              onTimer: () => _showTimerSheet(context),
            ),
            const SizedBox(height: 8),
            // Show current mode reported by device
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.deviceMode(
                  currentMode.isNotEmpty ? currentMode : l10n.unknown,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(key: const Key('bulb_tab_color'), text: l10n.tabColor),
                Tab(key: const Key('bulb_tab_whites'), text: l10n.tabWhites),
                Tab(key: const Key('bulb_tab_wrgb'), text: l10n.tabWrgb),
              ],
            ),
            const SizedBox(height: 8),
            // TabBarView needs a bounded height inside ListView
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildColorTab(l10n),
                  _buildWhitesTab(l10n),
                  _buildWrgbTab(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Color (HSV) tab ----
  Widget _buildColorTab(AppLocalizations l10n) {
    return Column(
      children: [
        Text(l10n.colorHsv),
        const SizedBox(height: 8),
        ColorPickerWidget(
          key: ValueKey('bulb-hsv-${_state?.color}'),
          initialHue: _parseHue(_state?.color),
          initialSaturation: _parseSat(_state?.color),
          initialValue: _parseVal(_state?.color),
          onColorChanged: (color) => _sendColor(color, 'hsv'),
        ),
      ],
    );
  }

  // ---- Whites (cold/warm) tab ----
  Widget _buildWhitesTab(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.whitesColdWarm),
        const SizedBox(height: 8),
        Text(l10n.whiteIndex('$_whitesIndex')),
        Slider(
          key: const Key('bulb_whites_white'),
          min: 1,
          max: 18,
          divisions: 17,
          value: _whitesIndex.toDouble().clamp(1, 18),
          label: '$_whitesIndex',
          onChanged: (v) => setState(() => _whitesIndex = v.round()),
          onChangeEnd: (_) => _scheduleWhitesUpdate(),
        ),
        const SizedBox(height: 8),
        Text(l10n.brightnessPercent('$_whitesBrightness')),
        Slider(
          key: const Key('bulb_whites_brightness'),
          min: 0,
          max: 100,
          value: _whitesBrightness.toDouble(),
          label: '$_whitesBrightness%',
          onChanged: (v) => setState(() => _whitesBrightness = v.round()),
          onChangeEnd: (_) => _scheduleWhitesUpdate(),
        ),
      ],
    );
  }

  // ---- WRGB sliders tab ----
  Widget _buildWrgbTab(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.tabWrgb),
        const SizedBox(height: 8),
        _wrgbSlider(
          l10n.colorWhite,
          _wrgbW,
          Colors.amber,
          (v) {
            setState(() => _wrgbW = v.round());
          },
          () => _scheduleWrgbUpdate(),
          sliderKey: const Key('bulb_wrgb_white'),
          l10n: l10n,
        ),
        _wrgbSlider(
          l10n.colorRed,
          _wrgbR,
          Colors.red,
          (v) {
            setState(() => _wrgbR = v.round());
          },
          () => _scheduleWrgbUpdate(),
          sliderKey: const Key('bulb_wrgb_red'),
          l10n: l10n,
        ),
        _wrgbSlider(
          l10n.colorGreen,
          _wrgbG,
          Colors.green,
          (v) {
            setState(() => _wrgbG = v.round());
          },
          () => _scheduleWrgbUpdate(),
          sliderKey: const Key('bulb_wrgb_green'),
          l10n: l10n,
        ),
        _wrgbSlider(
          l10n.colorBlue,
          _wrgbB,
          Colors.blue,
          (v) {
            setState(() => _wrgbB = v.round());
          },
          () => _scheduleWrgbUpdate(),
          sliderKey: const Key('bulb_wrgb_blue'),
          l10n: l10n,
        ),
      ],
    );
  }

  Widget _wrgbSlider(
    String label,
    int value,
    Color color,
    ValueChanged<double> onChanged,
    VoidCallback onChangeEnd, {
    Key? sliderKey,
    required AppLocalizations l10n,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.circle, color: color, size: 16),
            const SizedBox(width: 8),
            Text(l10n.labelValue(label, '$value')),
          ],
        ),
        Slider(
          key: sliderKey,
          min: 0,
          max: 255,
          value: value.toDouble(),
          label: '$value',
          activeColor: color,
          onChanged: onChanged,
          onChangeEnd: (_) => onChangeEnd(),
        ),
      ],
    );
  }

  /// Parse hue from HSV string "H;S;V". Defaults to 0 (red).
  /// Clamped to 0-359: myStrom firmware treats 360 as invalid hue.
  static double _parseHue(String? color) {
    if (color == null || color.isEmpty) return 0;
    final parts = color.split(';');
    if (parts.isNotEmpty) {
      final h = double.tryParse(parts[0]);
      if (h != null) return h.clamp(0, maxHue.toDouble());
    }
    return 0;
  }

  /// Parse saturation from HSV string "H;S;V". Defaults to 100.
  static double _parseSat(String? color) {
    if (color == null || color.isEmpty) return 100;
    final parts = color.split(';');
    if (parts.length >= 2) {
      final s = double.tryParse(parts[1]);
      if (s != null) return s.clamp(0, 100);
    }
    return 100;
  }

  /// Parse value/brightness from HSV string "H;S;V". Defaults to 100.
  static double _parseVal(String? color) {
    if (color == null || color.isEmpty) return 100;
    final parts = color.split(';');
    if (parts.length >= 3) {
      final v = double.tryParse(parts[2]);
      if (v != null) return v.clamp(0, 100);
    }
    return 100;
  }
}
