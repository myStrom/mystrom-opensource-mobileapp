import 'package:hive/hive.dart';

part 'scene.g.dart';

/// A scene is a named bundle of device actions triggered together
/// (e.g. "Arrive Home", "Good Night").
@HiveType(typeId: 1)
class Scene extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int iconCode;

  @HiveField(3)
  int colorValue;

  @HiveField(4)
  List<SceneAction> actions;

  Scene({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    List<SceneAction>? actions,
  }) : actions = actions ?? [];
}

/// One action within a scene: turn a specific device on/off/toggle.
@HiveType(typeId: 2)
class SceneAction extends HiveObject {
  @HiveField(0)
  String deviceMac;

  @HiveField(1)
  String deviceName;

  @HiveField(2)
  int deviceTypeCode;

  /// 'on' | 'off' | 'toggle' | 'timer'
  @HiveField(3)
  String action;

  /// Timer mode: 'on' | 'off' | 'toggle' — only used when [action] == 'timer'.
  /// HiveField 4. null for non-timer actions.
  @HiveField(4)
  String? timerMode;

  /// Timer duration in seconds — only used when [action] == 'timer'.
  /// HiveField 5. null/0 for non-timer actions.
  @HiveField(5)
  int? timerSeconds;

  SceneAction({
    required this.deviceMac,
    required this.deviceName,
    required this.deviceTypeCode,
    required this.action,
    this.timerMode,
    this.timerSeconds,
  });
}
