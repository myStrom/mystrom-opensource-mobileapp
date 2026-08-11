import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/scene.dart';
import '../../data/repositories/scene_repository.dart';
import '../../data/repositories/device_repository.dart';
import '../../domain/usecases/run_scene.dart';

/// Manages scenes (create/update/delete) and runs them against the
/// current device IPs provided by [DeviceRepository].
class SceneProvider extends ChangeNotifier {
  SceneProvider({
    required this._sceneRepo,
    required this._deviceRepo,
    required this._runScene,
  });

  final SceneRepository _sceneRepo;
  final DeviceRepository _deviceRepo;
  final RunScene _runScene;
  static const _uuid = Uuid();

  List<Scene> _scenes = [];
  List<Scene> get scenes => _scenes;

  void refresh() {
    _scenes = _sceneRepo.getAll();
    notifyListeners();
  }

  Future<void> saveScene(Scene scene) async {
    await _sceneRepo.save(scene);
    refresh();
  }

  Future<void> deleteScene(String id) async {
    await _sceneRepo.remove(id);
    refresh();
  }

  /// Runs a scene: executes all its actions sequentially. Returns a list of
  /// device names that failed (empty = all ok).
  Future<List<String>> runScene(Scene scene) async {
    final failed = await _runScene(
      scene,
      resolveIp: (mac) {
        final s = _deviceRepo.getByMac(mac);
        return s?.lastKnownIp;
      },
      isLocked: (mac) => _deviceRepo.getByMac(mac)?.lockable ?? false,
    );
    return failed;
  }

  /// Creates a new empty scene with sensible defaults.
  Scene createDraft({
    String name = 'New scene',
    int iconCode = 0xe318, // Icons.home
    int colorValue = 0xFF2196F3, // Colors.blue
  }) {
    final scene = Scene(
      id: _uuid.v4(),
      name: name,
      iconCode: iconCode,
      colorValue: colorValue,
    );
    return scene;
  }
}
