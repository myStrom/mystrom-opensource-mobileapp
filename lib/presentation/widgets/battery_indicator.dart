import 'package:flutter/material.dart';

/// Small battery indicator widget.
class BatteryIndicator extends StatelessWidget {
  const BatteryIndicator({
    super.key,
    required this.percent,
    this.charging = false,
  });

  final int percent;
  final bool charging;

  @override
  Widget build(BuildContext context) {
    final color = percent > 50
        ? Colors.green
        : percent > 20
        ? Colors.orange
        : Colors.red;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          charging ? Icons.battery_charging_full : Icons.battery_full,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text('$percent%', style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
