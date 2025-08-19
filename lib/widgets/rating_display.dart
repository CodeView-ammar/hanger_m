import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/models/rating_model.dart';
import 'package:intl/intl.dart';

/// عرض التقييمات بشكل احترافي
class LaundryRatingDisplay extends StatelessWidget {
  final LaundryRatingStats stats;
  final List<LaundryRatingModel> recentRatings;
  final bool showFullStats;

  const LaundryRatingDisplay({
    Key? key,
    required this.stats,
    this.recentRatings = const [],
    this.showFullStats = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRatingHeader(),
            if (showFullStats) ...[
              const SizedBox(height: 16),
              _buildRatingDistribution(),
              const SizedBox(height: 16),
              _buildTopAspects(),
            ],
            if (recentRatings.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildRecentRatings(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.star_rounded,
            color: primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    stats.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  RatingBarIndicator(
                    rating: stats.averageRating,
                    itemBuilder: (context, index) => const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                    ),
                    itemCount: 5,
                    itemSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${stats.totalRatings} تقييم • ${stats.ratingQualityLabel}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'توزيع التقييمات',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(5, (index) {
          final stars = 5 - index;
          final percentage = stats.getStarPercentage(stars);
          final count = stats.ratingDistribution[stars] ?? 0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  '$stars',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerRight,
                      widthFactor: percentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getStarColor(stars),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTopAspects() {
    if (stats.topPositiveAspects.isEmpty && stats.topNegativeAspects.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أبرز النقاط',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (stats.topPositiveAspects.isNotEmpty) ...[
          _buildAspectsList(
            'النقاط الإيجابية',
            stats.topPositiveAspects,
            Colors.green,
            Icons.thumb_up_rounded,
          ),
          const SizedBox(height: 8),
        ],
        if (stats.topNegativeAspects.isNotEmpty)
          _buildAspectsList(
            'نقاط التحسين',
            stats.topNegativeAspects,
            Colors.orange,
            Icons.thumb_down_rounded,
          ),
      ],
    );
  }

  Widget _buildAspectsList(
    String title,
    List<String> aspects,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: aspects.take(3).map((aspect) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                aspect,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.8),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRatings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'آخر التقييمات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // عرض جميع التقييمات
              },
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recentRatings.take(3).map((rating) => _buildRatingItem(rating)),
      ],
    );
  }

  Widget _buildRatingItem(LaundryRatingModel rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Text(
                  rating.isAnonymous ? '؟' : rating.userId.toString()[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          rating.isAnonymous ? 'مستخدم مجهول' : 'مستخدم ${rating.userId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        RatingBarIndicator(
                          rating: rating.rating,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 14,
                        ),
                      ],
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(rating.dateCreated),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rating.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.comment,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
          if (rating.ratingAspects.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: rating.ratingAspects.map((aspect) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  aspect,
                  style: TextStyle(
                    fontSize: 10,
                    color: primaryColor.withOpacity(0.8),
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStarColor(int stars) {
    switch (stars) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// عرض مبسط للتقييم (للاستخدام في البطاقات الصغيرة)
class CompactRatingDisplay extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double size;

  const CompactRatingDisplay({
    Key? key,
    required this.rating,
    required this.totalRatings,
    this.size = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBarIndicator(
          rating: rating,
          itemBuilder: (context, index) => const Icon(
            Icons.star_rounded,
            color: Colors.amber,
          ),
          itemCount: 5,
          itemSize: size,
        ),
        const SizedBox(width: 4),
        Text(
          '${rating.toStringAsFixed(1)} ($totalRatings)',
          style: TextStyle(
            fontSize: size * 0.8,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}