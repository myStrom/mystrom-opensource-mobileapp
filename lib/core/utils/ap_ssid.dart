import 'device_type.dart';

/// Recognises a myStrom device AP network by its SSID prefix and maps
/// it to a [DeviceType].
///
/// AP SSID patterns:
///   WRB            my-bulb-XXXXXX
///   WBS/WBP        my-button-XXXXXX
///   LCS            my-switch-XXXXXX
///   PIR (WMS)      my-pir-XXXXXX
///   WLL (Cube)     my-cube-lamp-XXXXXX
///   WS2, WSE, WSX  my-XXXXXX
///   WRS            my-strip-XXXXXX
///   BP2            my-bp2-XXXXXX
///   BM1            my-bm1-XXXXXX
class ApSsidMatcher {
  ApSsidMatcher._();

  /// Ordered list of (prefix, DeviceType) pairs.
  ///
  /// More specific prefixes must come first so that, e.g., `my-bulb-`
  /// does not get shadowed by the generic `my-` fallback used by
  /// WS2/WSE/WSX (which share the bare `my-XXXXXX` pattern).
  static const List<({String prefix, DeviceType type})> _rules = [
    (prefix: 'my-bulb-', type: DeviceType.bulb),
    (prefix: 'my-button-', type: DeviceType.button),
    (prefix: 'my-switch-', type: DeviceType.lcs),
    (prefix: 'my-pir-', type: DeviceType.wms),
    (prefix: 'my-cube-lamp-', type: DeviceType.wll),
    (prefix: 'my-strip-', type: DeviceType.wrs),
    (prefix: 'my-bp2-', type: DeviceType.bp2),
    (prefix: 'my-bm1-', type: DeviceType.bm1),
    // Generic fallback for WS2 / WSE / WSX (and any other switch
    // that uses the bare `my-<mac>` pattern). These three types are
    // indistinguishable by SSID alone — the exact type is confirmed
    // later via `GET /api/v1/info` after joining the AP.
    (prefix: 'my-', type: DeviceType.ws2),
  ];

  /// Returns the [DeviceType] whose AP SSID prefix matches [ssid], or
  /// `null` if [ssid] does not look like a myStrom device AP.
  ///
  /// Matching is case-insensitive on the prefix only. The full SSID is
  /// not validated — the suffix is typically a MAC fragment but may vary
  /// by firmware.
  static DeviceType? match(String ssid) {
    if (ssid.isEmpty) return null;
    final lower = ssid.toLowerCase();
    for (final r in _rules) {
      if (lower.startsWith(r.prefix)) return r.type;
    }
    return null;
  }

  /// Whether [ssid] matches any known myStrom AP SSID prefix.
  static bool isMyStromAp(String ssid) => match(ssid) != null;
}
