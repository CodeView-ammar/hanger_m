import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../components/api_extintion/url_api.dart';

class CourierService {
  static const String baseUrl = APIConfig.baseUrl;

  /// جلب الطلبات المتاحة للتوصيل
  static Future<List<Map<String, dynamic>>> getAvailableOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid');
      
      if (userId == null) {
        throw Exception('معرف المستخدم غير موجود');
      }

      final response = await http.get(
        Uri.parse('${baseUrl}/api/courier-orders/available_orders/?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('فشل في جلب الطلبات المتاحة: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الشبكة: $e');
    }
  }

  /// قبول طلب توصيل
  static Future<Map<String, dynamic>> acceptOrder(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid');
      
      if (userId == null) {
        throw Exception('معرف المستخدم غير موجود');
      }

      final response = await http.post(
        Uri.parse('${baseUrl}/api/courier-orders/$orderId/accept_order/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'فشل في قبول الطلب');
      }
    } catch (e) {
      throw Exception('خطأ في قبول الطلب: $e');
    }
  }

  /// جلب طلبات المندوب
  static Future<List<Map<String, dynamic>>> getMyOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid');
      
      if (userId == null) {
        throw Exception('معرف المستخدم غير موجود');
      }

      final response = await http.get(
        Uri.parse('${baseUrl}/api/courier-orders/my_orders/?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('فشل في جلب طلباتي: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الشبكة: $e');
    }
  }

  /// تحديث حالة الطلب
  static Future<Map<String, dynamic>> updateOrderStatus(int orderId, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid');
      
      if (userId == null) {
        throw Exception('معرف المستخدم غير موجود');
      }

      final response = await http.patch(
        Uri.parse('${baseUrl}/api/courier-orders/$orderId/update_status/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'فشل في تحديث حالة الطلب');
      }
    } catch (e) {
      throw Exception('خطأ في تحديث الحالة: $e');
    }
  }

  /// الحصول على النص المقروء لحالة الطلب
  static String getStatusText(String status) {
    final statusMap = {
      'pending': 'قيد الانتظار',
      'courier_accepted': 'تم قبول الطلب',
      'courier_on_the_way': 'المندوب في الطريق',
      'picked_up_from_customer': 'تم الاستلام من العميل',
      'delivered_to_laundry': 'تم التسليم للمغسلة',
      'in_progress': 'الطلب قيد المعالجة',
      'ready_for_delivery': 'جاهز للتسليم',
      'delivery_by_courier': 'التوصيل عن طريق المندوب',
      'courier_accepted_delivery': 'المندوب قبل طلب التوصيل',
      'delivered_to_customer': 'تم تسليم الطلب للعميل',
      'completed': 'مكتمل',
      'canceled': 'تم الإلغاء',
    };
    return statusMap[status] ?? status;
  }

  /// الحصول على لون حالة الطلب
  static int getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return 0xFFFF9800; // Orange
      case 'courier_accepted':
        return 0xFF2196F3; // Blue
      case 'courier_on_the_way':
        return 0xFF9C27B0; // Purple
      case 'picked_up_from_customer':
        return 0xFF673AB7; // Deep Purple
      case 'delivered_to_laundry':
        return 0xFF3F51B5; // Indigo
      case 'in_progress':
        return 0xFF2196F3; // Blue
      case 'ready_for_delivery':
        return 0xFF4CAF50; // Green
      case 'delivery_by_courier':
        return 0xFF8BC34A; // Light Green
      case 'courier_accepted_delivery':
        return 0xFF4CAF50; // Green
      case 'delivered_to_customer':
        return 0xFF4CAF50; // Green
      case 'completed':
        return 0xFF4CAF50; // Green
      case 'canceled':
        return 0xFFF44336; // Red
      default:
        return 0xFF757575; // Grey
    }
  }

  /// الحصول على الحالات التالية المتاحة
  static List<String> getNextStatuses(String currentStatus) {
    switch (currentStatus) {
      case 'courier_accepted':
        return ['courier_on_the_way'];
      case 'courier_on_the_way':
        return ['picked_up_from_customer'];
      case 'picked_up_from_customer':
        return ['delivered_to_laundry'];
      case 'ready_for_delivery':
        return ['delivery_by_courier'];
      case 'delivery_by_courier':
        return ['delivered_to_customer'];
      default:
        return [];
    }
  }
}