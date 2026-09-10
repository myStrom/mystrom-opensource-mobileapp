import '../../core/utils/device_type.dart';
import '../../data/models/action_url_config.dart';
import '../../data/repositories/action_config_repository.dart';

/// Configure button action URLs.
class ConfigureButtonAction {
  ConfigureButtonAction(this._repo);

  final ActionConfigRepository _repo;

  /// Build a URL targeting [targetIp] of type [targetType] with [action].
  static String buildUrl({
    required String targetIp,
    required DeviceType targetType,
    required String action,
    String? color,
    int? ramp,
    String? mode,
  }) {
    return ActionConfigRepository.buildActionUrl(
      targetIp: targetIp,
      targetType: targetType,
      action: action,
      color: color,
      ramp: ramp,
      mode: mode,
    );
  }

  // Single-button device
  Future<ActionUrlConfigModel> getButtonActions(String ip) {
    return _repo.getButtonActionsConfig(ip);
  }

  Future<void> setButtonAction({
    required String ip,
    required String scheme,
    required String url,
    String method = 'GET',
  }) async {
    final cfg = await _repo.getButtonActionsConfig(ip);
    final actions = cfg.actions.where((a) => a.scheme != scheme).toList();
    actions.add(ActionEntry(scheme: scheme, url: url, method: method));
    await _repo.setButtonActionsConfig(
      ip,
      ActionUrlConfigModel(actions: actions),
    );
  }

  /// Remove the action configured for [scheme] on a single-button device
  /// by omitting it from the actions blob sent to the device.
  Future<void> removeButtonAction({
    required String ip,
    required String scheme,
  }) async {
    final cfg = await _repo.getButtonActionsConfig(ip);
    final actions = cfg.actions.where((a) => a.scheme != scheme).toList();
    await _repo.setButtonActionsConfig(
      ip,
      ActionUrlConfigModel(actions: actions),
    );
  }

  // Button-se
  Future<void> setButtonSeAction({
    required String ip,
    required String referer,
    required String action,
    required String url,
  }) {
    return _repo.setButtonSeAction(
      ip: ip,
      referer: referer,
      action: action,
      url: url,
    );
  }

  /// All button-se actions: map of referer -> (action -> url).
  Future<ActionUrlConfigModel> getAllButtonSeActions(String ip) {
    return _repo.getAllButtonSeActions(ip);
  }

  Future<Map<String, String>> getButtonSeActions(
    String ip, {
    required String referer,
  }) => _repo.getButtonSeActions(ip, referer: referer);
}
