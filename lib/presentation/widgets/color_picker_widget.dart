import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/hsv_utils.dart';

/// Simple HSV color picker for strip/bulb control.
///
/// Produces a color string in `H;S;V` format (0-359, 0-100, 0-100).
/// Emits color changes with a debounce so we don't flood the device
/// with HTTP requests while dragging sliders.
class ColorPickerWidget extends StatefulWidget {
  const ColorPickerWidget({
    super.key,
    required this.onColorChanged,
    this.initialHue = 0,
    this.initialSaturation = 100,
    this.initialValue = 100,
    this.debounce = const Duration(milliseconds: 400),
  });

  final ValueChanged<String> onColorChanged;
  final double initialHue;
  final double initialSaturation;
  final double initialValue;
  final Duration debounce;

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  late double _hue;
  late double _sat;
  late double _val;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _hue = widget.initialHue.clamp(0, maxHue.toDouble());
    _sat = widget.initialSaturation.clamp(0, 100);
    _val = widget.initialValue.clamp(0, 100);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _scheduleEmit() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () {
      widget.onColorChanged('${_hue.round()};${_sat.round()};${_val.round()}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: HSVColor.fromAHSV(1, _hue, _sat / 100, _val / 100).toColor(),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        Text(l10n.hueValue('${_hue.round()}')),
        Slider(
          min: 0,
          max: maxHue.toDouble(),
          value: _hue.clamp(0, maxHue.toDouble()),
          onChanged: (v) {
            setState(() => _hue = v);
            _scheduleEmit();
          },
        ),
        Text(l10n.saturationValue('${_sat.round()}')),
        Slider(
          min: 0,
          max: 100,
          value: _sat,
          onChanged: (v) {
            setState(() => _sat = v);
            _scheduleEmit();
          },
        ),
        Text(l10n.brightnessPercent('${_val.round()}')),
        Slider(
          min: 0,
          max: 100,
          value: _val,
          onChanged: (v) {
            setState(() => _val = v);
            _scheduleEmit();
          },
        ),
      ],
    );
  }
}
