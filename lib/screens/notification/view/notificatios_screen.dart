import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];  // قائمة لتخزين الإشعارات
  bool isLoading = true; // لتحديد ما إذا كان التحميل جارياً
  String userId = ''; // تخزين معرف المستخدم

  // جلب اسم المستخدم من الكاش
  Future<void> fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userid') ?? '';  // استرجاع اسم المستخدم من SharedPreferences
    });
    fetchNotifications();  // جلب الإشعارات بعد استرجاع المستخدم
  }

  // جلب الإشعارات من API
  Future<void> fetchNotifications() async {
    if (userId.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final response = await http.get(Uri.parse('${APIConfig.notificationsEndpoint}?user=$userId'));

    if (response.statusCode == 200) {
      // إذا كانت الاستجابة ناجحة، نقوم بفك تشفير البيانات
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        notifications = List<Map<String, dynamic>>.from(data.map((item) => {
          'id': item['id'],  // استخراج id
          'message': item['message'],  // استخراج الرسالة
          'status': item['status']  // استخراج حالة الإشعار
        }));
        isLoading = false;  // بعد جلب البيانات، ننهي تحميل الصفحة
      });
    } else {
      // في حالة حدوث خطأ، يمكن التعامل مع ذلك هنا
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في جلب الإشعارات')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserId();  // جلب اسم المستخدم عند تحميل الشاشة
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // العودة إلى الشاشة السابقة
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())  // عرض مؤشر التحميل أثناء الجلب
          : notifications.isEmpty
              ? const Center(child: Text('لا توجد إشعارات حاليا'))  // إذا كانت القائمة فارغة
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return NotificationTile(
                      notification: notifications[index]['message'],  // استخدام الرسالة
                      notificationId: notifications[index]['id'],  // استخدام الـ ID الفعلي
                      status: notifications[index]['status'],  // إضافة حالة الإشعار
                      onNotificationRead: fetchNotifications,  // تمرير الدالة لتحديث الإشعارات
                    );
                  },
                ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final String notification;
  final int notificationId;  // ID للإشعار
  final String status;  // حالة الإشعار
  final Future<void> Function() onNotificationRead; // دالة لتحديث الإشعارات

  const NotificationTile({
    Key? key,
    required this.notification,
    required this.notificationId,
    required this.status,
    required this.onNotificationRead,
  }) : super(key: key);

  // دالة لتحديث حالة الإشعار عند فتحه
  Future<void> markAsRead(int notificationId) async {
    final response = await http.post(
      Uri.parse('${APIConfig.notificationsEndpoint}$notificationId/mark_as_read/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // حالة الإشعار تم تحديثها إلى مقروء
      print('تم تحديث الإشعار إلى مقروء');
    } else {
      // فشل في التحديث
      print('فشل في تحديث حالة الإشعار');
    }
  }

  // دالة لاختيار الأيقونة بناءً على حالة الإشعار
  IconData getIconForStatus(String status) {
    switch (status) {
      case 'error':
        return Icons.error_outline;  // أيقونة الخطأ
      case 'confirmation':
        return Icons.check_circle_outline;  // أيقونة التأكيد
      default:
        return Icons.notification_important;  // الأيقونة الافتراضية
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(getIconForStatus(status), color: Colors.blue),
      title: Text(utf8.decode(notification.codeUnits)),
      subtitle: const Text('تفاصيل', style: TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        // تحديث حالة الإشعار عند النقر
        await markAsRead(notificationId);

        // التوجيه إلى شاشة تفاصيل الرسالة
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationDetailsScreen(notification: notification),
          ),
        );

        // تحديث الإشعارات عند العودة
        onNotificationRead();
      },
    );
  }
}

// شاشة تفاصيل الرسالة
class NotificationDetailsScreen extends StatelessWidget {
  final String notification;

  const NotificationDetailsScreen({Key? key, required this.notification}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الإشعار'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);  // العودة إلى الشاشة السابقة
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تفاصيل الإشعار:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              utf8.decode(notification.codeUnits), // عرض النص المشفر بشكل صحيح
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
