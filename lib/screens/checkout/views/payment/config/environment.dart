import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// إدارة المتغيرات البيئية بشكل آمن
class Environment {
  static bool _isInitialized = false;

  /// تهيئة المتغيرات البيئية
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await dotenv.load(fileName: ".env");
      _isInitialized = true;
    } catch (e) {
      print('تحذير: لم يتم العثور على ملف .env، سيتم استخدام متغيرات النظام');
    }
  }

  /// الحصول على قيمة متغير بيئي مع قيمة افتراضية
  static String get(String key, [String defaultValue = '']) {
    return dotenv.env[key] ?? Platform.environment[key] ?? defaultValue;
  }

  /// التحقق من وجود المتغيرات المطلوبة
  static bool validateRequiredKeys() {
    final requiredKeys = [
      'PAYMOB_API_KEY',
      'PAYMOB_MERCHANT_ID',
      'PAYMOB_CARD_INTEGRATION_ID',
      'PAYMOB_IFRAME_ID',
    ];

    for (String key in requiredKeys) {
      if (get(key).isEmpty) {
        print('خطأ: المتغير البيئي $key غير موجود');
        return false;
      }
    }
    return true;
  }

  // Paymob Configuration
  static String get paymobApiKey => get('PAYMOB_API_KEY');
  static String get paymobMerchantId => get('PAYMOB_MERCHANT_ID');
  static String get paymobSecretKey => get('PAYMOB_SECRET_KEY');
  static String get paymobPublicKey => get('PAYMOB_PUBLIC_KEY');
  static String get paymobCardIntegrationId => get('PAYMOB_CARD_INTEGRATION_ID');
  static String get paymobApplePayIntegrationId => get('PAYMOB_APPLEPAY_INTEGRATION_ID');
  static String get paymobIframeId => get('PAYMOB_IFRAME_ID');

  // API Configuration
  static String get apiBaseUrl => get('API_BASE_URL', 'https://ksa.paymob.com/api');
  static int get apiTimeout => int.tryParse(get('API_TIMEOUT', '30000')) ?? 30000;

  // Encryption
  static String get encryptionKey => get('ENCRYPTION_KEY', 'default_key_change_in_production');
}
