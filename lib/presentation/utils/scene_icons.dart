import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Preset icons available when creating/editing a scene.
///
/// Must stay as const [IconData] references so release icon tree-shaking works.
enum SceneIconId {
  arriveHome,
  goodNight,
  morning,
  movie,
  dinner,
  away,
  sleep,
  weekend,
  lights,
  power,
}

class SceneIcon {
  const SceneIcon(this.icon, this.id);

  final IconData icon;
  final SceneIconId id;

  String localizedLabel(AppLocalizations l10n) {
    return switch (id) {
      SceneIconId.arriveHome => l10n.sceneIconArriveHome,
      SceneIconId.goodNight => l10n.sceneIconGoodNight,
      SceneIconId.morning => l10n.sceneIconMorning,
      SceneIconId.movie => l10n.sceneIconMovie,
      SceneIconId.dinner => l10n.sceneIconDinner,
      SceneIconId.away => l10n.sceneIconAway,
      SceneIconId.sleep => l10n.sceneIconSleep,
      SceneIconId.weekend => l10n.sceneIconWeekend,
      SceneIconId.lights => l10n.sceneIconLights,
      SceneIconId.power => l10n.sceneIconPower,
    };
  }

  String localizedLabelFromContext(BuildContext context) =>
      localizedLabel(AppLocalizations.of(context));
}

const List<SceneIcon> kSceneIcons = [
  SceneIcon(Icons.home, SceneIconId.arriveHome),
  SceneIcon(Icons.nightlight_round, SceneIconId.goodNight),
  SceneIcon(Icons.wb_sunny, SceneIconId.morning),
  SceneIcon(Icons.movie, SceneIconId.movie),
  SceneIcon(Icons.restaurant, SceneIconId.dinner),
  SceneIcon(Icons.work, SceneIconId.away),
  SceneIcon(Icons.bedtime, SceneIconId.sleep),
  SceneIcon(Icons.weekend, SceneIconId.weekend),
  SceneIcon(Icons.lightbulb, SceneIconId.lights),
  SceneIcon(Icons.power_settings_new, SceneIconId.power),
];

/// Resolves a stored [codePoint] to a const [IconData] from [kSceneIcons].
IconData sceneIconForCode(int codePoint) {
  for (final entry in kSceneIcons) {
    if (entry.icon.codePoint == codePoint) return entry.icon;
  }
  return Icons.home;
}
