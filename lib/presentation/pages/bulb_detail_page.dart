import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/device_http_client.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/bulb_state.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/control_bulb.dart';
import '../../domain/usecases/set_timer.dart';
import '../widgets/color_picker_widget.dart';
import '../widgets/feature_tiles_row.dart';
import '../widgets/timer_controls.dart';
import 'device_settings_page.dart';

/// Bulb control page.
///
/// Supports three color modes shown as tabs:
/// - **Color** (hsv): Hue;Saturation;Value (0-360;0-100;0-100)
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
            try {
              await _timer(
                widget.device.bestIp!,
                mode: mode,
                seconds: seconds,
                path: ApiEndpoints.bulbTimer,
              );
              _snack('Timer set');
            } catch (e) {
              _snack(e.toString());
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            SwitchListTile(
              key: const Key('bulb_on_switch'),
              title: const Text('On'),
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
                const Text('Ramp'),
                Expanded(
                  child: Slider(
                    key: const Key('bulb_ramp_slider'),
                    min: 0,
                    max: 15000,
                    value: _ramp.toDouble().clamp(0, 15000),
                    label: '${(_ramp / 1000).toStringAsFixed(1)}s',
                    onChanged: (v) => setState(() => _ramp = v.round()),
                  ),
                ),
                Text('${(_ramp / 1000).toStringAsFixed(1)}s'),
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
                'Device mode: ${currentMode.isNotEmpty ? currentMode : "unknown"}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(key: Key('bulb_tab_color'), text: 'Color'),
                Tab(key: Key('bulb_tab_whites'), text: 'Whites'),
                Tab(key: Key('bulb_tab_wrgb'), text: 'WRGB'),
              ],
            ),
            const SizedBox(height: 8),
            // TabBarView needs a bounded height inside ListView
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildColorTab(),
                  _buildWhitesTab(),
                  _buildWrgbTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Color (HSV) tab ----
  Widget _buildColorTab() {
    return Column(
      children: [
        const Text('Color (HSV)'),
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
  Widget _buildWhitesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Whites (Cold / Warm)'),
        const SizedBox(height: 8),
        Text('White: $_whitesIndex'),
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
        Text('Brightness: $_whitesBrightness%'),
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
  Widget _buildWrgbTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('WRGB'),
        const SizedBox(height: 8),
        _wrgbSlider(
          'White',
          _wrgbW,
          Colors.amber,
          (v) {
            setState(() => _wrgbW = v.round());
          },
          () => _scheduleWrgbUpdate(),
          sliderKey: const Key('bulb_wrgb_white'),
        ),
        _wrgbSlider(
          'Red',
          _wrgbR,
          Colors.red,
          (v) {
            setState(() => _wrgbR = v.round());
          },
          () => _scheduleWrgbUpdate(),
          sliderKey: const Key('bulb_wrgb_red'),
        ),
        _wrgbSlider(
          'Green',
          _wrgbG,
          Colors.green,
          (v) {
            setState(() => _wrgbG = v.round());
          },
          () => _scheduleWrgbUpdate(),
          sliderKey: const Key('bulb_wrgb_green'),
        ),
        _wrgbSlider(
          'Blue',
          _wrgbB,
          Colors.blue,
          (v) {
            setState(() => _wrgbB = v.round());
          },
          () => _scheduleWrgbUpdate(),
          sliderKey: const Key('bulb_wrgb_blue'),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.circle, color: color, size: 16),
            const SizedBox(width: 8),
            Text('$label: $value'),
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
  static double _parseHue(String? color) {
    if (color == null || color.isEmpty) return 0;
    final parts = color.split(';');
    if (parts.isNotEmpty) {
      final h = double.tryParse(parts[0]);
      if (h != null) return h.clamp(0, 360);
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
