import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSettings extends ChangeNotifier {
  SharedPreferences prefs;
  ValueNotifier<Locale> userLocale = ValueNotifier(null);
  LanguageSettings();
  void init() async {
    prefs = await SharedPreferences.getInstance();
  }

  void setLocale(Locale locale) {
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

  static Locale fromMap(Map<String, String> map) {
    return Locale.fromSubtags(
        countryCode: map['countryCode'],
        languageCode: map['languageCode'],
        scriptCode: map['scriptCode']);
  }
}
