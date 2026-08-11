import '../../core/utils/device_type.dart';
import '../datasources/device_remote_ds.dart';
import '../models/action_url_config.dart';

/// Configures button action URLs.
///
/// Builds URLs from a target device + action, then pushes them to the
/// button device via the appropriate API (JSON blob or button-se
/// raw URL string).
class ActionConfigRepository {
  ActionConfigRepository(this._remote);

  final DeviceRemoteDataSource _remote;

  /// Construct an action URL for a target device.
  ///
  /// Returns the URL string that the button should request when pressed.
  ///
  /// The scheme defines the HTTP method: `get://`, `post://`, `put://`,
  /// `delete://`.  For POST/PUT, the query string is sent as the body
  /// instead of being appended to the URL.
  static String buildActionUrl({
    required String targetIp,
    required DeviceType targetType,
    required String action, // toggle | on | off | color
    String? color,
    int? ramp,
    String? mode,
  }) {
    switch (targetType) {
      case DeviceType.ws2:
      case DeviceType.wse:
      case DeviceType.wsx:
      case DeviceType.lcs:
        switch (action) {
          case 'toggle':
            return 'get://$targetIp/toggle';
          case 'on':
            return 'post://$targetIp/relay?action=on';
          case 'off':
            return 'post://$targetIp/relay?action=off';
          default:
            return 'get://$targetIp/toggle';
        }
      case DeviceType.wrs:
        final params = <String>[];
        params.add('action=${action == 'toggle' ? 'toggle' : action}');
        if (color != null) params.add('color=$color');
        if (ramp != null) params.add('ramp=$ramp');
        if (mode != null) params.add('mode=$mode');
        return 'post://$targetIp/device?${params.join("&")}';
      case DeviceType.wll:
        final params = <String>[];
        params.add('action=$action');
        if (ramp != null) params.add('ramp=$ramp');
        return 'post://$targetIp/device?${params.join("&")}';
      case DeviceType.bulb:
        final params = <String>[];
        params.add('action=${action == 'toggle' ? 'toggle' : action}');
        if (color != null) params.add('color=$color');
        if (ramp != null) params.add('ramp=$ramp');
        if (mode != null) params.add('mode=$mode');
        return 'post://$targetIp/api/v1/device/self?${params.join("&")}';
      default:
        return 'get://$targetIp/';
    }
  }

  // ---- Button (single button) ----

  Future<ActionUrlConfigModel> getButtonActionsConfig(String ip) {
    return _remote.getButtonActions(ip);
  }

  Future<void> setButtonActionsConfig(String ip, ActionUrlConfigModel cfg) =>
      _remote.setButtonActions(ip, cfg);

  // ---- Button-se (BP2 / BM1) ----

  Future<void> setButtonSeAction({
    required String ip,
    required String referer,
    required String action,
    required String url,
  }) {
    return _remote.setButtonSeAction(
      ip,
      referer: referer,
      action: action,
      url: url,
    );
  }

  Future<Map<String, String>> getButtonSeActions(
    String ip, {
    required String referer,
  }) => _remote.getButtonSeActions(ip, referer: referer);

  Future<ActionUrlConfigModel> getAllButtonSeActions(String ip) =>
      _remote.getAllButtonSeActions(ip);
}
