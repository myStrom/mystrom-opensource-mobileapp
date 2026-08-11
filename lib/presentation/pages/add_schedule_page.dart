import 'package:flutter/material.dart';

import '../../core/utils/scheduler_time.dart';
import '../../data/models/scheduler_item.dart';
import '../widgets/analog_time_picker.dart';

/// Full-page "add schedule entry" editor.
///
/// Layout (top to bottom):
/// 1. Action selector: on / off / toggle.
/// 2. Large analog clock with two draggable hands (hour = short, minute =
///    long 2×). The current HH:MM is shown above the dial.
/// 3. Weekday picker.
/// 4. Variant fields (color / ramp / value) when applicable.
class AddSchedulePage extends StatefulWidget {
  const AddSchedulePage({
    super.key,
    required this.hasColor,
    required this.hasRamp,
    required this.hasValue,
  });

  final bool hasColor;
  final bool hasRamp;
  final bool hasValue;

  @override
  State<AddSchedulePage> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends State<AddSchedulePage> {
  int _hour = 8;
  int _minute = 0;
  String _action = 'on';
  late Set<String> _days;

  final _colorCtrl = TextEditingController();
  final _rampCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();

  static const _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    _days = SchedulerTimeConverter.dayNames.toSet();
  }

  @override
  void dispose() {
    _colorCtrl.dispose();
    _rampCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    // Parse HSV string "H;S;V" into a map for the new scheduler API.
    String? mode;
    Map<String, dynamic>? hsv;
    if (widget.hasColor && _colorCtrl.text.isNotEmpty) {
      final parts = _colorCtrl.text.split(';');
      if (parts.length == 3) {
        mode = 'hsv';
        hsv = {
          'hue': int.tryParse(parts[0]) ?? 0,
          'saturation': int.tryParse(parts[1]) ?? 100,
          'value': int.tryParse(parts[2]) ?? 100,
        };
      }
    }
    final item = SchedulerItem(
      enable: true,
      hour: _hour.clamp(0, 23),
      minute: _minute.clamp(0, 59),
      action: _action,
      days: SchedulerTimeConverter.dayNames.where(_days.contains).toList(),
      mode: mode,
      hsv: hsv,
      ramp: widget.hasRamp && _rampCtrl.text.isNotEmpty
          ? int.tryParse(_rampCtrl.text)
          : null,
      value: widget.hasValue && _valueCtrl.text.isNotEmpty
          ? int.tryParse(_valueCtrl.text)
          : null,
    );
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('add_schedule_back_button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add schedule'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // ---- Action selector ----
          const Text('Action', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final a in [
                'on',
                'off',
                'toggle',
                if (widget.hasColor) 'set',
              ])
                ChoiceChip(
                  key: Key('schedule_action_chip_$a'),
                  label: Text(a == 'set' ? 'set (color only)' : a),
                  selected: _action == a,
                  onSelected: (_) => setState(() => _action = a),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ---- Analog clock ----
          Center(
            child: AnalogTimePicker(
              key: const Key('schedule_clock'),
              hour: _hour,
              minute: _minute,
              onChanged: (t) => setState(() {
                _hour = t.hour;
                _minute = t.minute;
              }),
            ),
          ),
          const SizedBox(height: 24),

          // ---- Days of week ----
          const Text('Days', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (var i = 0; i < 7; i++)
                FilterChip(
                  key: Key('schedule_day_chip_$i'),
                  label: Text(_dayLabels[i]),
                  selected: _days.contains(SchedulerTimeConverter.dayNames[i]),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _days.add(SchedulerTimeConverter.dayNames[i]);
                      } else {
                        _days.remove(SchedulerTimeConverter.dayNames[i]);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ---- Variant fields ----
          if (widget.hasColor || widget.hasRamp || widget.hasValue) ...[
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (widget.hasColor)
                  SizedBox(
                    width: 140,
                    child: TextField(
                      key: const Key('schedule_color_field'),
                      controller: _colorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Color (HSV)',
                        hintText: '360;100;100',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                if (widget.hasRamp)
                  SizedBox(
                    width: 120,
                    child: TextField(
                      key: const Key('schedule_ramp_field'),
                      controller: _rampCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ramp (ms)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                if (widget.hasValue)
                  SizedBox(
                    width: 100,
                    child: TextField(
                      key: const Key('schedule_value_field'),
                      controller: _valueCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Value %',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('schedule_add_button'),
        onPressed: _submit,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}
