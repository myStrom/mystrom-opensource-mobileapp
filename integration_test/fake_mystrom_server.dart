// Fake myStrom HTTP server used by the integration tests.
//
// Listens on 127.0.0.1 and emulates just enough of the myStrom REST API
// for WS2 (switch) and WRS (strip) devices so the UI can toggle power,
// change color and read/write the scheduler without real hardware.
//
// State is kept per MAC so multiple fake devices can share one server.

import 'dart:convert';
import 'dart:io';

/// Per-device state held by the fake server.
class FakeDeviceState {
  FakeDeviceState({
    required this.mac,
    required this.type,
    required this.model,
    required this.version,
  });

  final String mac;
  final String type; // info "type" string, e.g. "wse", "strip"
  final String model; // e.g. "WS2", "WRS"
  final String version; // firmware version

  bool relay = false; // switch relay
  bool on = false; // strip/bulb on
  String color = '0;0;0'; // HSV string for strip/bulb
  String mode = 'hsv';
  int ramp = 0;
  String chMode = 'colors';
  int dimmerValue = 50; // dimmer brightness 0-100
  String timerMode = 'none'; // last timer mode set
  int timerSeconds = 0; // last timer duration set
  String? lcsButtonAction; // LCS button action URL
  dynamic buttonActions; // Button (legacy) / Button-se action map
  String? buttonSeAction; // Button-se per-referer action URL body
  List<Map<String, dynamic>> scheduler = const [];

  /// Set to true when a `POST /identify` request was received. Tests assert
  /// on this to confirm the identify button fired the right endpoint.
  bool identifyRequested = false;

  /// Set to true when a `POST /api/v1/timer/<mac>` request was received
  /// (bulb identification). Tests assert on this to confirm the bulb
  /// identify path fired.
  bool bulbTimerIdentifyRequested = false;

  /// Boot identifier returned in `/report`. Tests can change it to
  /// simulate a reboot and exercise the energy accumulator.
  String bootId = 'boot-1';

  // ---- Provisioning (SoftAP) ----

  /// WiFi scan results returned by `GET /api/v1/scan`, as the flat
  /// alternating SSID/RSSI array the real firmware emits.
  List<dynamic> scanResults = const ['HomeWiFi', -55, 'Guest', -72];

  /// Set to true when `POST /api/v1/connect` was received.
  bool connectRequested = false;

  /// The decoded JSON body of the last `/api/v1/connect` request.
  Map<String, dynamic>? connectBody;

  /// When > 0, `/api/v1/connect` returns 400 that many times (decremented
  /// per request) to simulate legacy firmware that rejects the `roaming`
  /// field on the first attempt. Tests the fallback retry path.
  int rejectConnectCount = 0;

  /// Set to true when `POST /api/v1/wps` was received.
  bool wpsRequested = false;
}

/// A minimal myStrom-compatible HTTP server bound to 127.0.0.1.
///
/// One server instance emulates exactly one device (the device identified
/// by [register]). This avoids any reliance on the Host header to route
/// requests to per-device state.
class FakeMystromServer {
  FakeMystromServer();

  HttpServer? _server;
  FakeDeviceState? _state;

  /// When true, `POST /identify` returns 400 (simulates a device paired
  /// with HomeKit, where /identify is a HomeKit API endpoint that rejects
  /// non-HomeKit callers).
  bool rejectIdentify = false;

  /// The device this server emulates.
  FakeDeviceState register(FakeDeviceState state) {
    _state = state;
    return state;
  }

  String get baseUrl => 'http://${_server!.address.host}:${_server!.port}';

  /// The bound port (only valid after [start]).
  int get port => _server!.port;

  /// The bound address host (only valid after [start]).
  String get host => _server!.address.host;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handleRequest);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  FakeDeviceState _resolve(HttpRequest req) {
    final st = _state;
    if (st == null) {
      throw StateError('No fake device registered on this server');
    }
    return st;
  }

  Future<void> _handleRequest(HttpRequest req) async {
    try {
      final path = req.uri.path;
      final query = req.uri.queryParameters;
      final st = _resolve(req);

      String? body;
      if (req.method == 'POST') {
        final bytes = await req.fold<List<int>>([], (a, b) => a..addAll(b));
        body = String.fromCharCodes(bytes);
      }

      // Strip channel mode set: POST /api/v1/ch_mode/<mode> (the path
      // has a mode suffix, so handle it before the fixed-path switch).
      if (path.startsWith('/api/v1/ch_mode/') && req.method == 'POST') {
        st.chMode = path.substring('/api/v1/ch_mode/'.length);
        await _empty(req);
        return;
      }

      switch (path) {
        case '/info':
        case '/api/v1/info':
          await _json(req, {
            'version': st.version,
            'mac': st.mac,
            'ssid': 'test-ssid',
            'ip': _server!.address.host,
            'mask': '255.255.255.0',
            'gw': '192.168.1.1',
            'dns': '8.8.8.8',
            'static': false,
            'connected': true,
            'roaming': false,
            'type': st.type,
            'name': st.model,
            'connectionStatus': {
              'ntp': true,
              'dns': true,
              'connection': true,
              'handshake': true,
              'login': true,
            },
          });
          return;

        case '/report':
          await _json(req, {
            'relay': st.relay,
            // Realistic power: a few watts when the relay is on, zero when off.
            'power': st.relay ? 12.5 : 0.0,
            'temperature': 22.5,
            // Energy since boot in watt-seconds (Ws).
            'energy_since_boot': st.relay ? 3600000.0 : 0.0,
            'boot_id': st.bootId,
          });
          return;

        case '/relay':
          // /relay?state=0|1
          if (req.method == 'GET' && query.containsKey('state')) {
            st.relay = query['state'] == '1';
          }
          // Empty 200 like the real firmware.
          await _empty(req);
          return;

        case '/toggle':
          st.relay = !st.relay;
          await _json(req, {'relay': st.relay});
          return;

        case '/timer':
        case '/api/v1/timer/self':
          // POST /timer?mode=&time= (switch) or /api/v1/timer/self (bulb).
          // Some HTTP clients send the params in the URL query, others in
          // the body; accept both.
          if (req.method == 'POST') {
            final params = <String, String>{...query};
            if (params.isEmpty && body != null && body.isNotEmpty) {
              for (final part in body.split('&')) {
                final eq = part.indexOf('=');
                if (eq > 0) {
                  params[Uri.decodeQueryComponent(part.substring(0, eq))] =
                      Uri.decodeQueryComponent(part.substring(eq + 1));
                }
              }
            }
            if (params.containsKey('mode')) {
              st.timerMode = params['mode'] ?? 'none';
            }
            final t = params['time'];
            if (t != null) st.timerSeconds = int.tryParse(t) ?? 0;
          }
          await _empty(req);
          return;

        case '/api/v1/sensors':
          // PIR (WMS) and Button-se (BP2/BM1) sensor readout.
          await _json(req, {
            'motion': false,
            'light': 128.0,
            'temperature': 21.0,
            'humidity': 45.0,
            'battery': {'voltage': 3.0, 'charging': false},
            'charger': {'voltage': 0.0, 'charging': false},
          });
          return;

        case '/api/v1/action/button':
          // LCS button action URL: GET returns {url: ...}, POST sets it
          // via a form-encoded body (url=...).
          if (req.method == 'GET') {
            await _json(req, {'url': st.lcsButtonAction ?? ''});
          } else {
            var url = st.lcsButtonAction ?? '';
            if (body != null && body.isNotEmpty) {
              for (final part in body.split('&')) {
                final eq = part.indexOf('=');
                if (eq > 0 &&
                    Uri.decodeQueryComponent(part.substring(0, eq)) == 'url') {
                  url = Uri.decodeQueryComponent(part.substring(eq + 1));
                }
              }
            }
            st.lcsButtonAction = url;
            await _empty(req);
          }
          return;

        case '/api/v1/actions':
          // Button (legacy) + Button-se action URL config.
          // GET returns an empty action map; POST accepts JSON and stores
          // it so tests can assert it landed.
          if (req.method == 'GET') {
            await _json(req, const {});
          } else {
            try {
              final decoded = jsonDecode(body ?? '');
              st.buttonActions = decoded;
            } catch (_) {
              st.buttonActions = body;
            }
            await _empty(req);
          }
          return;

        case '/api/v1/action':
          // Button-se per-referer action URL: POST stores the URL.
          if (req.method == 'POST') {
            st.buttonSeAction = body ?? '';
            await _empty(req);
          } else {
            await _json(req, const {});
          }
          return;

        // ---- Strip / Bulb / Dimmer ----
        case '/api/v1/device':
        case '/api/v1/device/self':
          if (req.method == 'GET') {
            await _json(req, {
              st.mac: {
                'on': st.on,
                'color': st.color,
                'mode': st.mode,
                'ramp': st.ramp,
                'value': st.dimmerValue,
                // Power scales with the strip/dimmer/bulb being on.
                'power': st.on ? (st.dimmerValue / 100.0 * 9.0) : 0.0,
                'reachable': true,
              },
            });
          } else {
            _applyForm(st, body ?? '');
            await _empty(req);
          }
          return;

        case '/device':
          // Strip/dimmer POST endpoint (no /api/v1 prefix).
          if (req.method == 'POST') {
            _applyForm(st, body ?? '');
          }
          await _empty(req);
          return;

        case '/api/v1/ch_mode':
          await _json(req, {'ch_mode': st.chMode});
          return;

        case '/api/v1/scheduler':
          if (req.method == 'GET') {
            await _jsonList(req, st.scheduler);
          } else {
            // POST: body is a JSON array; echo it back as the stored list.
            try {
              final decoded = jsonDecode(body ?? '') as List<dynamic>;
              st.scheduler = decoded.cast<Map<String, dynamic>>().toList(
                growable: true,
              );
              await _jsonList(req, st.scheduler);
            } catch (_) {
              await _jsonList(req, const []);
            }
          }
          return;

        case '/identify':
          // Standard identification blink (WS2, WSE, WRS, WLL, WMS).
          if (req.method == 'POST') st.identifyRequested = true;
          if (rejectIdentify) {
            req.response.statusCode = HttpStatus.badRequest;
            await req.response.close();
            return;
          }
          await _empty(req);
          return;

        case '/api/v1/scan':
          // WiFi scan from the device's perspective. Returns the flat
          // alternating SSID/RSSI array the real firmware emits.
          await _jsonList(req, st.scanResults);
          return;

        case '/api/v1/connect':
          // Provisioning: POST with ssid/passwd[/ip/mask/gw/dns/roaming].
          if (req.method == 'POST') {
            st.connectRequested = true;
            try {
              st.connectBody = jsonDecode(body ?? '') as Map<String, dynamic>;
            } catch (_) {
              st.connectBody = {'raw': body};
            }
            // Simulate legacy firmware rejecting the `roaming` field
            // a limited number of times (decremented per request).
            if (st.rejectConnectCount > 0) {
              st.rejectConnectCount--;
              req.response.statusCode = HttpStatus.badRequest;
              await req.response.close();
              return;
            }
          }
          await _empty(req);
          return;

        case '/api/v1/wps':
          st.wpsRequested = true;
          await _empty(req);
          return;

        default:
          // Bulb timer by MAC: POST /api/v1/timer/<mac>?mode=toggle&...
          // (used for bulb identification).
          if (req.method == 'POST' &&
              path.startsWith('/api/v1/timer/') &&
              path != '/api/v1/timer/self') {
            st.bulbTimerIdentifyRequested = true;
            await _empty(req);
            return;
          }
          // Best-effort: unknown endpoints return an empty 200 so the
          // app does not crash on optional probes.
          await _empty(req);
          return;
      }
    } catch (e) {
      req.response.statusCode = HttpStatus.internalServerError;
      await req.response.close();
    }
  }

  void _applyForm(FakeDeviceState st, String body) {
    for (final part in body.split('&')) {
      final eq = part.indexOf('=');
      if (eq < 0) continue;
      final key = Uri.decodeQueryComponent(part.substring(0, eq));
      final value = Uri.decodeQueryComponent(part.substring(eq + 1));
      switch (key) {
        case 'action':
          if (value == 'on') st.on = true;
          if (value == 'off') st.on = false;
          if (value == 'toggle') st.on = !st.on;
        case 'color':
          st.color = value;
        case 'mode':
          st.mode = value;
        case 'ramp':
          st.ramp = int.tryParse(value) ?? st.ramp;
        case 'value':
          // Dimmer brightness 0-100.
          final v = int.tryParse(value);
          if (v != null) st.dimmerValue = v.clamp(0, 100);
          break;
      }
    }
  }

  Future<void> _json(HttpRequest req, Map<String, dynamic> data) async {
    req.response.headers.contentType = ContentType.json;
    req.response.write(jsonEncode(data));
    await req.response.close();
  }

  Future<void> _jsonList(HttpRequest req, List<dynamic> data) async {
    req.response.headers.contentType = ContentType.json;
    req.response.write(jsonEncode(data));
    await req.response.close();
  }

  Future<void> _empty(HttpRequest req) async {
    req.response.statusCode = HttpStatus.ok;
    await req.response.close();
  }
}
