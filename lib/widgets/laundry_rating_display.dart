import 'package:flutter/material.dart';

class LaundryRatingDisplay extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double size;
  final bool showText;

  const LaundryRatingDisplay({
    Key? key,
    required this.rating,
    required this.reviewCount,
    this.size = 16,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStarRating(rating, size),
        if (showText) ...[
          const SizedBox(width: 4),
          Text(
            '${rating.toStringAsFixed(1)} (${reviewCount > 0 ? reviewCount : 'لا توجد تقييمات'})',
            style: TextStyle(
              fontSize: size * 0.8,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStarRating(double rating, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: Colors.amber, size: size);
        } else if (index == rating.floor() && rating % 1 != 0) {
          return Icon(Icons.star_half, color: Colors.amber, size: size);
        } else {
          return Icon(Icons.star_border, color: Colors.grey, size: size);
        }
      }),
    );
  }
}

class CompactRatingDisplay extends StatelessWidget {
  final double rating;
  final int reviewCount;

  const CompactRatingDisplay({
    Key? key,
    required this.rating,
    required this.reviewCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 14),
          const SizedBox(width: 2),
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : 'جديد',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (reviewCount > 0) ...[
            const SizedBox(width: 2),
            Text(
              '($reviewCount)',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}