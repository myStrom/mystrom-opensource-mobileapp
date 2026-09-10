/// HSV color helpers shared by the color picker, scheduler forms and the
/// action URL picker.
///
/// myStrom devices accept hue in the **0–359** range (360 wraps back to
/// red/0 and is rejected or misbehaves on some firmware versions), so all
/// user input and parsed device state is clamped to `0 <= hue <= 359`.
/// Saturation and value are `0–100`.
library;

/// Maximum valid hue value (inclusive).
const int maxHue = 359;

/// Clamp a hue value to the valid `0–359` range.
int clampHue(num hue) {
  // Guard against NaN/infinity: double.round() throws for them.
  if (hue.isNaN) return 0;
  if (hue.isInfinite) return hue.isNegative ? 0 : maxHue;
  return hue.round().clamp(0, maxHue);
}

/// Clamp saturation or value to the valid `0–100` range.
int clampSatVal(num v) => v.round().clamp(0, 100);

/// Sanitize a raw `H;S;V` string into a normalized `H;S;V` string with
/// hue in `0–359` and saturation/value in `0–100`.
///
/// Returns `null` when [input] is `null`/empty or not in the
/// `H;S;V` (3 parts) format — the caller decides what to do.
String? sanitizeHsv(String? input) {
  if (input == null || input.isEmpty) return null;
  final parts = input.split(';');
  if (parts.length != 3) return null;
  final h = int.tryParse(parts[0].trim());
  final s = int.tryParse(parts[1].trim());
  final v = int.tryParse(parts[2].trim());
  if (h == null || s == null || v == null) return null;
  return '${clampHue(h)};${clampSatVal(s)};${clampSatVal(v)}';
}