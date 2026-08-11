import 'package:flutter/material.dart';

/// Simple sparkline / bar chart for recent power readings.
class PowerChartWidget extends StatelessWidget {
  const PowerChartWidget({
    super.key,
    required this.readings,
    this.maxValue,
  });

  final List<double> readings;
  final double? maxValue;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('No power data')),
      );
    }
    final max = maxValue ?? readings.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 80,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarPainter(readings: readings, max: max == 0 ? 1 : max),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<double> readings;
  final double max;

  _BarPainter({required this.readings, required this.max});

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / readings.length;
    final paint = Paint()..color = Colors.green;

    for (var i = 0; i < readings.length; i++) {
      final h = (readings[i] / max) * size.height;
      canvas.drawRect(
        Rect.fromLTWH(i * barWidth, size.height - h, barWidth - 1, h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.readings != readings || old.max != max;
}