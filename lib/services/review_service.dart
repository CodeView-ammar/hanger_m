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
        return LaundryReviewStats.fromListJson(data); // Use the new constructor
      } else {
        throw Exception('فشل في جلب التقييمات');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }
  // ... rest of the service
  static Future<LaundryReview> addLaundryReview({
    required int laundryId,
    required double serviceQuality,
    required double deliverySpeed,
    required double priceValue,
    required String comment,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid') ?? '';

      if (userId.isEmpty) {
        throw Exception('يرجى تسجيل الدخول أولاً');
      }

      final response = await http.post(
        Uri.parse('${APIConfig.laundryReviewsEndpoint}$laundryId/reviews/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user': int.parse(userId),
          'service_quality': serviceQuality,
          'delivery_speed': deliverySpeed,
          'price_value': priceValue,
          'comment':  utf8.decode(comment.codeUnits),
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return LaundryReview.fromJson(data);
      } else {
        throw Exception('فشل في إضافة التقييم');
      }
    } catch (e) {
      throw Exception('خطأ: ${e.toString()}');
    }
  }

 

  static double calculateOverallRating(double serviceQuality, double deliverySpeed, double priceValue) {
    return (serviceQuality + deliverySpeed + priceValue) / 3;
  }
}