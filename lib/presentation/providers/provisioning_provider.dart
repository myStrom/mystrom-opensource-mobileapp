import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/network/wifi_platform.dart';
import '../../data/models/device_info.dart';
import '../../data/models/wifi_network.dart';
import '../../domain/usecases/provision_wifi.dart';

/// Coarse stage of the SoftAP provisioning wizard.
enum ProvisioningStage {
  /// Waiting for the user to pick / connect to a device AP.
  selectAp,

  /// Connected to the AP; scanning for home WiFi networks via the device.
  scanNetworks,

  /// User is filling in SSID/password + advanced options.
  enterCredentials,

  /// POST /api/v1/connect in flight.
  sending,

  /// Device accepted credentials and is rebooting onto the home WiFi.
  done,

  /// Terminal error state — [error] holds the message.
  error,
}

/// Full state for the WiFi provisioning wizard (SoftAP + WPS).
///
/// The SoftAP flow is a small state machine:
///
///   selectAp → scanNetworks → enterCredentials → sending → done
///
/// At each transition the provider talks to the device (HTTP) and/or
/// the host WiFi stack ([WifiPlatform]). The UI rebuilds on every
/// [notifyListeners] and renders a step appropriate for [stage].
class ProvisioningProvider extends ChangeNotifier {
  ProvisioningProvider(this._usecase, {WifiPlatform? wifiPlatform})
    : _wifi = wifiPlatform ?? createDefaultWifiPlatform();

  final ProvisionWifi _usecase;
  final WifiPlatform _wifi;

  // ---- State ----

  ProvisioningStage _stage = ProvisioningStage.selectAp;
  ProvisioningStage get stage => _stage;

  bool _busy = false;
  bool get busy => _busy;

  /// Convenience flags derived from [stage] / [busy] for the legacy UI.
  bool get scanning => _busy && _stage == ProvisioningStage.scanNetworks;
  bool get sending => _busy && _stage == ProvisioningStage.sending;

  /// Candidate myStrom APs visible to the host WiFi.
  List<WifiApCandidate> _apCandidates = const [];
  List<WifiApCandidate> get apCandidates => _apCandidates;

  /// The AP the user selected (and we are talking to).
  WifiApCandidate? _selectedAp;
  WifiApCandidate? get selectedAp => _selectedAp;

  /// Device `/api/v1/info` fetched after joining the AP, if available.
  /// Used to confirm the exact [DeviceType] and MAC.
  DeviceInfoModel? _deviceInfo;
  DeviceInfoModel? get deviceInfo => _deviceInfo;

  /// Home WiFi networks visible to the device (from `GET /api/v1/scan`).
  List<WifiNetworkModel> _networks = const [];
  List<WifiNetworkModel> get networks => _networks;

  String? _error;
  String? get error => _error;

  // ---- AP selection ----

  /// Scan the host WiFi for myStrom device APs.
  Future<void> scanForAps() async {
    debugPrint('[provision] scanForAps called, platform=${_wifi.runtimeType}');
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _apCandidates = await _wifi.scanMyStromAps();
      debugPrint('[provision] scanForAps returned ${_apCandidates.length} APs');
      if (_apCandidates.isEmpty) {
        _error = null; // empty list is not an error — just no devices found
      }
    } on PlatformException catch (e) {
      debugPrint(
        '[provision] scanForAps PlatformException: ${e.code} ${e.message}',
      );
      _error = e.message ?? e.code;
    } catch (e) {
      debugPrint('[provision] scanForAps error: $e');
      _error = 'Could not scan WiFi: $e';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// User picked an AP from the list (or entered its SSID manually).
  ///
  /// We record the selection, ask the OS to join the AP, then optionally
  /// fetch `/api/v1/info` to confirm the device type & MAC. After that
  /// we move to [ProvisioningStage.scanNetworks] so the user can pick
  /// the home WiFi.
  Future<void> selectAp(WifiApCandidate ap) async {
    _selectedAp = ap;
    _deviceInfo = null;
    _networks = const [];
    _busy = true;
    _error = null;
    notifyListeners();

    // Ask the OS to join the device AP. On desktop this is a no-op
    // (the user connects manually); on mobile it may open the system
    // picker. Either way we proceed and let the HTTP calls fail
    // gracefully if the host is not actually on the AP.
    try {
      await _wifi.connectToAp(ap.ssid);
    } catch (e) {
      debugPrint('[provision] connectToAp failed: $e');
    }

    // Confirm the device type / MAC via /api/v1/info. This is best-effort:
    // older firmware may not answer, in which case we keep the SSID-based
    // [DeviceType] guess from the AP prefix.
    try {
      _deviceInfo = await _usecase.fetchInfo();
    } catch (e) {
      debugPrint('[provision] fetchInfo failed: $e');
    }

    _stage = ProvisioningStage.scanNetworks;
    _busy = false;
    notifyListeners();
  }

  /// Skip the device-side WiFi scan and go straight to credential entry
  /// (used for hidden networks or when the scan returns nothing).
  void skipToCredentials() {
    _stage = ProvisioningStage.enterCredentials;
    notifyListeners();
  }

  // ---- Device-side WiFi scan ----

  /// Scan for home WiFi networks through the device (default AP IP).
  Future<void> scanNetworks([String? ip]) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _networks = await _usecase.scanNetworks(ip);
      _stage = ProvisioningStage.enterCredentials;
    } catch (e) {
      _error = e.toString();
      _stage = ProvisioningStage.error;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // ---- Send credentials ----

  /// Send WiFi credentials to the device. On success transitions to
  /// [ProvisioningStage.done] and asks the OS to disconnect from the
  /// device AP so the host rejoins its home WiFi automatically.
  ///
  /// Returns `true` on success.
  Future<bool> sendCredentials(
    String ssid,
    String? password, {
    String? ip,
    String? staticIp,
    String? mask,
    String? gw,
    String? dns,
    bool roaming = false,
  }) async {
    _busy = true;
    _error = null;
    _stage = ProvisioningStage.sending;
    notifyListeners();
    try {
      await _usecase.sendCredentials(
        ssid,
        password,
        ip: ip,
        staticIp: staticIp,
        mask: mask,
        gw: gw,
        dns: dns,
        roaming: roaming,
      );
      _stage = ProvisioningStage.done;
      return true;
    } on DioException catch (e) {
      // The device starts shutting down its AP *immediately* after
      // accepting /api/v1/connect, so the HTTP response often never
      // arrives (connection reset / receive timeout). Treat those as
      // success — the credentials were almost certainly received.
      final dropped =
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout;
      if (dropped) {
        debugPrint(
          '[provision] connect response dropped (${e.type}) — '
          'treating as success',
        );
        _stage = ProvisioningStage.done;
        return true;
      }
      _error = e.toString();
      _stage = ProvisioningStage.error;
      return false;
    } catch (e) {
      _error = e.toString();
      _stage = ProvisioningStage.error;
      return false;
    } finally {
      // The device AP is going down — tell the OS to drop it so the
      // host rejoins the home WiFi. Best-effort; ignored on desktop.
      if (_selectedAp != null) {
        try {
          await _wifi.disconnectFromAp(_selectedAp!.ssid);
        } catch (e) {
          debugPrint('[provision] disconnectFromAp failed: $e');
        }
      }
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> triggerWps([String? ip]) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _usecase.triggerWps(ip);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Reset the wizard back to the AP-selection step.
  void reset() {
    _stage = ProvisioningStage.selectAp;
    _selectedAp = null;
    _deviceInfo = null;
    _networks = const [];
    _apCandidates = const [];
    _error = null;
    _busy = false;
    notifyListeners();
  }
}
