import 'package:flutter_test/flutter_test.dart';

import 'package:mystrom_local/presentation/utils/hsv_utils.dart';

void main() {
  group('clampHue', () {
    test('clamps values above 359 to 359', () {
      expect(clampHue(360), 359);
      expect(clampHue(480), 359);
      expect(clampHue(double.infinity), 359);
      expect(clampHue(double.nan), 0);
      expect(clampHue(double.negativeInfinity), 0);
    });

    test('keeps valid values untouched', () {
      expect(clampHue(0), 0);
      expect(clampHue(120), 120);
      expect(clampHue(359), 359);
    });

    test('clamps negative values to 0', () {
      expect(clampHue(-1), 0);
      expect(clampHue(-120), 0);
    });

    test('rounds doubles', () {
      expect(clampHue(120.6), 121);
      expect(clampHue(359.4), 359);
    });
  });

  group('clampSatVal', () {
    test('clamps to 0-100', () {
      expect(clampSatVal(-5), 0);
      expect(clampSatVal(50), 50);
      expect(clampSatVal(100), 100);
      expect(clampSatVal(150), 100);
    });
  });

  group('sanitizeHsv', () {
    test('normalizes a valid H;S;V string', () {
      expect(sanitizeHsv('120;100;100'), '120;100;100');
    });

    test('clamps hue of 360 down to 359', () {
      expect(sanitizeHsv('360;100;100'), '359;100;100');
      expect(sanitizeHsv('400;120;150'), '359;100;100');
    });

    test('clamps negative and out-of-range parts', () {
      expect(sanitizeHsv('-10;50;50'), '0;50;50');
      expect(sanitizeHsv('10;-5;150'), '10;0;100');
    });

    test('trims whitespace around parts', () {
      expect(sanitizeHsv(' 30 ; 50 ; 60 '), '30;50;60');
    });

    test('returns null for null/empty/invalid input', () {
      expect(sanitizeHsv(null), isNull);
      expect(sanitizeHsv(''), isNull);
      expect(sanitizeHsv('120;100'), isNull);
      expect(sanitizeHsv('a;b;c'), isNull);
      expect(sanitizeHsv('120;100;100;50'), isNull);
    });
  });

  group('maxHue constant', () {
    test('is 359 (myStrom devices reject hue 360)', () {
      expect(maxHue, 359);
    });
  });
}