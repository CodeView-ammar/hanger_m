import 'dart:convert';

/// نموذج التقييم للمغاسل
class LaundryRatingModel {
  final int? id;
  final int orderId;
  final int laundryId;
  final String laundryName;
  final int userId;
  final double rating;
  final String comment;
  final DateTime dateCreated;
  final bool isAnonymous;
  final List<String> ratingAspects; // جوانب التقييم (جودة الخدمة، السرعة، إلخ)

  LaundryRatingModel({
    this.id,
    required this.orderId,
    required this.laundryId,
    required this.laundryName,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.dateCreated,
    this.isAnonymous = false,
    this.ratingAspects = const [],
  });

  factory LaundryRatingModel.fromJson(Map<String, dynamic> json) {
    return LaundryRatingModel(
      id: json['id'],
      orderId: json['order_id'],
      laundryId: json['laundry_id'],
      laundryName: json['laundry_name'] ?? 'مغسلة',
      userId: json['user_id'],
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] ?? '',
      dateCreated: DateTime.parse(json['date_created']),
      isAnonymous: json['is_anonymous'] ?? false,
      ratingAspects: List<String>.from(json['rating_aspects'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'laundry_id': laundryId,
      'laundry_name': laundryName,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'is_anonymous': isAnonymous,
      'rating_aspects': ratingAspects,
    };
  }

  /// نسخة معدلة من التقييم
  LaundryRatingModel copyWith({
    int? id,
    int? orderId,
    int? laundryId,
    String? laundryName,
    int? userId,
    double? rating,
    String? comment,
    DateTime? dateCreated,
    bool? isAnonymous,
    List<String>? ratingAspects,
  }) {
    return LaundryRatingModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      laundryId: laundryId ?? this.laundryId,
      laundryName: laundryName ?? this.laundryName,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      dateCreated: dateCreated ?? this.dateCreated,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      ratingAspects: ratingAspects ?? this.ratingAspects,
    );
  }
}

/// نموذج إحصائيات التقييم للمغسلة
class LaundryRatingStats {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution; // توزيع النجوم (1-5)
  final List<String> topPositiveAspects;
  final List<String> topNegativeAspects;

  LaundryRatingStats({
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
    this.topPositiveAspects = const [],
    this.topNegativeAspects = const [],
  });

  factory LaundryRatingStats.fromJson(Map<String, dynamic> json) {
    return LaundryRatingStats(
      averageRating: (json['average_rating'] as num).toDouble(),
      totalRatings: json['total_ratings'],
      ratingDistribution: Map<int, int>.from(json['rating_distribution'] ?? {}),
      topPositiveAspects: List<String>.from(json['top_positive_aspects'] ?? []),
      topNegativeAspects: List<String>.from(json['top_negative_aspects'] ?? []),
    );
  }

  /// الحصول على نسبة نجمة معينة
  double getStarPercentage(int stars) {
    if (totalRatings == 0) return 0.0;
    return (ratingDistribution[stars] ?? 0) / totalRatings * 100;
  }

  /// التحقق من جودة التقييم
  String get ratingQualityLabel {
    if (averageRating >= 4.5) return 'ممتاز';
    if (averageRating >= 4.0) return 'جيد جداً';
    if (averageRating >= 3.5) return 'جيد';
    if (averageRating >= 3.0) return 'مقبول';
    return 'يحتاج تحسين';
  }
}