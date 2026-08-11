import 'dart:async';

import 'package:flutter/material.dart';

/// Simple HSV color picker for strip/bulb control.
///
/// Produces a color string in `H;S;V` format (0-360, 0-100, 0-100).
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
    _hue = widget.initialHue;
    _sat = widget.initialSaturation;
    _val = widget.initialValue;
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
        Text('Hue: ${_hue.round()}°'),
        Slider(
          min: 0,
          max: 360,
          value: _hue,
          onChanged: (v) {
            setState(() => _hue = v);
            _scheduleEmit();
          },
        ),
        Text('Saturation: ${_sat.round()}%'),
        Slider(
          min: 0,
          max: 100,
          value: _sat,
          onChanged: (v) {
            setState(() => _sat = v);
            _scheduleEmit();
          },
        ),
        Text('Brightness: ${_val.round()}%'),
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
