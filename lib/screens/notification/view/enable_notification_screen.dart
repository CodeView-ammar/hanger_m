import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:melaq/main.dart';

class EnableNotificationScreen extends StatelessWidget {
  const EnableNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // العودة إلى الشاشة السابقة
          },
        ),
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMoreOptions(context); // عرض خيارات إضافية
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Push Notifications are currently turned off',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enabling push notifications allows us to send you info about our new products, sales, events and more!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                _enableNotifications(context); // معالجة الضغط على زر تفعيل الإشعارات
              },
              child: const Text('Enable Notification'),
            ),
            const SizedBox(height: 40),
            const Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.transparent,
                  child: Icon(
                    Icons.location_on,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFD04647),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // إضافة دالة لإرسال الإشعارات
  Future<void> showNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      '1',
      'ammar',
      channelDescription: 'وصف القناة',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await flutterLocalNotificationsPlugin.show(
      0, // ID الخاص بالإشعار
      'عرض الجمعه',
      'محتوى الإشعار',
      platformDetails,
      payload: 'data',
    );
  }

  Future<void> _enableNotifications(BuildContext context) async {
    // طلب صلاحيات الإشعارات
    final status = await Permission.notification.request();

    if (status.isGranted) {
      // تم منح الصلاحيات بنجاح
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications enabled!')),
      );
      showNotification(); // إرسال إشعار عند تمكين الإشعارات
    } else if (status.isDenied) {
      // تم رفض الصلاحيات
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications permission denied!')),
      );
    } else if (status.isPermanentlyDenied) {
      // تم رفض الصلاحيات بشكل دائم
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable notifications from settings.')),
      );
      // يمكنك توجيه المستخدم إلى إعدادات التطبيق
      openAppSettings(); // فتح إعدادات التطبيق
    }
  }

  void _showMoreOptions(BuildContext context) {
    // عرض خيارات إضافية
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  // معالجة الضغط على إعدادات
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help'),
                onTap: () {
                  // معالجة الضغط على المساعدة
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
