import 'package:hive/hive.dart';

import '../../core/config/app_config.dart';
import '../models/scene.dart';

/// Local Hive-backed data source for scenes.
class SceneLocalDataSource {
  late Box<Scene> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Scene>(AppConfig.hiveScenesBox);
  }

  List<Scene> getAll() => _box.values.toList();

  Scene? getById(String id) => _box.get(id);

  Future<void> upsert(Scene scene) => _box.put(scene.id, scene);

  Future<void> delete(String id) => _box.delete(id);
}
