import 'package:flutter/material.dart';

import '../../domain/entities/device_entity.dart';
import '../../domain/usecases/configure_button_action.dart';
import '../../l10n/app_localizations.dart';
import '../utils/action_l10n.dart';
import '../utils/hsv_utils.dart';

/// Dialog/widget that lets the user pick a target device and an action,
/// then generates the action URL automatically.
class ActionUrlPicker extends StatefulWidget {
  const ActionUrlPicker({
    super.key,
    required this.devices,
    required this.onUrlGenerated,
  });

  final List<DeviceEntity> devices;
  final ValueChanged<String> onUrlGenerated;

  @override
  State<ActionUrlPicker> createState() => _ActionUrlPickerState();
}

class _ActionUrlPickerState extends State<ActionUrlPicker> {
  DeviceEntity? _target;
  String _action = 'toggle';
  String _color = '120;100;100';
  String _ramp = '500';
  String? _colorError;
  String? _rampError;

  bool _canColor(DeviceEntity? device) =>
      device != null && (device.type.isStrip || device.type.isBulb);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controllable = widget.devices
        .where(
          (d) =>
              d.bestIp != null &&
              (d.type.isSwitch ||
                  d.type.isStrip ||
                  d.type.isDimmer ||
                  d.type.isBulb),
        )
        .toList();

    return AlertDialog(
      title: Text(l10n.assignAction),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controllable.isEmpty) Text(l10n.noActionTargets),
            if (controllable.isNotEmpty)
              DropdownButtonFormField<DeviceEntity>(
                decoration: InputDecoration(labelText: l10n.targetDevice),
                initialValue: _target,
                items: controllable
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(
                          l10n.deviceWithModel(d.displayName, d.type.model),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  _target = v;
                  if (_action == 'color' && !_canColor(v)) _action = 'toggle';
                }),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(_canColor(_target)),
              decoration: InputDecoration(labelText: l10n.action),
              initialValue: _action,
              items: ['toggle', 'on', 'off', if (_canColor(_target)) 'color']
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(localizedActionLabel(l10n, a)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _action = v ?? 'toggle'),
            ),
            if (_action == 'color') ...[
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('action_url_color_field'),
                initialValue: _color,
                decoration: InputDecoration(
                  labelText: l10n.colorHsvShort,
                  hintText: '120;100;100',
                  errorText: _colorError,
                ),
                onChanged: (v) {
                  setState(() {
                    _color = v;
                    _colorError = null;
                  });
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('action_url_ramp_field'),
                initialValue: _ramp,
                decoration: InputDecoration(
                  labelText: l10n.rampMs,
                  errorText: _rampError,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() {
                  _ramp = v;
                  _rampError = null;
                }),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _target == null ? null : _generate,
          child: Text(l10n.assign),
        ),
      ],
    );
  }

  void _generate() {
    if (_target == null || _target!.bestIp == null) return;
    // Color actions require a well-formed H;S;V string. Out-of-range
    // values are clamped (hue to 0-359, sat/val to 0-100); a malformed
    // string is REJECTED with a validation error instead of being
    // silently replaced by an arbitrary default color.
    String? color;
    int? ramp;
    if (_action == 'color') {
      color = sanitizeHsv(_color);
      if (color == null) {
        setState(() => _colorError = AppLocalizations.of(context).invalidColor);
        return;
      }
      ramp = int.tryParse(_ramp.trim());
      if (ramp == null || ramp < 0 || ramp > 40950) {
        setState(
          () => _rampError = AppLocalizations.of(context).invalidActionRamp,
        );
        return;
      }
    }
    final url = ConfigureButtonAction.buildUrl(
      targetIp: _target!.bestIp!,
      targetType: _target!.type,
      action: _action,
      color: color,
      ramp: ramp,
    );
    widget.onUrlGenerated(url);
  }
}
