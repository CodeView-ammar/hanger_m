import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// خدمة التخزين الآمن للبيانات الحساسة
class SecureStorageService {
  static var _storage = FlutterSecureStorage(
    // aOptions: const AndroidOptions(
    //   encryptedSharedPreferences: true,
    // ),
    // iOptions: const IOSOptions(
    //   accessibility: IOSAccessibility.first_unlock,
    // ),
  );

  /// حفظ بيانات المستخدم بشكل آمن
  static Future<void> saveUserData({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    String? address,
  }) async {
    final userData = {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address ?? '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _storage.write(
      key: 'user_data',
      value: jsonEncode(userData),
    );
  }

  /// استرجاع بيانات المستخدم المحفوظة
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userData = await _storage.read(key: 'user_data');
      if (userData != null) {
        return jsonDecode(userData);
      }
    } catch (e) {
      print('خطأ في استرجاع بيانات المستخدم: $e');
    }
    return null;
  }

  /// حفظ معرف المستخدم
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userid', userId);
  }

  /// استرجاع معرف المستخدم
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userid');
  }

  /// مسح جميع البيانات المحفوظة
  static Future<void> clearAllData() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// التحقق من وجود بيانات المستخدم
  static Future<bool> hasUserData() async {
    final userData = await getUserData();
    return userData != null && userData['userId'] != null;
  }
}
