import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Interactive analog clock used by the scheduler "add" page.
///
/// Two hands:
/// - **Hour hand** (short): drag within its touch zone to set the hour.
/// - **Minute hand** (long, 2× longer): drag within its touch zone to set
///   the minute.
///
/// Only one hand can be dragged at a time: the user must lift the finger
/// off a hand before grabbing the other (multi-touch on the second hand
/// is ignored while the first is being dragged).
class AnalogTimePicker extends StatefulWidget {
  const AnalogTimePicker({
    super.key,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  final int hour;
  final int minute;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  State<AnalogTimePicker> createState() => _AnalogTimePickerState();
}

class _AnalogTimePickerState extends State<AnalogTimePicker> {
  /// Which hand is currently being dragged (null when none).
  _Hand? _activeHand;

  static const double _size = 280;
  // Hour hand visual length = the hour touch-zone radius (as a fraction
  // of the dial radius). A touch within this radius sets the hour.
  static const double _hourRatio = 0.50;
  // Minute hand visual length = the minute touch-zone radius. A touch
  // between the hour radius and this radius sets the minute.
  static const double _minuteRatio = 0.86;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = _size / 2;
    final center = Offset(radius, radius);
    final hourAngle = _handAngle(widget.hour % 12, 12);
    final minuteAngle = _handAngle(widget.minute, 60);
    final hourHandEnd = _handEnd(center, hourAngle, radius * _hourRatio);
    final minuteHandEnd = _handEnd(center, minuteAngle, radius * _minuteRatio);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time display above the dial.
        Text(
          '${widget.hour.toString().padLeft(2, '0')}:'
          '${widget.minute.toString().padLeft(2, '0')}',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: _size,
          height: _size,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: (_) => setState(() => _activeHand = null),
            child: CustomPaint(
              size: const Size(_size, _size),
              painter: _ClockPainter(
                center: center,
                radius: radius,
                hourHandEnd: hourHandEnd,
                minuteHandEnd: minuteHandEnd,
                hourAngle: hourAngle,
                minuteAngle: minuteAngle,
                hourRatio: _hourRatio,
                minuteRatio: _minuteRatio,
                activeHand: _activeHand,
                faceColor: theme.colorScheme.surfaceContainerHighest,
                hourColor: theme.colorScheme.primary,
                minuteColor: theme.colorScheme.tertiary,
                tickColor: theme.colorScheme.outline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Offset _localPosition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox;
    return box.globalToLocal(globalPosition);
  }

  /// Tap on the dial: pick the nearest hand at the touch point and jump
  /// the corresponding time unit to the tapped angle. Works alongside
  /// drag (pan) — tap for quick jumps, drag for fine adjustment.
  void _onTapDown(TapDownDetails details) {
    final pos = _localPosition(details.globalPosition);
    final center = Offset(_size / 2, _size / 2);
    setState(() {
      _activeHand = _pickHandAt(pos, center);
      if (_activeHand != null) _updateFromPosition(pos, center);
      _activeHand = null;
    });
  }

  void _onPanStart(DragStartDetails details) {
    final pos = _localPosition(details.globalPosition);
    final center = Offset(_size / 2, _size / 2);
    setState(() => _activeHand = _pickHandAt(pos, center));
    if (_activeHand != null) _updateFromPosition(pos, center);
  }

  /// Decide which hand a touch point belongs to based on distance from
  /// the center.
  ///
  /// Clean radial split (exactly the hand reach, no extra margins):
  /// - <= hourLen  -> **hour hand** (inner disc, up to the short hand tip)
  /// - hourLen < d <= minuteLen -> **minute hand** (ring from the short
  ///   hand tip to the long hand tip)
  /// - beyond minuteLen -> nothing
  _Hand? _pickHandAt(Offset pos, Offset center) {
    final dist = (pos - center).distance;
    final hourLen = (_size / 2) * _hourRatio;
    final minuteLen = (_size / 2) * _minuteRatio;
    if (dist <= hourLen) {
      return _Hand.hour;
    } else if (dist <= minuteLen) {
      return _Hand.minute;
    }
    return null;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeHand == null) return;
    final pos = _localPosition(details.globalPosition);
    final center = Offset(_size / 2, _size / 2);
    _updateFromPosition(pos, center);
  }

  void _updateFromPosition(Offset pos, Offset center) {
    final angle = math.atan2(pos.dy - center.dy, pos.dx - center.dx);
    // 0 radians points right (3 o'clock). Convert to clock angle (12 at top).
    // clock angle = (90° - degreesFromRight) mapped to 0..60 / 0..12.
    switch (_activeHand) {
      case _Hand.hour:
        final h = _angleToUnit(angle, 12);
        // Keep the existing minute, snap hour.
        widget.onChanged(TimeOfDay(hour: h, minute: widget.minute));
      case _Hand.minute:
        final m = _angleToUnit(angle, 60);
        widget.onChanged(TimeOfDay(hour: widget.hour, minute: m));
      case null:
        break;
    }
  }

  /// Convert a radians angle (0 = right, increasing clockwise) to the
  /// nearest unit on a clock of [units] divisions.
  int _angleToUnit(double angle, int units) {
    // atan2: 0 = right, π/2 = down, -π/2 = up.
    // Clock: 0 (top) at -π/2. Convert so top = 0, clockwise positive.
    // Add 2π before the final modulo so the result is always non-negative
    // (Dart's % keeps the sign of the dividend, so a negative intermediate
    // would map to a wrong clock position).
    final clockwise =
        ((math.pi / 2 + angle) % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
    final fraction = clockwise / (2 * math.pi);
    return (fraction * units).round() % units;
  }

  double _handAngle(int unit, int units) {
    // fraction of full circle, 0 at top, clockwise.
    final fraction = unit / units;
    // Convert to atan2 convention: 0 at right, clockwise positive.
    return -math.pi / 2 + fraction * 2 * math.pi;
  }

  Offset _handEnd(Offset center, double angle, double length) {
    return Offset(
      center.dx + length * math.cos(angle),
      center.dy + length * math.sin(angle),
    );
  }
}

enum _Hand { hour, minute }

class _ClockPainter extends CustomPainter {
  const _ClockPainter({
    required this.center,
    required this.radius,
    required this.hourHandEnd,
    required this.minuteHandEnd,
    required this.hourAngle,
    required this.minuteAngle,
    required this.hourRatio,
    required this.minuteRatio,
    required this.activeHand,
    required this.faceColor,
    required this.hourColor,
    required this.minuteColor,
    required this.tickColor,
  });

  final Offset center;
  final double radius;
  final Offset hourHandEnd;
  final Offset minuteHandEnd;
  final double hourAngle;
  final double minuteAngle;
  final double hourRatio;
  final double minuteRatio;
  final _Hand? activeHand;
  final Color faceColor;
  final Color hourColor;
  final Color minuteColor;
  final Color tickColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Face.
    final facePaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    // ---- Touch-zone tints (match the hand reach exactly) ----
    // Minute zone: filled disc up to the minute hand tip (tertiary tint).
    final minuteZoneRadius = radius * minuteRatio;
    canvas.drawCircle(
      center,
      minuteZoneRadius,
      Paint()
        ..color = minuteColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    // Hour zone: filled disc up to the hour hand tip (primary tint),
    // painted on top so the inner disc shows the hour colour and the
    // outer ring keeps the minute colour.
    final hourZoneRadius = radius * hourRatio;
    canvas.drawCircle(
      center,
      hourZoneRadius,
      Paint()
        ..color = hourColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );

    final rimPaint = Paint()
      ..color = tickColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, rimPaint);

    // Hour ticks (12) and minute ticks (60).
    for (var i = 0; i < 60; i++) {
      final angle = -math.pi / 2 + (i / 60) * 2 * math.pi;
      final isHour = i % 5 == 0;
      final outer = radius * 0.94;
      final inner = radius * (isHour ? 0.86 : 0.90);
      canvas.drawLine(
        Offset(
          center.dx + outer * math.cos(angle),
          center.dy + outer * math.sin(angle),
        ),
        Offset(
          center.dx + inner * math.cos(angle),
          center.dy + inner * math.sin(angle),
        ),
        Paint()
          ..color = tickColor
          ..strokeWidth = isHour ? 2 : 1,
      );
    }

    // Hour hand (short).
    final hourPaint = Paint()
      ..color = activeHand == _Hand.hour
          ? hourColor
          : hourColor.withValues(alpha: 0.85)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, hourHandEnd, hourPaint);

    // Minute hand (long).
    final minutePaint = Paint()
      ..color = activeHand == _Hand.minute
          ? minuteColor
          : minuteColor.withValues(alpha: 0.85)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, minuteHandEnd, minutePaint);

    // Center hub.
    canvas.drawCircle(center, 6, Paint()..color = hourColor);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) =>
      old.hourHandEnd != hourHandEnd ||
      old.minuteHandEnd != minuteHandEnd ||
      old.activeHand != activeHand ||
      old.faceColor != faceColor;
}
