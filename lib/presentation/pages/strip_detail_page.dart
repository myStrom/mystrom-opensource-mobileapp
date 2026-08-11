import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/device_http_client.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/strip_state.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/control_strip.dart';
import '../../domain/usecases/set_timer.dart';
import '../widgets/color_picker_widget.dart';
import '../widgets/feature_tiles_row.dart';
import '../widgets/timer_controls.dart';
import 'device_settings_page.dart';
import 'scheduler_page.dart';

/// LED strip control page (WRS).
///
/// The control UI adapts to the strip's channel mode:
/// - **colors**: WRGB strip — Color (HSV) tab + WRGB sliders tab
/// - **channels**: 4 independent dimmable channels — 4 sliders
/// - **cold_warm**: 2 warm + 2 cold white — warm/cold slider pair
class StripDetailPage extends StatefulWidget {
  const StripDetailPage({super.key, required this.device});

  final DeviceEntity device;

  @override
  State<StripDetailPage> createState() => _StripDetailPageState();
}

class _StripDetailPageState extends State<StripDetailPage>
    with SingleTickerProviderStateMixin {
  late final ControlStrip _control;
  late final SetTimer _timer;
  late final TabController _tabController;
  StripStateModel? _state;
  bool _loading = true;
  String? _error;
  int _ramp = 500;

  // WRGB fields
  int _wrgbW = 0;
  int _wrgbR = 0;
  int _wrgbG = 0;
  int _wrgbB = 0;
  Timer? _wrgbDebounce;

  // Channels fields (4 independent channels)
  int _ch0 = 0;
  int _ch1 = 0;
  int _ch2 = 0;
  int _ch3 = 0;
  Timer? _channelsDebounce;

  // Cold/warm fields
  int _warmVal = 0;
  int _coldVal = 0;
  Timer? _cwDebounce;

  // Whites (mono) fields
  int _whitesIndex = 1;
  int _whitesBrightness = 100;
  Timer? _whitesDebounce;

  // Tab order for colors mode: Color (hsv) → Whites (mono) → WRGB (rgb)
  static const _colorModes = ['hsv', 'mono', 'rgb'];
  bool _switchingTab = false;

  @override
  void initState() {
    super.initState();
    _control = ControlStrip(
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
    _wrgbDebounce?.cancel();
    _channelsDebounce?.cancel();
    _cwDebounce?.cancel();
    _whitesDebounce?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (_switchingTab || _tabController.indexIsChanging) return;
    if (widget.device.bestIp == null) return;
    final chMode = _state?.chMode ?? 'colors';
    if (chMode != 'colors') return;
    final newMode = _colorModes[_tabController.index];
    final currentMode = _state?.mode ?? '';
    if (newMode == currentMode) return;
    _control
        .setStripMode(widget.device.bestIp!, mode: newMode)
        .then((_) {
          if (!mounted) return;
          setState(() => _state = _state?.copyWith(mode: newMode));
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
        _populateFieldsFromState(s);
        if (s.chMode == 'colors') {
          final modeIndex = _colorModes.indexOf(s.mode);
          if (modeIndex >= 0 && modeIndex != _tabController.index) {
            _switchingTab = true;
            _tabController.animateTo(modeIndex);
            _switchingTab = false;
          }
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _populateFieldsFromState(StripStateModel s) {
    if (s.mode == 'rgb' && s.color.length == 8) {
      _wrgbW = int.tryParse(s.color.substring(0, 2), radix: 16) ?? 0;
      _wrgbR = int.tryParse(s.color.substring(2, 4), radix: 16) ?? 0;
      _wrgbG = int.tryParse(s.color.substring(4, 6), radix: 16) ?? 0;
      _wrgbB = int.tryParse(s.color.substring(6, 8), radix: 16) ?? 0;
    }
    if (s.chMode == 'channels' && s.mode == 'rgb' && s.color.length == 8) {
      _ch0 = _wrgbW;
      _ch1 = _wrgbR;
      _ch2 = _wrgbG;
      _ch3 = _wrgbB;
    }
    if (s.chMode == 'cold_warm' && s.mode == 'rgb' && s.color.length == 8) {
      // W+R = warm, G+B = cold. Take R as warm, B as cold.
      _warmVal = int.tryParse(s.color.substring(2, 4), radix: 16) ?? 0;
      _coldVal = int.tryParse(s.color.substring(6, 8), radix: 16) ?? 0;
    }
    if (s.mode == 'mono') {
      final parts = s.color.split(';');
      if (parts.length == 2) {
        _whitesIndex = int.tryParse(parts[0]) ?? 0;
        _whitesBrightness = int.tryParse(parts[1]) ?? 100;
      }
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
            try {
              await _timer(widget.device.bestIp!, mode: mode, seconds: seconds);
              _snack('Timer set');
            } catch (e) {
              _snack(e.toString());
            }
          },
        ),
      ),
    );
  }

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

  void _scheduleWrgbUpdate() {
    _wrgbDebounce?.cancel();
    _wrgbDebounce = Timer(const Duration(milliseconds: 400), () {
      final hex =
          _toHex2(_wrgbW) + _toHex2(_wrgbR) + _toHex2(_wrgbG) + _toHex2(_wrgbB);
      _sendColor(hex, 'rgb');
    });
  }

  void _scheduleChannelsUpdate() {
    _channelsDebounce?.cancel();
    _channelsDebounce = Timer(const Duration(milliseconds: 400), () {
      final hex = _toHex2(_ch0) + _toHex2(_ch1) + _toHex2(_ch2) + _toHex2(_ch3);
      _sendColor(hex, 'rgb');
    });
  }

  void _scheduleColdWarmUpdate() {
    _cwDebounce?.cancel();
    _cwDebounce = Timer(const Duration(milliseconds: 400), () {
      // W+R = warm, G+B = cold
      final hex =
          _toHex2(_warmVal) +
          _toHex2(_warmVal) +
          _toHex2(_coldVal) +
          _toHex2(_coldVal);
      _sendColor(hex, 'rgb');
    });
  }

  void _scheduleWhitesUpdate() {
    _whitesDebounce?.cancel();
    _whitesDebounce = Timer(const Duration(milliseconds: 400), () {
      _sendColor('$_whitesIndex;$_whitesBrightness', 'mono');
    });
  }

  static String _toHex2(int v) =>
      v.clamp(0, 255).toRadixString(16).padLeft(2, '0').toUpperCase();

  static double _parseHue(String? color) {
    if (color == null || color.isEmpty) return 0;
    final parts = color.split(';');
    if (parts.isNotEmpty) {
      final h = double.tryParse(parts[0]);
      if (h != null) return h.clamp(0, 360);
    }
    return 0;
  }

  static double _parseSat(String? color) {
    if (color == null || color.isEmpty) return 100;
    final parts = color.split(';');
    if (parts.length >= 2) {
      final s = double.tryParse(parts[1]);
      if (s != null) return s.clamp(0, 100);
    }
    return 100;
  }

  static double _parseVal(String? color) {
    if (color == null || color.isEmpty) return 100;
    final parts = color.split(';');
    if (parts.length >= 3) {
      final v = double.tryParse(parts[2]);
      if (v != null) return v.clamp(0, 100);
    }
    return 100;
  }

  @override
  Widget build(BuildContext context) {
    final on = _state?.on ?? false;
    final chMode = _state?.chMode ?? 'colors';
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
            key: const Key('strip_settings_button'),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Mode: $chMode',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            SwitchListTile(
              key: const Key('strip_on_switch'),
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
            const SizedBox(height: 16),
            switch (chMode) {
              'colors' => _buildColorsUI(),
              'channels' => _buildChannelsUI(),
              'cold_warm' => _buildColdWarmUI(),
              _ => _buildColorsUI(),
            },
          ],
        ),
      ),
    );
  }

  // ---- colors mode: tabs Color (HSV) + WRGB ----
  Widget _buildColorsUI() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(key: Key('strip_tab_color'), text: 'Color'),
            Tab(key: Key('strip_tab_whites'), text: 'Whites'),
            Tab(key: Key('strip_tab_wrgb'), text: 'WRGB'),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 380,
          child: TabBarView(
            controller: _tabController,
            children: [_buildColorTab(), _buildWhitesTab(), _buildWrgbTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildColorTab() {
    return Column(
      children: [
        const Text('Color (HSV)'),
        const SizedBox(height: 8),
        ColorPickerWidget(
          key: ValueKey('strip-hsv-${_state?.color}'),
          initialHue: _parseHue(_state?.color),
          initialSaturation: _parseSat(_state?.color),
          initialValue: _parseVal(_state?.color),
          onColorChanged: (color) => _sendColor(color, 'hsv'),
        ),
      ],
    );
  }

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
          sliderKey: const Key('strip_wrgb_white'),
        ),
        _wrgbSlider(
          'Red',
          _wrgbR,
          Colors.red,
          (v) {
            setState(() => _wrgbR = v.round());
          },
          () => _scheduleWrgbUpdate(),
          sliderKey: const Key('strip_wrgb_red'),
        ),
        _wrgbSlider(
          'Green',
          _wrgbG,
          Colors.green,
          (v) {
            setState(() => _wrgbG = v.round());
          },
          () => _scheduleWrgbUpdate(),
          sliderKey: const Key('strip_wrgb_green'),
        ),
        _wrgbSlider(
          'Blue',
          _wrgbB,
          Colors.blue,
          (v) {
            setState(() => _wrgbB = v.round());
          },
          () => _scheduleWrgbUpdate(),
          sliderKey: const Key('strip_wrgb_blue'),
        ),
      ],
    );
  }

  // ---- Whites (mono) tab ----
  Widget _buildWhitesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Whites'),
        const SizedBox(height: 4),
        const Text(
          'The device internally converts warmth to WRGB values.',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text('White: $_whitesIndex'),
        Slider(
          key: const Key('strip_whites_white'),
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
          key: const Key('strip_whites_brightness'),
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

  // ---- channels mode: 4 independent sliders ----
  Widget _buildChannelsUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Channels'),
        const SizedBox(height: 8),
        _wrgbSlider(
          'Channel 1',
          _ch0,
          Colors.amber,
          (v) {
            setState(() => _ch0 = v.round());
          },
          () => _scheduleChannelsUpdate(),
          sliderKey: const Key('strip_channel_1'),
        ),
        _wrgbSlider(
          'Channel 2',
          _ch1,
          Colors.red,
          (v) {
            setState(() => _ch1 = v.round());
          },
          () => _scheduleChannelsUpdate(),
          sliderKey: const Key('strip_channel_2'),
        ),
        _wrgbSlider(
          'Channel 3',
          _ch2,
          Colors.green,
          (v) {
            setState(() => _ch2 = v.round());
          },
          () => _scheduleChannelsUpdate(),
          sliderKey: const Key('strip_channel_3'),
        ),
        _wrgbSlider(
          'Channel 4',
          _ch3,
          Colors.blue,
          (v) {
            setState(() => _ch3 = v.round());
          },
          () => _scheduleChannelsUpdate(),
          sliderKey: const Key('strip_channel_4'),
        ),
      ],
    );
  }

  // ---- cold_warm mode: warm + cold sliders ----
  Widget _buildColdWarmUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cold / Warm'),
        const SizedBox(height: 8),
        _wrgbSlider(
          'Warm',
          _warmVal,
          Colors.orange,
          (v) {
            setState(() => _warmVal = v.round());
          },
          () => _scheduleColdWarmUpdate(),
          sliderKey: const Key('strip_warm'),
        ),
        _wrgbSlider(
          'Cold',
          _coldVal,
          Colors.lightBlue,
          (v) {
            setState(() => _coldVal = v.round());
          },
          () => _scheduleColdWarmUpdate(),
          sliderKey: const Key('strip_cold'),
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
}
