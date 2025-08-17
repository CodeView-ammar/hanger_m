
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';


class LocationService {
  Future<Map<String, dynamic>?> getDistanceAndDuration(double startLat, double startLng, double destLat, double destLng) async {
    final apiKey = APIConfig.apiMap; // استبدل بـ API Key الخاص بك
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=$destLat,$destLng&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['routes'].isNotEmpty) {
        final distance = data['routes'][0]['legs'][0]['distance']['value'] as int; // المسافة بالمتر
        final duration = data['routes'][0]['legs'][0]['duration']['text']; // الوقت المستغرق
        return {
          'distance': distance / 1000, // تحويل إلى كيلومترات
          'duration': duration,
        };
      }
    } else {
      throw Exception('فشل تحميل المسافة والوقت');
    }

    return null;
  }

  Future<Map<String, double?>> getCurrentLocation() async {
    final prefs = await SharedPreferences.getInstance();
    // جلب الموقع المحفوظ في SharedPreferences
    double? savedLatitude = prefs.getDouble('latitude');
    double? savedLongitude = prefs.getDouble('longitude');
    return {
      'latitude': savedLatitude,
      'longitude': savedLongitude,
    };
  }

}