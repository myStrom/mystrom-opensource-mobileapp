/// Endpoint path helpers per device type / capability.
///
/// Centralises the REST paths described in the API docs so the UI and
/// repositories don't hardcode strings.
class ApiEndpoints {
  ApiEndpoints._();

  // Common
  static const info = '/info';
  static const apiV1Info = '/api/v1/info';
  static const scan = '/api/v1/scan';
  static const connect = '/api/v1/connect';
  static const wps = '/api/v1/wps';
  static const ip = '/api/v1/ip';
  static const help = '/help';

  // Switch / Plug (WS2, WSE, WSX, LCS)
  // Note: relay/timer use /relay and /timer (no /api/v1 prefix) on real firmware.
  static const relay = '/relay';
  static const toggle = '/toggle';
  static const report = '/report';
  static const temperature = '/api/v1/temperature';
  static const timer = '/timer';
  static const bulbTimerPath = '/api/v1/timer/self';
  static const monitor = '/api/v1/monitor';
  static const reboot = '/api/v1/reboot';
  static const temp = '/temp';
  static const plug = '/plug';

  // LED Strip (WRS)
  // GET uses /api/v1/device, but POST must use /device (no /api/v1 prefix).
  static const stripDeviceGet = '/api/v1/device';
  static const stripDevicePost = '/device';
  static const stripColors = '/api/v1/colors';
  static const stripColor = '/api/v1/color';
  static const stripValue = '/api/v1/value';
  static const stripStop = '/api/v1/stop';
  static const stripPower = '/api/v1/power';
  static const stripChModeGet = '/api/v1/ch_mode';
  static const stripChModeSet = '/api/v1/ch_mode'; // /<mode> appended
  static const stripTimer = '/timer';
  static const stripEffectSet = '/api/v1/effect/set';
  static const stripEffectStart = '/api/v1/effect/start';
  static const stripEffectStop = '/api/v1/effect/stop';
  static const stripEffectGet = '/api/v1/effect/get';
  static const stripEffectStatus = '/api/v1/effect/status';
  static const stripWakeupStart = '/api/v1/wakeup/start';
  static const stripWakeupStop = '/api/v1/wakeup/stop';
  static const stripWakeupStatus = '/api/v1/wakeup/status';

  // Dimmer (WLL / Cube)
  // GET uses /api/v1/device, but POST must use /device (no /api/v1 prefix).
  static const dimmerDeviceGet = '/api/v1/device';
  static const dimmerDevicePost = '/device';
  static const dimmerTimer = '/timer';

  // Bulb
  static const bulbDevice = '/api/v1/device/self';
  static const bulbTimer = '/api/v1/timer/self';
  static const bulbEvent = '/api/v1/event';

  // PIR (WMS)
  static const pirSensors = '/api/v1/sensors';
  static const pirMotion = '/api/v1/motion';
  static const pirLight = '/api/v1/light';
  static const pirSettings = '/api/v1/settings/pir';
  static const pirThresholds = '/api/v1/settings/pir/thresholds';
  // PIR action: GET /api/v1/action returns {pir: {...}}
  static const pirActionAll = '/api/v1/action';
  static const pirAction = '/api/v1/action/pir';
  static const pirLedEnable = '/api/v1/led/enable';
  static const pirLedDisable = '/api/v1/led/disable';

  // Button (single button)
  static const buttonDevice = '/api/v1/device';
  static const buttonActions = '/api/v1/actions';
  static const buttonSleep = '/api/v1/sleep';
  static const buttonThresholds = '/api/v1/thresholds';
  static const buttonVerification = '/api/v1/verification';

  // LCS button action (single URL)
  static const lcsButtonAction = '/api/v1/action/button';

  // Switch button action (WS2, WSE, WSX)
  // GET returns {url, on, off}; POST sets the default URL via raw text body.
  static const switchButtonAction = '/api/v1/action/relay';

  // Button-se (BP2 / BM1)
  static const buttonSeSensors = '/api/v1/sensors';
  static const buttonSeAction = '/api/v1/action';
  static const buttonSeActions = '/api/v1/actions';
  static const buttonSeDisplay = '/api/v1/display';
  static const buttonSeSleep = '/api/v1/sleep';

  // Scheduler (firmware >= 5.0.0; WS2, WSE, WRS, WMS, WSX, WLL only)
  // GET  /api/v1/scheduler -> array of schedule items (UTC times)
  // POST /api/v1/scheduler  -> array of schedule items (UTC times), returns array
  static const scheduler = '/api/v1/scheduler';

  // Report history (firmware >= 5.0.0; WS2, WSE, WSX only)
  // GET /api/v1/history?page=<n> -> {records:[{t, e}], count, offset, page}
  // Records come newest-first, ~64 per page, hourly cadence. `t` is an
  // ISO-8601 UTC timestamp, `e` is cumulative energy in watt-seconds (Ws).
  static const history = '/api/v1/history';

  // Identification (WS2, WSE, WRS, WLL, WMS).
  // POST /identify -> 204 on success. Returns 400 when the device is paired
  // with HomeKit (component of the HomeKit API). Any error/timeout must be
  // silently ignored by the caller — identification is best-effort.
  static const identify = '/identify';

  // Bulb identification uses the bulb timer API with a short toggle.
  // POST /api/v1/timer/<MAC>?mode=toggle&time=3&color=120;100;100
  // Path prefix; the MAC is appended by the caller.
  static const bulbTimerPrefix = '/api/v1/timer/';
}
