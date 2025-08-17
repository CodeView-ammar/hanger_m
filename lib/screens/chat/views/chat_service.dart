import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/screens/chat/views/support_chat_screen.dart';

class ChatService {
  static  String baseUrl =APIConfig.supportChatEndpoint;

  static Future<String> sendMessage({
    required String message,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['reply'] ?? 'لا يوجد رد.';
      } else {
        throw Exception('فشل في إرسال الرسالة.');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }

  // دالة لجلب الرسائل حسب التذكرة
  static Future<List<ChatMessage>> getMessages(int ticketId) async {
    final url = '${baseUrl}/messages/?ticket_id=$ticketId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => ChatMessage.fromJson(json)).toList();
    } else {
      throw Exception('فشل في جلب الرسائل.');
    }
  }
}



