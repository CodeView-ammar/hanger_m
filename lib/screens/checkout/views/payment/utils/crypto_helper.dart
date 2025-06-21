import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import '../config/environment.dart';

/// مساعد التشفير للبيانات الحساسة
class CryptoHelper {
  static late final Encrypter _encrypter;
  static late final IV _iv;

  /// تهيئة التشفير
  static void initialize() {
    final key = Key.fromBase64(base64Encode(
      Environment.encryptionKey.padRight(32, '0').substring(0, 32).codeUnits,
    ));
    _encrypter = Encrypter(AES(key));
    _iv = IV.fromSecureRandom(16);
  }

  /// تشفير النص
  static String encrypt(String plainText) {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      throw Exception('فشل في تشفير البيانات: $e');
    }
  }

  /// فك التشفير
  static String decrypt(String encryptedText) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      throw Exception('فشل في فك تشفير البيانات: $e');
    }
  }

  /// إنشاء hash آمن
  static String createHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// التحقق من صحة hash
  static bool verifyHash(String data, String hash) {
    return createHash(data) == hash;
  }

  /// إنشاء token عشوائي آمن
  static String generateSecureToken(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = SecureRandom();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }
}

/// مولد أرقام عشوائية آمن
class SecureRandom {
  static final _random = Random.secure();

  int nextInt(int max) => _random.nextInt(max);
  double nextDouble() => _random.nextDouble();
  bool nextBool() => _random.nextBool();
}
