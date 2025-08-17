import 'package:shared_preferences/shared_preferences.dart';

class LanguageHelper {
  static Future<String?> getCurrentLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('language_code'); // إرجاع اللغة المخزنة في SharedPreferences
  }

  static Future<void> setLanguage(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode); // حفظ اللغة في SharedPreferences
  }
}
