import 'package:flutter/material.dart';

/// Preset icons available when creating/editing a scene.
///
/// Must stay as const [IconData] references so release icon tree-shaking works.
class SceneIcon {
  const SceneIcon(this.icon, this.label);

  final IconData icon;
  final String label;
}

const List<SceneIcon> kSceneIcons = [
  SceneIcon(Icons.home, 'Arrive Home'),
  SceneIcon(Icons.nightlight_round, 'Good Night'),
  SceneIcon(Icons.wb_sunny, 'Morning'),
  SceneIcon(Icons.movie, 'Movie'),
  SceneIcon(Icons.restaurant, 'Dinner'),
  SceneIcon(Icons.work, 'Away'),
  SceneIcon(Icons.bedtime, 'Sleep'),
  SceneIcon(Icons.weekend, 'Weekend'),
  SceneIcon(Icons.lightbulb, 'Lights'),
  SceneIcon(Icons.power_settings_new, 'Power'),
];

/// Resolves a stored [codePoint] to a const [IconData] from [kSceneIcons].
IconData sceneIconForCode(int codePoint) {
  for (final entry in kSceneIcons) {
    if (entry.icon.codePoint == codePoint) return entry.icon;
  }
  return Icons.home;
}
