import 'dart:developer';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/services/local_notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PushNotificationsService {
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;
  static final String apiUrl = APIConfig.updatefcmEndpoint;

  static Future<void> init() async {
    // طلب صلاحيات الإشعارات
    await messaging.requestPermission();

    // جلب التوكن الحالي وإرساله
    String? token = await messaging.getToken();
    if (token != null) {
      await sendTokenToServer(token);
      log("FCM Token: $token");
    }

    // الاستماع لتحديث التوكن تلقائياً
    messaging.onTokenRefresh.listen((newToken) async {
      await sendTokenToServer(newToken);
      log("FCM Token refreshed: $newToken");
    });

    // تعيين الخلفية
    FirebaseMessaging.onBackgroundMessage(handlerBackgroundMessage);

    // استماع الرسائل أثناء عمل التطبيق في الواجهة
    handleForegroundMessage();
  }

  static void handleForegroundMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LocalNotificationService.showBasicNotification(message);
    });
  }

  // دالة إرسال التوكن للسيرفر
  static Future<void> sendTokenToServer(String newToken) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userid'); // تحقق من تسجيل الدخول
      if (userId == null) {
        log("User not logged in");
        return;
      }

      String? savedToken = prefs.getString('fcm_token');

      if (savedToken == null) {
        // إذا لم يكن هناك توكن محفوظ، قم بإضافته
        await saveToken(newToken, userId);
      } else if (savedToken != newToken) {
        // إذا كان التوكن محفوظًا مختلفًا، قم بتحديثه
        await saveToken(newToken, userId);
      } else {
        log("FCM token unchanged, no need to send");
      }
    } catch (e) {
      log("Error sending FCM token: $e");
    }
  }

  // دالة لحفظ التوكن في السيرفر
  static Future<void> saveToken(String newToken, String userId) async {
    try {
      print("apiUrl"*100);
      print(apiUrl);
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "user_id": userId,
          "fcm": newToken,
        }),
      );

      if (response.statusCode == 200) {
        log("FCM token sent successfully");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', newToken);
      } else {
        log("Failed to send FCM token. Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      log("Error saving FCM token: $e");
    }
  }

  // دالة استقبال الرسائل في الخلفية
  static Future<void> handlerBackgroundMessage(RemoteMessage message) async {
    await Firebase.initializeApp();
    log("Background message title: ${message.notification?.title ?? "null"}");
    LocalNotificationService.showBasicNotification(message);
  }
}