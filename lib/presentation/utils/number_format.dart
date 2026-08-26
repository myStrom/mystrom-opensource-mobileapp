import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// Locale-aware formatting for the numeric readings shown in the UI.
///
/// The separators differ per locale we ship: `en` and `de_CH` use a dot as
/// decimal separator, `de` uses a comma. Grouping differs as well (`1,234.5`
/// vs `1'234.5` vs `1.234,5`), so raw `toStringAsFixed` would be wrong in at
/// least one locale no matter which one it is written for.
NumberFormat decimalFormat(Locale locale, int decimals) =>
    NumberFormat.decimalPatternDigits(
      locale: locale.toLanguageTag(),
      decimalDigits: decimals,
    );

/// Formats [value] with exactly [decimals] fraction digits in the locale that
/// is active for [context].
String formatDecimal(BuildContext context, num value, int decimals) =>
    decimalFormat(Localizations.localeOf(context), decimals).format(value);
