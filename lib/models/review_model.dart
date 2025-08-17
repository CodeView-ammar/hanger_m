// Assuming LaundryReviewStats is currently structured to expect 'reviews' and 'statistics' keys
import 'dart:convert';

class LaundryReviewStats {
  final List<LaundryReview> reviews;
  final double averageRating;
  final int totalReviews;
  final double averageServiceQuality;
  final double averageDeliverySpeed;
  final double averagePriceValue;

  LaundryReviewStats({
    required this.reviews,
    required this.averageRating,
    required this.totalReviews,
    required this.averageServiceQuality,
    required this.averageDeliverySpeed,
    required this.averagePriceValue,
  });

  // Original fromJson (conceptual) that expects a map with 'reviews' and 'statistics'
  /*
  factory LaundryReviewStats.fromJson(Map<String, dynamic> json) {
    return LaundryReviewStats(
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => LaundryReview.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      averageRating: json['statistics']['average_rating']?.toDouble() ?? 0.0,
      totalReviews: json['statistics']['total_reviews'] ?? 0,
      averageServiceQuality: json['statistics']['average_service_quality']?.toDouble() ?? 0.0,
      averageDeliverySpeed: json['statistics']['average_delivery_speed']?.toDouble() ?? 0.0,
      averagePriceValue: json['statistics']['average_price_value']?.toDouble() ?? 0.0,
    );
  }
  */

  // *** Modified fromJson to handle a direct list of reviews and calculate stats ***
  factory LaundryReviewStats.fromListJson(List<dynamic> jsonList) {
    final List<LaundryReview> parsedReviews = jsonList
        .map((e) => LaundryReview.fromJson(e as Map<String, dynamic>))
        .toList();

    double totalOverallRating = 0;
    double totalServiceQuality = 0;
    double totalDeliverySpeed = 0;
    double totalPriceValue = 0;

    for (var review in parsedReviews) {
      totalOverallRating += review.overallRating;
      totalServiceQuality += review.serviceQuality;
      totalDeliverySpeed += review.deliverySpeed;
      totalPriceValue += review.priceValue;
    }

    final int totalReviews = parsedReviews.length;
    final double averageRating = totalReviews > 0 ? totalOverallRating / totalReviews : 0.0;
    final double averageServiceQuality = totalReviews > 0 ? totalServiceQuality / totalReviews : 0.0;
    final double averageDeliverySpeed = totalReviews > 0 ? totalDeliverySpeed / totalReviews : 0.0;
    final double averagePriceValue = totalReviews > 0 ? totalPriceValue / totalReviews : 0.0;

    return LaundryReviewStats(
      reviews: parsedReviews,
      averageRating: averageRating,
      totalReviews: totalReviews,
      averageServiceQuality: averageServiceQuality,
      averageDeliverySpeed: averageDeliverySpeed,
      averagePriceValue: averagePriceValue,
    );
  }
}

class LaundryReview {
  final int id;
  final int laundryId;
  final int userId;
  final String userName;
  final int rating;
  final String comment;
  final double serviceQuality;
  final double deliverySpeed;
  final double priceValue;
  final double overallRating; // This needs to be calculated or provided by API
  final DateTime createdAt;
  final DateTime updatedAt;

  LaundryReview({
    required this.id,
    required this.laundryId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.serviceQuality,
    required this.deliverySpeed,
    required this.priceValue,
    required this.overallRating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LaundryReview.fromJson(Map<String, dynamic> json) {
    // Calculate overall_rating if not directly provided, or use 'average_rating' from the individual review
    final double calculatedOverallRating = (json['service_quality']?.toDouble() ?? 0.0 +
                                           json['delivery_speed']?.toDouble() ?? 0.0 +
                                           json['price_value']?.toDouble() ?? 0.0) / 3.0;

    return LaundryReview(
      id: json['id'],
      laundryId: json['laundry'],
      userId: json['user'],
      userName:utf8.decode( json['user_name'].codeUnits) ?? 'مجهول',
      rating: json['rating'] ?? 0, // Assuming 'rating' is the 'overall_rating' from API for the individual review
      comment: utf8.decode(json['comment'].codeUnits) ?? '',
      serviceQuality: json['service_quality']?.toDouble() ?? 0.0,
      deliverySpeed: json['delivery_speed']?.toDouble() ?? 0.0,
      priceValue: json['price_value']?.toDouble() ?? 0.0,
      overallRating: json['average_rating']?.toDouble() ?? calculatedOverallRating, // Use API's average_rating if present, else calculate
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}