/// Device type enum with code, model, display name and capability flags.
///
/// Codes come from the UDP broadcast byte 6.
enum DeviceType {
  ws2(
    106,
    'WS2',
    'WiFi Switch CH',
    isSwitch: true,
    hasPower: true,
    hasTemperature: true,
    hasTimer: true,
    hasScheduler: true,
    canIdentify: true,
  ),
  wse(
    107,
    'WSE',
    'WiFi Switch EU',
    isSwitch: true,
    hasPower: true,
    hasTemperature: true,
    hasTimer: true,
    hasScheduler: true,
    canIdentify: true,
  ),
  wsx(
    122,
    'WSX',
    'WiFi Switch X',
    isSwitch: true,
    hasPower: true,
    hasTemperature: false,
    hasTimer: true,
    hasScheduler: true,
  ),
  wrs(
    105,
    'WRS',
    'WiFi Strip',
    isStrip: true,
    hasPower: true,
    hasTimer: true,
    hasScheduler: true,
    canIdentify: true,
  ),
  wll(
    113,
    'WLL',
    'WiFi Cube',
    isDimmer: true,
    hasPower: true,
    hasTimer: true,
    hasScheduler: true,
    canIdentify: true,
  ),
  wms(
    110,
    'WMS',
    'WiFi PIR',
    isPir: true,
    hasTemperature: true,
    hasScheduler: true,
    canIdentify: true,
  ),
  bp2(
    118,
    'BP2',
    'WiFi Button Plus 2',
    isButton: true,
    isBattery: true,
    hasTemperature: true,
    hasHumidity: true,
  ),
  bp1(
    119,
    'BP1',
    'WiFi Button Plus 1',
    isButton: true,
    isBattery: true,
    hasTemperature: true,
    hasHumidity: true,
  ),
  bm1(
    121,
    'BM1',
    'WiFi Button Max',
    isButton: true,
    isBattery: true,
    hasTemperature: true,
    hasHumidity: true,
  ),
  bulb(
    102,
    'Bulb',
    'WiFi Bulb',
    isBulb: true,
    hasTimer: true,
    canIdentify: true,
    identifyViaTimer: true,
  ),
  lcs(120, 'LCS', 'WiFi Switch LCS', isSwitch: true, hasTimer: true),
  button(101, 'Button', 'WiFi Button', isButton: true, isBattery: true),
  unknown(0, '???', 'Unknown Device');

  final int code;
  final String model;
  final String displayName;

  // Capability flags
  final bool isSwitch;
  final bool isStrip;
  final bool isDimmer;
  final bool isBulb;
  final bool isPir;
  final bool isButton;
  final bool isBattery;
  final bool hasPower;
  final bool hasTemperature;
  final bool hasHumidity;
  final bool hasTimer;
  final bool hasScheduler;

  /// Device responds to `POST /identify` by blinking/confirming.
  /// Supported on WS2, WSE, WRS, WLL, WMS (PIR) and the Bulb.
  final bool canIdentify;

  /// When `true`, identification is done through the bulb timer API
  /// (`POST /api/v1/timer/<MAC>?mode=toggle&time=3&color=...`) instead of
  /// the standard `POST /identify` endpoint. Currently only the Bulb.
  final bool identifyViaTimer;

  /// Global switch to enable/disable the identify feature across the app.
  /// Set to `false` to hide all identify affordances and make the use case
  /// a no-op (the underlying capability code stays in place). Flip back to
  /// `true` to re-enable identification.
  static const bool identifyEnabled = false;

  /// Whether identification is currently exposed in the UI / active in the
  /// use case. Combines the per-type capability with the global switch.
  bool get identifyAvailable => canIdentify && identifyEnabled;

  const DeviceType(
    this.code,
    this.model,
    this.displayName, {
    this.isSwitch = false,
    this.isStrip = false,
    this.isDimmer = false,
    this.isBulb = false,
    this.isPir = false,
    this.isButton = false,
    this.isBattery = false,
    this.hasPower = false,
    this.hasTemperature = false,
    this.hasHumidity = false,
    this.hasTimer = false,
    this.hasScheduler = false,
    this.canIdentify = false,
    this.identifyViaTimer = false,
  });

  /// Resolve a [DeviceType] from the UDP broadcast type code.
  static DeviceType fromCode(int code) {
    return DeviceType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => DeviceType.unknown,
    );
  }

  /// Whether this device type broadcasts UDP continuously.
  /// Battery-powered buttons may sleep and not broadcast reliably.
  bool get broadcastsUdp => !isBattery;

  /// Scheduler is supported on WS2, WSE, WRS, WMS, WSX and WLL since
  /// firmware 5.0.0. Returns `true` only when both the type supports it
  /// and the reported firmware version is >= [minFw].
  static bool schedulerAvailable(DeviceType type, String firmwareVersion) {
    if (!type.hasScheduler) return false;
    return compareFirmware(firmwareVersion, schedulerMinFw) >= 0;
  }

  /// Minimum firmware version that ships the scheduler API.
  static const String schedulerMinFw = '5.0.0';

  /// Compares two semver-like version strings.
  ///
  /// Returns a negative number if [a] < [b], zero if equal, positive if [a] > [b].
  /// Non-numeric segments (e.g. a trailing git hash) are compared lexically and
  /// only considered when the numeric parts are equal.
  static int compareFirmware(String a, String b) {
    int cmp(List<String> x, List<String> y) {
      final n = x.length > y.length ? x.length : y.length;
      for (var i = 0; i < n; i++) {
        final xs = i < x.length ? x[i] : '';
        final ys = i < y.length ? y[i] : '';
        final xi = int.tryParse(xs);
        final yi = int.tryParse(ys);
        if (xi != null && yi != null) {
          if (xi != yi) return xi.compareTo(yi);
        } else {
          return xs.compareTo(ys);
        }
      }
      return 0;
    }

    final pa = a.split(RegExp(r'[.\-+]'));
    final pb = b.split(RegExp(r'[.\-+]'));
    return cmp(pa, pb);
  }
}
