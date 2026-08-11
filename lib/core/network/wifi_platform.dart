import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/ap_ssid.dart';
import '../utils/device_type.dart';

/// A candidate myStrom device AP detected by scanning the host's WiFi.
class WifiApCandidate {
  const WifiApCandidate({
    required this.ssid,
    required this.bssid,
    required this.signal,
    required this.type,
  });

  /// AP SSID, e.g. `my-bulb-A1B2C3`.
  final String ssid;

  /// BSSID / MAC of the AP (best-effort — may be empty on some platforms).
  final String bssid;

  /// Signal strength in dBm.
  final int signal;

  /// Resolved [DeviceType] from [ApSsidMatcher] (never null — only
  /// myStrom APs are surfaced by [WifiPlatform.scanMyStromAps]).
  final DeviceType type;

  @override
  String toString() => 'WifiApCandidate($ssid, ${signal}dBm, $type)';
}

/// Platform-agnostic interface for the host's WiFi stack.
///
/// On real devices this is backed by a platform plugin (e.g.
/// `wifi_iot` / `network_info_plus` / a native method channel). In
/// tests it is replaced by a fake so the provisioning wizard can be
/// driven end-to-end without a real WiFi adapter.
///
/// All methods are best-effort: if the platform does not support an
/// operation, it should throw [UnsupportedError] (caught by the
/// provisioning UI) rather than hanging.
abstract class WifiPlatform {
  /// Returns the SSID the host is currently connected to, or `null`
  /// when not connected / unknown.
  Future<String?> get currentSsid;

  /// Scan visible WiFi networks and return the ones that look like
  /// myStrom device APs (see [ApSsidMatcher]).
  ///
  /// This is the SSID-based scan the wizard uses to present a list of
  /// in-range devices. It is distinct from [DeviceRemoteDataSource.scanWifi],
  /// which scans from the *device's* perspective after joining its AP.
  Future<List<WifiApCandidate>> scanMyStromAps();

  /// Ask the OS to join the open myStrom AP with [ssid].
  ///
  /// Returns `true` if the OS reports success (or queued the request).
  /// On mobile platforms this typically opens the system WiFi picker;
  /// on desktop it is usually a no-op and the user connects manually.
  Future<bool> connectToAp(String ssid);

  /// Ask the OS to disconnect from [ssid] (or the current network).
  ///
  /// Used after `/api/v1/connect` to release the device AP so the OS
  /// rejoins the user's home WiFi automatically.
  Future<bool> disconnectFromAp(String ssid);
}

/// No-op [WifiPlatform] used when no platform plugin is available
/// (e.g. running on Windows desktop, or in tests that do not care
/// about real WiFi).
///
/// Every method reports "unsupported" by throwing [UnsupportedError]
/// except [scanMyStromAps], which returns an empty list so the manual
/// flow still works.
class StubWifiPlatform implements WifiPlatform {
  const StubWifiPlatform();

  @override
  Future<String?> get currentSsid async {
    throw UnsupportedError('WiFi SSID not available on this platform');
  }

  @override
  Future<List<WifiApCandidate>> scanMyStromAps() async => const [];

  @override
  Future<bool> connectToAp(String ssid) async {
    debugPrint('[WifiPlatform] connectToAp($ssid) — stub, no-op');
    return false;
  }

  @override
  Future<bool> disconnectFromAp(String ssid) async {
    debugPrint('[WifiPlatform] disconnectFromAp($ssid) — stub, no-op');
    return false;
  }
}

/// Android-backed [WifiPlatform] that uses a `MethodChannel` to talk to
/// the native Kotlin `MainActivity` which performs `WifiManager.startScan()`.
///
/// On Android the SSID scan requires runtime permission (fine location on
/// Android 6–12, nearby Wi-Fi devices on Android 13+). The native side
/// requests it automatically on first `scanMyStromAps` call and delivers
/// the results asynchronously via the same `MethodChannel.Result`.
///
/// Programmatic AP connect/disconnect is not possible on Android 10+, so
/// those methods return `false` (the user connects manually).
class AndroidWifiPlatform implements WifiPlatform {
  AndroidWifiPlatform({String channelName = 'mystrom.local/wifi'})
    : _channel = MethodChannel(channelName);

  final MethodChannel _channel;

  @override
  Future<String?> get currentSsid async {
    try {
      return await _channel.invokeMethod<String>('getCurrentSsid');
    } catch (e) {
      debugPrint('[AndroidWifi] getCurrentSsid failed: $e');
      return null;
    }
  }

  @override
  Future<List<WifiApCandidate>> scanMyStromAps() async {
    debugPrint('[AndroidWifi] scanMyStromAps invoking channel...');
    final raw = await _channel.invokeMethod<List<dynamic>>('scanMyStromAps');
    debugPrint(
      '[AndroidWifi] scanMyStromAps returned: ${raw?.length ?? 0} items',
    );
    if (raw == null) return const [];
    final out = <WifiApCandidate>[];
    for (final item in raw) {
      final map = item as Map<dynamic, dynamic>;
      final ssid = map['ssid'] as String? ?? '';
      if (ssid.isEmpty) continue;
      final type = ApSsidMatcher.match(ssid) ?? DeviceType.unknown;
      out.add(
        WifiApCandidate(
          ssid: ssid,
          bssid: map['bssid'] as String? ?? '',
          signal: (map['signal'] as num?)?.toInt() ?? -100,
          type: type,
        ),
      );
    }
    debugPrint('[AndroidWifi] parsed ${out.length} myStrom APs');
    return out;
  }

  @override
  Future<bool> connectToAp(String ssid) async {
    try {
      return await _channel.invokeMethod<bool>('connectToAp', ssid) ?? false;
    } catch (e) {
      debugPrint('[AndroidWifi] connectToAp failed: $e');
      return false;
    }
  }

  @override
  Future<bool> disconnectFromAp(String ssid) async {
    try {
      return await _channel.invokeMethod<bool>('disconnectFromAp', ssid) ??
          false;
    } catch (e) {
      debugPrint('[AndroidWifi] disconnectFromAp failed: $e');
      return false;
    }
  }
}

/// Auto-select the best [WifiPlatform] for the current runtime.
/// Returns [AndroidWifiPlatform] on Android, [StubWifiPlatform] elsewhere.
WifiPlatform createDefaultWifiPlatform() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return AndroidWifiPlatform();
  }
  return const StubWifiPlatform();
}
