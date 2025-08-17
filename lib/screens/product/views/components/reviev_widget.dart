import 'package:flutter/material.dart';

import '../../../../constants.dart';

class RevievWidget extends StatelessWidget {
  final double averageRating;
  final int totalReviews;

  const RevievWidget({
    super.key,
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(defaultPadding),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < averageRating.floor()
                          ? Icons.star
                          : (index == averageRating.floor() && averageRating % 1 != 0
                              ? Icons.star_half
                              : Icons.star_border),
                      color: Colors.amber,
                      size: 14,
                    );
                  }),
                ),
                const SizedBox(width: 4),
                Text(
                  totalReviews.toString(),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
