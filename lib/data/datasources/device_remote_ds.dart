import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/device_http_client.dart';
import '../../core/utils/device_type.dart';
import '../models/action_url_config.dart';
import '../models/bulb_state.dart';
import '../models/device_info.dart';
import '../models/dimmer_state.dart';
import '../models/pir_state.dart';
import '../models/scheduler_item.dart';
import '../models/strip_state.dart';
import '../models/switch_state.dart';
import '../models/wifi_network.dart';
import '../models/button_sensor_state.dart';

/// Remote data source: all HTTP calls to a device.
class DeviceRemoteDataSource {
  DeviceRemoteDataSource(this._client);

  final DeviceHttpClient _client;

  /// Build a raw form-encoded body string (`key=value&key=value`).
  ///
  /// Values containing semicolons (like HSV color `H;S;V`) are NOT
  /// URL-encoded — myStrom firmware expects them raw.  `null` values
  /// are skipped entirely.
  static String _buildFormBody(Map<String, String?> fields) {
    final parts = <String>[];
    fields.forEach((key, value) {
      if (value != null) parts.add('$key=$value');
    });
    return parts.join('&');
  }

  // ---- Common ----

  /// Best-effort current power draw (W) for any device type.
  ///
  /// Returns null when the device does not report power or the request
  /// fails. Used by the dashboard "total / per-room power" summary which
  /// must be resilient to missing fields and unreachable devices.
  Future<double?> getPower(String ip, DeviceType type) async {
    try {
      if (type.isSwitch) {
        final r = await getReport(ip);
        return r.power;
      } else if (type.isStrip) {
        return (await getStripState(ip)).power;
      } else if (type.isDimmer) {
        return (await getDimmerState(ip)).power;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<DeviceInfoModel> getInfo(String ip) async {
    // Some firmware versions expose /api/v1/info instead of /info.
    // Try /info first, fall back to /api/v1/info.
    try {
      final res = await _client.get(ip, ApiEndpoints.info);
      return DeviceInfoModel.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      final res = await _client.get(ip, ApiEndpoints.apiV1Info);
      return DeviceInfoModel.fromJson(res.data as Map<String, dynamic>);
    }
  }

  /// Fetch `/api/v1/info` with a short timeout, suitable for probing a
  /// device in AP mode where we don't want to block the wizard for the
  /// full provisioning timeout if the device doesn't respond.
  ///
  /// Returns `null` on any error (timeout, 404, non-JSON, etc.).
  Future<DeviceInfoModel?> probeInfo(String ip) async {
    try {
      return await getInfo(ip);
    } catch (_) {
      return null;
    }
  }

  Future<List<WifiNetworkModel>> scanWifi(String ip) async {
    final res = await _client.get(
      ip,
      ApiEndpoints.scan,
      responseType: ResponseType.json,
    );
    final data = res.data;
    if (data is String) {
      // chunked text fallback
      return const [];
    }
    return WifiNetworkModel.fromScanArray(data as List<dynamic>);
  }

  /// Scan for WiFi networks, retrying for up to [totalTimeout] because the
  /// myStrom `/api/v1/scan` endpoint takes ~5s on real hardware and may
  /// return an empty/partial list on the first call.
  ///
  /// Each attempt uses the HTTP client's configured timeout. The scan is
  /// considered complete as soon as a non-empty list is returned.
  Future<List<WifiNetworkModel>> scanWifiWithRetry(
    String ip, {
    Duration totalTimeout = const Duration(seconds: 15),
  }) async {
    final deadline = DateTime.now().add(totalTimeout);
    List<WifiNetworkModel> last = const [];
    while (DateTime.now().isBefore(deadline)) {
      try {
        last = await scanWifi(ip);
        if (last.isNotEmpty) return last;
      } on DioException catch (e) {
        // connection timeout / 5xx — keep retrying until the deadline.
        debugPrint('[scanWifi] retry: ${e.type}');
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return last;
  }

  /// Send WiFi credentials to a device in AP mode.
  ///
  /// Newer firmware (WS2, WSE, WSX, WRS, WLL, WMS, BP2, BM1, LCS)
  /// accepts an optional `roaming` bool. Older firmware (WRB
  /// Bulb, WBS/WBP Button) does NOT — sending `roaming` may cause a
  /// `400 Bad Request`. We try the new (with roaming) variant first and
  /// fall back to the legacy body if the server rejects it.
  Future<void> connectWifi(
    String ip, {
    required String ssid,
    String? password,
    String? staticIp,
    String? mask,
    String? gw,
    String? dns,
    bool roaming = false,
  }) async {
    final base = <String, dynamic>{'ssid': ssid};
    if (password != null) base['passwd'] = password;
    if (staticIp != null) base['ip'] = staticIp;
    if (mask != null) base['mask'] = mask;
    if (gw != null) base['gw'] = gw;
    if (dns != null) base['dns'] = dns;

    // Newer firmware: include roaming.
    final newBody = <String, dynamic>{...base, 'roaming': roaming};
    try {
      await _client.post(ip, ApiEndpoints.connect, body: newBody);
      return;
    } on DioException catch (e) {
      // 400 Bad Request → legacy firmware without roaming support.
      final code = e.response?.statusCode;
      if (code != 400 && code != 422) rethrow;
      debugPrint(
        '[connectWifi] new firmware body rejected ($code), '
        'retrying without roaming',
      );
    }

    // Legacy firmware: omit roaming entirely.
    await _client.post(ip, ApiEndpoints.connect, body: base);
  }

  Future<void> triggerWps(String ip) async {
    await _client.post(ip, ApiEndpoints.wps);
  }

  // ---- Switch / Plug ----

  Future<SwitchStateModel> getRelay(String ip) async {
    // /relay without query returns 404 on some firmware; use /report instead.
    final res = await _client.get(ip, ApiEndpoints.report);
    return SwitchStateModel.fromReport(res.data as Map<String, dynamic>);
  }

  Future<SwitchStateModel> setRelay(String ip, {required bool on}) async {
    // /relay?state=0|1 returns empty 200; fetch /report for actual state.
    await _client.get(ip, ApiEndpoints.relay, query: {'state': on ? 1 : 0});
    final res = await _client.get(ip, ApiEndpoints.report);
    return SwitchStateModel.fromReport(res.data as Map<String, dynamic>);
  }

  Future<SwitchStateModel> toggleRelay(String ip) async {
    // /toggle returns {"relay": true/false}
    final res = await _client.get(ip, ApiEndpoints.toggle);
    final body = res.data;
    if (body is Map<String, dynamic>) {
      return SwitchStateModel.fromRelay(body);
    }
    // Fallback: fetch report
    final report = await _client.get(ip, ApiEndpoints.report);
    return SwitchStateModel.fromReport(report.data as Map<String, dynamic>);
  }

  Future<SwitchStateModel> getReport(String ip) async {
    final res = await _client.get(ip, ApiEndpoints.report);
    return SwitchStateModel.fromReport(res.data as Map<String, dynamic>);
  }

  Future<void> setTimer(
    String ip, {
    required String mode,
    required int seconds,
    String? path,
  }) async {
    await _client.post(
      ip,
      path ?? ApiEndpoints.timer,
      query: {'mode': mode, 'time': seconds},
    );
  }

  Future<void> reboot(String ip) async {
    await _client.post(ip, ApiEndpoints.reboot);
  }

  // ---- LED Strip ----

  Future<StripStateModel> getStripState(String ip) async {
    final res = await _client.get(ip, ApiEndpoints.stripDeviceGet);
    final state = StripStateModel.fromJson(res.data as Map<String, dynamic>);
    // Also fetch the channel mode.
    try {
      final modeRes = await _client.get(ip, ApiEndpoints.stripChModeGet);
      final modeData = modeRes.data;
      if (modeData is Map<String, dynamic>) {
        final chMode = modeData['ch_mode'] as String? ?? 'colors';
        return state.copyWith(chMode: chMode);
      }
    } catch (_) {
      // ch_mode not available — default to 'colors'.
    }
    return state;
  }

  Future<void> setStripState(
    String ip, {
    String? action,
    String? color,
    int? ramp,
    String? mode,
  }) async {
    final body = _buildFormBody({
      'action': action,
      'color': color,
      'ramp': ramp?.toString(),
      'mode': mode,
    });
    await _client.postRawForm(ip, ApiEndpoints.stripDevicePost, body);
  }

  /// Get the current channel mode (colors | channels | cold_warm).
  Future<String> getChMode(String ip) async {
    final res = await _client.get(ip, ApiEndpoints.stripChModeGet);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return data['ch_mode'] as String? ?? 'colors';
    }
    return 'colors';
  }

  /// Set the channel mode (colors | channels | cold_warm).
  Future<void> setChMode(String ip, {required String chMode}) async {
    await _client.post(ip, '${ApiEndpoints.stripChModeSet}/$chMode');
  }

  Future<void> stopStripTransition(String ip) async {
    await _client.post(ip, ApiEndpoints.stripStop);
  }

  // ---- Dimmer ----

  Future<DimmerStateModel> getDimmerState(String ip) async {
    final res = await _client.get(ip, ApiEndpoints.dimmerDeviceGet);
    return DimmerStateModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> setDimmerState(
    String ip, {
    String? action,
    int? value,
    int? ramp,
  }) async {
    final body = _buildFormBody({
      'action': action,
      'value': value?.toString(),
      'ramp': ramp?.toString(),
    });
    await _client.postRawForm(ip, ApiEndpoints.dimmerDevicePost, body);
  }

  // ---- Bulb ----

  Future<BulbStateModel> getBulbState(String ip) async {
    final res = await _client.get(ip, ApiEndpoints.bulbDevice);
    return BulbStateModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> setBulbState(
    String ip, {
    String? action,
    String? color,
    int? ramp,
    String? mode,
  }) async {
    final body = _buildFormBody({
      'action': action,
      'color': color,
      'ramp': ramp?.toString(),
      'mode': mode,
    });
    await _client.postRawForm(ip, ApiEndpoints.bulbDevice, body);
  }

  // ---- PIR ----

  Future<PirStateModel> getPirSensors(String ip) async {
    final res = await _client.get(ip, ApiEndpoints.pirSensors);
    return PirStateModel.fromSensors(res.data as Map<String, dynamic>);
  }

  Future<void> setPirAction(
    String ip,
    String action, {
    required String url,
  }) async {
    await _client.postRawText(ip, '${ApiEndpoints.pirAction}/$action', url);
  }

  Future<Map<String, String>> getPirActions(String ip) async {
    final res = await _client.get(ip, ApiEndpoints.pirActionAll);
    final j = res.data as Map<String, dynamic>;
    // Response is {"pir": {"generic": "...", "night": "...", ...}}
    final pir = j['pir'] as Map<String, dynamic>? ?? {};
    return pir.map((k, v) => MapEntry(k, v.toString()));
  }

  // ---- LCS Button Action (single URL) ----

  /// Get the button action URL configured on an LCS device.
  Future<String> getLcsButtonAction(String ip) async {
    final res = await _client.get(ip, ApiEndpoints.lcsButtonAction);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return data['url'] as String? ?? '';
    }
    return '';
  }

  /// Set the button action URL on an LCS device.
  Future<void> setLcsButtonAction(String ip, String url) async {
    await _client.postRawForm(ip, ApiEndpoints.lcsButtonAction, 'url=$url');
  }

  // ---- Button (single button) ----

  Future<ActionUrlConfigModel> getButtonActions(String ip) async {
    final res = await _client.get(ip, ApiEndpoints.buttonActions);
    return ActionUrlConfigModel.fromJsonActions(
      res.data as Map<String, dynamic>,
    );
  }

  Future<void> setButtonActions(String ip, ActionUrlConfigModel cfg) async {
    await _client.post(
      ip,
      ApiEndpoints.buttonActions,
      body: {'actions': cfg.actions.map((e) => e.toJson()).toList()},
    );
  }

  Future<void> buttonSleep(String ip) async {
    await _client.post(ip, ApiEndpoints.buttonSleep);
  }

  // ---- Button-se (BP2 / BM1) ----

  Future<ButtonSensorStateModel> getButtonSeSensors(String ip) async {
    final res = await _client.get(ip, ApiEndpoints.buttonSeSensors);
    return ButtonSensorStateModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> setButtonSeAction(
    String ip, {
    required String referer,
    required String action,
    required String url,
  }) async {
    await _client.postRawText(
      ip,
      '${ApiEndpoints.buttonSeAction}/$referer/$action',
      url,
    );
  }

  Future<Map<String, String>> getButtonSeActions(
    String ip, {
    required String referer,
  }) async {
    final res = await _client.get(
      ip,
      '${ApiEndpoints.buttonSeActions}/$referer',
    );
    final j = res.data as Map<String, dynamic>;
    return j.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<ActionUrlConfigModel> getAllButtonSeActions(String ip) async {
    final res = await _client.get(ip, ApiEndpoints.buttonSeActions);
    return ActionUrlConfigModel.fromJsonButtonSe(
      res.data as Map<String, dynamic>,
    );
  }

  Future<void> buttonSeSleep(String ip) async {
    await _client.post(ip, ApiEndpoints.buttonSeSleep);
  }

  // ---- Scheduler (firmware >= 5.0.0) ----
  //
  // Only available on WS2, WSE, WRS, WMS (PIR), WSX and WLL.
  // Times are stored as UTC on the device; callers convert local <-> UTC.

  Future<List<SchedulerItem>> getScheduler(String ip) async {
    final res = await _client.get(ip, ApiEndpoints.scheduler);
    final data = res.data;
    if (data is! List) return const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(SchedulerItem.fromJson)
        .toList();
  }

  /// Replaces the whole scheduler list. The device returns the stored list.
  Future<List<SchedulerItem>> setScheduler(
    String ip,
    List<SchedulerItem> items,
  ) async {
    final body = items.map((i) => i.toJson()).toList();
    final res = await _client.post(
      ip,
      ApiEndpoints.scheduler,
      body: body,
      contentType: 'application/json',
    );
    final data = res.data;
    if (data is! List) return const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(SchedulerItem.fromJson)
        .toList();
  }

  // ---- Identification ----

  /// Standard identification blink. Used by WS2, WSE, WRS, WLL, WMS (PIR).
  ///
  /// `POST /identify` returns 204 on success. When the device is paired with
  /// HomeKit this endpoint is part of the HomeKit API and returns 400. Any
  /// error (400, timeout, network) must be silently ignored by the caller —
  /// identification is best-effort.
  Future<void> identify(String ip) async {
    try {
      await _client.post(ip, ApiEndpoints.identify);
    } catch (_) {
      // Swallow — identification is best-effort.
    }
  }

  /// Bulb identification via the timer API.
  ///
  /// `POST /api/v1/timer/<mac>?mode=toggle&time=3&color=120;100;100`
  /// triggers a 3-second toggle blink with a green hue. The MAC here is the
  /// device's own MAC (the `<SELF>` placeholder from `/help`), without
  /// colons. As with [identify], any error is silently ignored.
  ///
  /// The query string is built and sent raw: Dio's `queryParameters`
  /// URL-encodes values, which would turn `120;100;100` into
  /// `120%3B100%3B100` — the bulb firmware rejects that, so the
  /// semicolons must reach the device verbatim.
  Future<void> identifyBulb(String ip, String mac) async {
    try {
      final cleanMac = mac.replaceAll(':', '');
      final path = '${ApiEndpoints.bulbTimerPrefix}$cleanMac';
      const rawQuery = 'mode=toggle&time=3&color=120;100;100';
      await _client.postRawQuery(ip, path, rawQuery);
    } catch (_) {
      // Swallow — identification is best-effort.
    }
  }
}
