import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSettings extends ChangeNotifier {
  SharedPreferences prefs;
  ValueNotifier<Locale> userLocale = ValueNotifier(null);
  LanguageSettings() {
    loadSettings();
  }
  Future loadSettings() async {
    prefs = await SharedPreferences.getInstance();
    var locale = prefs?.getString('locale');
    if (locale != null) {
      userLocale.value = fromMap(jsonDecode(locale) as Map<String, dynamic>);
    }
  }

  void setLocale(Locale locale) {
    if (locale == null) {
      prefs?.remove('locale');
      userLocale.value = null;
      notifyListeners();
      return;
    }
    prefs.setString('locale', jsonEncode(locale.toMap()));
    userLocale.value = locale;
    notifyListeners();
  }
}

extension localeToJson on Locale {
  toMap() {
    return {
      'countryCode': this.countryCode,
      'languageCode': this.languageCode,
      'scriptCode': this.scriptCode
    };
  }
}

Locale fromMap(Map<String, dynamic> map) {
  return Locale.fromSubtags(
      countryCode: map['countryCode'],
      languageCode: map['languageCode'],
      scriptCode: map['scriptCode']);
}
