import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/models/support_model.dart';

class SupportService {
  static Future<List<SupportTicket>> getUserTickets(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${APIConfig.supportTicketsEndpoint}?user=$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => SupportTicket.fromJson(item)).toList();
      } else {
        throw Exception('فشل في جلب التذاكر');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }

  static Future<List<SupportMessage>> getTicketMessages(int ticketId) async {
    try {
      final response = await http.get(
        Uri.parse('${APIConfig.supportMessagesEndpoint}?ticket_id=$ticketId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => SupportMessage.fromJson(item)).toList();
      } else {
        throw Exception('فشل في جلب الرسائل');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }

  static Future<SupportTicket> createTicket({
    required String title,
    required String category,
    required String priority,
    required String initialMessage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid') ?? '';

      if (userId.isEmpty) {
        throw Exception('يرجى تسجيل الدخول أولاً');
      }

      final response = await http.post(
        Uri.parse(APIConfig.supportTicketsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user': int.parse(userId),
          'title': title,
          'category': category,
          'priority': priority,
          'initial_message': initialMessage,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return SupportTicket.fromJson(data);
      } else {
        throw Exception('فشل في إنشاء التذكرة');
      }
    } catch (e) {
      throw Exception('خطأ: ${e.toString()}');
    }
  }

  static Future<SupportMessage> sendMessage({
    required int ticketId,
    required String content,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(APIConfig.supportMessagesEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ticket': ticketId,
          'content': content,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return SupportMessage.fromJson(data);
      } else {
        throw Exception('فشل في إرسال الرسالة');
      }
    } catch (e) {
      throw Exception('خطأ: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getFAQ() async {
    try {
      final response = await http.get(
        Uri.parse(APIConfig.supportFAQEndpoint),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('فشل في جلب الأسئلة الشائعة');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }

  static String getCategoryText(String category) {
    switch (category) {
      case SupportCategories.technical:
        return 'مشكلة تقنية';
      case SupportCategories.billing:
        return 'مشكلة فواتير';
      case SupportCategories.order:
        return 'مشكلة طلب';
      case SupportCategories.complaint:
        return 'شكوى';
      case SupportCategories.suggestion:
        return 'اقتراح';
      default:
        return 'استفسار عام';
    }
  }

  static String getPriorityText(String priority) {
    switch (priority) {
      case SupportPriorities.low:
        return 'منخفض';
      case SupportPriorities.medium:
        return 'متوسط';
      case SupportPriorities.high:
        return 'عالي';
      case SupportPriorities.urgent:
        return 'عاجل';
      default:
        return priority;
    }
  }

  static String getStatusText(String status) {
    switch (status) {
      case SupportStatus.open:
        return 'مفتوح';
      case SupportStatus.inProgress:
        return 'قيد المعالجة';
      case SupportStatus.resolved:
        return 'محلول';
      case SupportStatus.closed:
        return 'مغلق';
      default:
        return status;
    }
  }
}