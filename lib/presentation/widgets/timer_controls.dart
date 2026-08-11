import 'package:flutter/material.dart';

/// Reusable timer controls shown in a bottom sheet.
///
/// Mode selector (none/on/off/toggle) + duration (H/M/S) + Set button.
class TimerControls extends StatefulWidget {
  const TimerControls({super.key, required this.onSet});

  final Future<void> Function(String mode, int seconds) onSet;

  @override
  State<TimerControls> createState() => _TimerControlsState();
}

class _TimerControlsState extends State<TimerControls> {
  String _mode = 'off';
  int _hours = 0;
  int _minutes = 5;
  int _seconds = 0;

  int get _totalSeconds => _hours * 3600 + _minutes * 60 + _seconds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DropdownButton<String>(
              key: const Key('timer_mode_dropdown'),
              value: _mode,
              items: const [
                DropdownMenuItem(value: 'none', child: Text('None')),
                DropdownMenuItem(value: 'on', child: Text('On')),
                DropdownMenuItem(value: 'off', child: Text('Off')),
                DropdownMenuItem(value: 'toggle', child: Text('Toggle')),
              ],
              onChanged: (v) => setState(() => _mode = v ?? 'off'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Duration: ${_hours.toString().padLeft(2, '0')}:'
                '${_minutes.toString().padLeft(2, '0')}:'
                '${_seconds.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTimeSelector(
                label: 'H',
                value: _hours,
                max: 23,
                onChanged: (value) => setState(() => _hours = value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimeSelector(
                label: 'M',
                value: _minutes,
                max: 59,
                onChanged: (value) => setState(() => _minutes = value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimeSelector(
                label: 'S',
                value: _seconds,
                max: 59,
                onChanged: (value) => setState(() => _seconds = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton(
              key: const Key('timer_set_button'),
              onPressed: _totalSeconds > 0
                  ? () => widget.onSet(_mode, _totalSeconds)
                  : null,
              child: const Text('Set'),
            ),
            const SizedBox(width: 12),
            Text('${_totalSeconds}s'),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        DropdownButton<int>(
          value: value,
          items: [
            for (var i = 0; i <= max; i++)
              DropdownMenuItem(
                value: i,
                child: Text(i.toString().padLeft(2, '0')),
              ),
          ],
          onChanged: (v) => onChanged(v ?? 0),
        ),
      ],
    );
  }
}
