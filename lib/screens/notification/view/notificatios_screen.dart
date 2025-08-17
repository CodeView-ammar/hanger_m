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

    final response = await http.get(Uri.parse('${APIConfig.notificationUserEndpoint}$userId/'));

    if (response.statusCode == 200) {
      // إذا كانت الاستجابة ناجحة، نقوم بفك تشفير البيانات
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        notifications = List<Map<String, dynamic>>.from(data.map((item) => {
          'id': item['id'],  // استخراج id
          'message': item['message'],  // استخراج الرسالة
          'status': item['status'],  // استخراج حالة الإشعار
          'created_at': item['created_at'],  // تاريخ الإنشاء
          'is_read': item['is_read']  // حالة القراءة
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
                      isRead: notifications[index]['is_read'] ?? false,  // حالة القراءة
                      createdAt: notifications[index]['created_at'] ?? '',  // تاريخ الإنشاء
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
  final bool isRead;  // حالة القراءة
  final String createdAt;  // تاريخ الإنشاء
  final Future<void> Function() onNotificationRead; // دالة لتحديث الإشعارات

  const NotificationTile({
    Key? key,
    required this.notification,
    required this.notificationId,
    required this.status,
    required this.isRead,
    required this.createdAt,
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
      case 'alert':
        return Icons.warning_amber_outlined;  // أيقونة التنبيه
      default:
        return Icons.notification_important;  // الأيقونة الافتراضية
    }
  }

  // دالة لاختيار لون الأيقونة
  Color getColorForStatus(String status) {
    switch (status) {
      case 'error':
        return Colors.red;
      case 'confirmation':
        return Colors.green;
      case 'alert':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  // دالة لتنسيق التاريخ
  String formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      DateTime date = DateTime.parse(dateString);
      Duration difference = DateTime.now().difference(date);
      
      if (difference.inDays > 0) {
        return 'منذ ${difference.inDays} يوم';
      } else if (difference.inHours > 0) {
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inMinutes > 0) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else {
        return 'الآن';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey.shade300 : getColorForStatus(status).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: getColorForStatus(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            getIconForStatus(status), 
            color: getColorForStatus(status),
            size: 24,
          ),
        ),
        title: Text(
          utf8.decode(notification.codeUnits),
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          formatDate(createdAt),
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
        onTap: () async {
          // تحديث حالة الإشعار عند النقر
          if (!isRead) {
            markAsRead(notificationId);
            await markAsRead(notificationId);
          }

          // التوجيه إلى شاشة تفاصيل الرسالة
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationDetailsScreen(
                notification: notification,
                status: status,
                createdAt: createdAt,
              ),
            ),
          );

          // تحديث الإشعارات عند العودة
          onNotificationRead();
        },
      ),
    );
  }
}

// شاشة تفاصيل الرسالة
class NotificationDetailsScreen extends StatelessWidget {
  final String notification;
  final String status;
  final String createdAt;

  const NotificationDetailsScreen({
    Key? key, 
    required this.notification,
    required this.status,
    required this.createdAt,
  }) : super(key: key);

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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        status == 'error' ? Icons.error_outline :
                        status == 'confirmation' ? Icons.check_circle_outline :
                        status == 'alert' ? Icons.warning_amber_outlined :
                        Icons.notification_important,
                        color: status == 'error' ? Colors.red :
                               status == 'confirmation' ? Colors.green :
                               status == 'alert' ? Colors.orange : Colors.blue,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          status == 'error' ? 'إشعار خطأ' :
                          status == 'confirmation' ? 'إشعار تأكيد' :
                          status == 'alert' ? 'إشعار تنبيه' : 'إشعار',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    utf8.decode(notification.codeUnits),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'التاريخ: ${_formatFullDate(createdAt)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFullDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
