import 'dart:convert';
import 'package:http/http.dart' as http;
import '../components/api_extintion/url_api.dart';

class LaundryDetailService {
  /// الحصول على أوقات عمل المغسلة
  static Future<List<LaundryWorkingHour>> getLaundryWorkingHours(int laundryId) async {
    try {
      final response = await http.get(
        Uri.parse('${APIConfig.api_baseUrl}/laundry-hours/laundries/$laundryId/working-hours/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => LaundryWorkingHour.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load working hours');
      }
    } catch (e) {
      print('Error loading working hours: $e');
      return [];
    }
  }

  /// الحصول على خدمات المغسلة
  static Future<LaundryServicesResponse?> getLaundryServices(int laundryId) async {
    try {
      final response = await http.get(
        Uri.parse('${APIConfig.api_baseUrl}/laundries/$laundryId/services/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LaundryServicesResponse.fromJson(data);
      } else {
        throw Exception('Failed to load services');
      }
    } catch (e) {
      print('Error loading services: $e');
      return null;
    }
  }
}

/// نموذج لأوقات عمل المغسلة
class LaundryWorkingHour {
  final int id;
  final String dayOfWeek;
  final String openingTime;
  final String closingTime;

  LaundryWorkingHour({
    required this.id,
    required this.dayOfWeek,
    required this.openingTime,
    required this.closingTime,
  });

  factory LaundryWorkingHour.fromJson(Map<String, dynamic> json) {
    return LaundryWorkingHour(
      id: json['id'],
      dayOfWeek: json['day_of_week'],
      openingTime: json['opening_time'],
      closingTime: json['closing_time'],
    );
  }

  /// ترجمة اسم اليوم إلى العربية
  String get dayNameArabic {
    switch (dayOfWeek) {
      case 'saturday':
        return 'السبت';
      case 'sunday':
        return 'الأحد';
      case 'monday':
        return 'الاثنين';
      case 'tuesday':
        return 'الثلاثاء';
      case 'wednesday':
        return 'الأربعاء';
      case 'thursday':
        return 'الخميس';
      case 'friday':
        return 'الجمعة';
      default:
        return dayOfWeek;
    }
  }

  /// تنسيق الوقت
  String formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'م' : 'ص';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  String get formattedSchedule {
    return '${formatTime(openingTime)} - ${formatTime(closingTime)}';
  }
}

/// نموذج لاستجابة خدمات المغسلة
class LaundryServicesResponse {
  final String laundryName;
  final List<LaundryServiceDetail> services;

  LaundryServicesResponse({
    required this.laundryName,
    required this.services,
  });

  factory LaundryServicesResponse.fromJson(Map<String, dynamic> json) {
    return LaundryServicesResponse(
      laundryName: json['laundry_name'],
      services: (json['services'] as List)
          .map((item) => LaundryServiceDetail.fromJson(item))
          .toList(),
    );
  }
}

/// نموذج لتفاصيل خدمة المغسلة
class LaundryServiceDetail {
  final int id;
  final ServiceInfo service;
  final int laundryId;

  LaundryServiceDetail({
    required this.id,
    required this.service,
    required this.laundryId,
  });

  factory LaundryServiceDetail.fromJson(Map<String, dynamic> json) {
    return LaundryServiceDetail(
      id: json['id'],
      service: ServiceInfo.fromJson(json['service']),
      laundryId: json['laundry'],
    );
  }
}

/// نموذج لمعلومات الخدمة
class ServiceInfo {
  final int id;
  final String name;
  final String? description;
  final String price;
  final String urgentPrice;
  final int duration;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int laundryId;
  final int categoryId;

  ServiceInfo({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.urgentPrice,
    required this.duration,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    required this.laundryId,
    required this.categoryId,
  });

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    return ServiceInfo(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
      urgentPrice: json['urgent_price'],
      duration: json['duration'],
      image: json['image'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      laundryId: json['laundry'],
      categoryId: json['category'],
    );
  }

  /// الحصول على السعر المنسق
  String get formattedPrice {
    try {
      final priceValue = double.parse(price);
      return '${priceValue.toStringAsFixed(0)} ريال';
    } catch (e) {
      return '$price ريال';
    }
  }

  /// الحصول على السعر العاجل المنسق
  String get formattedUrgentPrice {
    try {
      final urgentPriceValue = double.parse(urgentPrice);
      return '${urgentPriceValue.toStringAsFixed(0)} ريال';
    } catch (e) {
      return '$urgentPrice ريال';
    }
  }

  /// مدة الخدمة المنسقة
  String get formattedDuration {
    if (duration == 1) {
      return 'يوم واحد';
    } else if (duration == 2) {
      return 'يومان';
    } else if (duration > 2 && duration <= 10) {
      return '$duration أيام';
    } else {
      return '$duration يوم';
    }
  }
}