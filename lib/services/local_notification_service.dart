import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class LocalNotificationService {
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static StreamController<NotificationResponse> streamController =
      StreamController();
  static onTap(NotificationResponse notificationResponse) {
    // log(notificationResponse.id!.toString());
    // log(notificationResponse.payload!.toString());
    streamController.add(notificationResponse);
    // Navigator.push(context, route);
  }

  static Future init() async {
    InitializationSettings settings = const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: onTap,
      onDidReceiveBackgroundNotificationResponse: onTap,
    );
  }

static void showBasicNotification(RemoteMessage message) async {
  AndroidNotificationDetails android;

  if (message.notification?.android?.imageUrl != null &&
      message.notification!.android!.imageUrl!.isNotEmpty) {
    try {
      // جلب الصورة من الرابط
      final http.Response image = await http.get(
        Uri.parse(message.notification!.android!.imageUrl!),
      );

      BigPictureStyleInformation bigPictureStyleInformation =
          BigPictureStyleInformation(
        ByteArrayAndroidBitmap.fromBase64String(base64Encode(image.bodyBytes)),
        largeIcon:
            ByteArrayAndroidBitmap.fromBase64String(base64Encode(image.bodyBytes)),
      );

      android = AndroidNotificationDetails(
        'id_1',
        'basic_notification',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(
            'sound'.split('.').first), // اسم ملف الصوت بدون الامتداد
        styleInformation: bigPictureStyleInformation,
      );
    } catch (e) {
      // في حال فشل تحميل الصورة، عرض الإشعار العادي
      android =const AndroidNotificationDetails(
        'id_1',
        'basic_notification',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('sound'),
      );
    }
  } else {
    // إشعار عادي بدون صورة
    android =const AndroidNotificationDetails(
      'id_1',
      'basic_notification',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('sound'),
    );
  }

  NotificationDetails details = NotificationDetails(android: android);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? '',
    message.notification?.body ?? '',
    details,
  );
}

  static void cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
