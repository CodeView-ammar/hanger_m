import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/models/review_model.dart';

class ReviewService {
 static Future<LaundryReviewStats> getLaundryReviews(int laundryId) async {
    try {
      final response = await http.get(
        Uri.parse('${APIConfig.laundryReviewsEndpoint}$laundryId/reviews/'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body); // Expect a list

        LaundryReviewStats laundryReviewStats; // تعريف المتغير
        print('Response body: ${response.body}');
        try {
          laundryReviewStats = LaundryReviewStats.fromListJson(data);
          return laundryReviewStats; // إرجاع القيمة هنا
        } catch (e) {
          print('Error creating LaundryReviewStats: $e');
          throw Exception('خطأ في معالجة مراجعات المغسلة');
        }
      } else {
        throw Exception('فشل في جلب التقييمات - كود الخطأ: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching laundry reviews: $e'); // طباعة الخطأ
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }


static Future<bool> isOrderReviewed(int orderId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid') ?? '';
    final token = prefs.getString('token') ?? '';

    if (userId.isEmpty) {
      throw Exception('يرجى تسجيل الدخول أولاً');
    }

    final url = '${APIConfig.api_baseUrl}/reviews/check/$orderId/$userId/';
    print('التحقق من التقييم للطلب: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['reviewed'] == true;
    } else {
      throw Exception('فشل في التحقق من التقييم (كود: ${response.statusCode})');
    }
  } catch (e) {
    throw Exception('خطأ في التحقق: ${e.toString()}');
  }
}
 
static Future<bool> addLaundryReview({
    required int laundryId,
    required int withOrderId,
    required double serviceQuality,
    required double deliverySpeed,
    required double priceValue,
    required String comment,
  }) async {
    try {
      print('=== بدء عملية إرسال التقييم ===');
      
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid') ?? '';
      final token = prefs.getString('token') ?? '';

      if (userId.isEmpty) {
        throw Exception('يرجى تسجيل الدخول أولاً');
      }

      final url = '${APIConfig.api_baseUrl}/reviews/laundry/$laundryId/reviews/';
      print('إرسال التقييم إلى URL: $url');

      final Map<String, dynamic> reviewData = {
        'user': int.parse(userId),
        'order': withOrderId, // إضافة معرف الطلب
        'laundry': laundryId, // إضافة معرف المغسلة
        'service_quality': serviceQuality,
        'delivery_speed': deliverySpeed,
        'price_value': priceValue,
        'comment': comment.trim(),
      };

      print('بيانات التقييم: ${json.encode(reviewData)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: json.encode(reviewData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // final data = json.decode(response.body);
        return true;
      } else {
        String errorMessage = 'فشل في إضافة التقييم (كود: ${response.statusCode})';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map) {
            errorMessage = errorData['detail'] ?? errorData['message'] ?? errorMessage;
          }
        } catch (e) {
          print('خطأ في تحليل رسالة الخطأ: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {

      throw Exception('خطأ في إرسال التقييم: ${e.toString()}');
    }
  }
 

  static double calculateOverallRating(double serviceQuality, double deliverySpeed, double priceValue) {
    return (serviceQuality + deliverySpeed + priceValue) / 3;
  }
}