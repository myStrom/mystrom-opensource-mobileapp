import '../../l10n/app_localizations.dart';

/// Display label for internal category keys (`All`, `Favorite`, or a room name).
String categoryDisplayLabel(String categoryKey, AppLocalizations l10n) {
  switch (categoryKey) {
    case 'All':
      return l10n.categoryAll;
    case 'Favorite':
      return l10n.categoryFavorite;
    default:
      return categoryKey;
  }
}
