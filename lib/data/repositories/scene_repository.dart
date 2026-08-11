import '../datasources/scene_local_ds.dart';
import '../models/scene.dart';

/// CRUD repository wrapping the local Hive data source for scenes.
class SceneRepository {
  SceneRepository(this._local);

  final SceneLocalDataSource _local;

  List<Scene> getAll() => _local.getAll();

  Scene? getById(String id) => _local.getById(id);

  Future<void> save(Scene scene) => _local.upsert(scene);

  Future<void> remove(String id) => _local.delete(id);
}
