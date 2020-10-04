import 'package:flutter/material.dart';
import 'package:male/Localizations/app_localizations.dart';

V nullSafeMapValue<K, V>(Map<K, V> map, K key) {
  if (map?.containsKey(key) ?? false) return map[key];
  return null;
}

String getLocalizedName(
  Map<String, String> localizedName,
  BuildContext context,
) {
  var currentLocale = AppLocalizations.of(context).locale;
  var primaryLocale = AppLocalizations.supportedLocales.first;
  var currentLocalized = nullSafeMapValue<String, String>(
      localizedName, currentLocale.languageCode);
  if ((currentLocalized?.length ?? 0) > 0) return currentLocalized;

  var primaryLocalized = nullSafeMapValue<String, String>(
      localizedName, primaryLocale.languageCode);
  if ((primaryLocalized?.length ?? 0) > 0) return primaryLocalized;

  return '';
}
