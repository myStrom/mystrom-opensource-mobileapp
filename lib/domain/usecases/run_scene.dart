import '../../core/network/api_endpoints.dart';
import '../../core/utils/device_type.dart';
import '../../data/datasources/device_remote_ds.dart';
import '../../data/models/scene.dart';

/// Executes all actions of a scene in order.
///
/// Each [SceneAction] targets a device by MAC; the caller is responsible
/// for resolving the current IP (from discovery or stored). Action types:
/// 'on', 'off', 'toggle' — mapped to the appropriate endpoint per device
/// type. Failures of individual actions do not abort the whole scene.
class RunScene {
  RunScene(this._remote);

  final DeviceRemoteDataSource _remote;

  /// Runs [scene]. [resolveIp] maps a device MAC to its current best IP
  /// (or null if not reachable). [isLocked] maps a MAC to whether its
  /// on/off is locked — locked devices are skipped for on/off/toggle
  /// actions. Returns a list of failures (device names that could not be
  /// reached, rejected the action, or were skipped because they are locked).
  Future<List<String>> call(
    Scene scene, {
    required String? Function(String mac) resolveIp,
    bool Function(String mac)? isLocked,
  }) async {
    final failed = <String>[];
    for (final action in scene.actions) {
      if (isLocked != null && isLocked(action.deviceMac)) {
        // Skip locked devices: do not change their on/off state.
        continue;
      }
      final ip = resolveIp(action.deviceMac);
      if (ip == null) {
        failed.add(action.deviceName);
        continue;
      }
      try {
        await _runAction(action, ip);
      } catch (_) {
        failed.add(action.deviceName);
      }
    }
    return failed;
  }

  Future<void> _runAction(SceneAction action, String ip) async {
    final type = DeviceType.fromCode(action.deviceTypeCode);
    switch (action.action) {
      case 'on':
        await _setOn(type, ip, true);
        break;
      case 'off':
        await _setOn(type, ip, false);
        break;
      case 'timer':
        await _runTimer(type, ip, action);
        break;
      case 'toggle':
      default:
        await _toggle(type, ip);
        break;
    }
  }

  Future<void> _setOn(DeviceType type, String ip, bool on) async {
    final action = on ? 'on' : 'off';
    if (type.isSwitch) {
      await _remote.setRelay(ip, on: on);
    } else if (type.isStrip) {
      await _remote.setStripState(ip, action: action);
    } else if (type.isDimmer) {
      await _remote.setDimmerState(ip, action: action);
    } else if (type.isBulb) {
      await _remote.setBulbState(ip, action: action);
    }
  }

  Future<void> _toggle(DeviceType type, String ip) async {
    if (type.isSwitch) {
      await _remote.toggleRelay(ip);
    } else if (type.isStrip) {
      await _remote.setStripState(ip, action: 'toggle');
    } else if (type.isDimmer) {
      await _remote.setDimmerState(ip, action: 'toggle');
    } else if (type.isBulb) {
      await _remote.setBulbState(ip, action: 'toggle');
    }
  }

  /// Run a timer action: set the device to switch to [timerMode] after
  /// [timerSeconds]. Bulb uses `/api/v1/timer/self`, others `/timer`.
  Future<void> _runTimer(DeviceType type, String ip, SceneAction action) async {
    final mode = action.timerMode ?? 'toggle';
    final seconds = action.timerSeconds ?? 0;
    if (seconds <= 0) return;
    final path = type.isBulb ? ApiEndpoints.bulbTimer : ApiEndpoints.timer;
    await _remote.setTimer(ip, mode: mode, seconds: seconds, path: path);
  }
}
