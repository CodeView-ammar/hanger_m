import 'package:flutter/material.dart';

import '../../../../constants.dart';
import '../../../laundry_details_screen.dart';

class ServiceInfo extends StatelessWidget {
  const ServiceInfo({
    super.key,
    required this.title,
    required this.brand,
    required this.description,
    required this.rating,
    required this.numOfReviews,
    required this.isAvailable,
    this.laundryId,
    this.laundryData,
  });

  final String title, brand, description;
  final double rating;
  final int numOfReviews;
  final bool isAvailable;
  final int? laundryId;
  final Map<String, dynamic>? laundryData;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(defaultPadding),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              brand.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: defaultPadding / 2),
            GestureDetector(
              onTap: () {
                // التنقل إلى شاشة تفاصيل المغسلة عند النقر على الاسم
                if (laundryId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LaundryDetailsScreen(
                        laundry: laundryData ?? {
                          'id': laundryId,
                          'name': title,
                          'address': brand,
                          'phone': '',
                          'email': '',
                          'x_map': '',
                          'y_map': '',
                          'image': '',
                          'average_rating': rating,
                          'total_reviews': numOfReviews,
                        },
                      ),
                    ),
                  );
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: laundryId != null ? const Color.fromARGB(255, 3, 3, 3) : null,
                        decoration: laundryId != null ? TextDecoration.underline : null,
                      ),
                    ),
                  ),
                  // عرض التقييم بجانب الاسم
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
              Text.rich(
  TextSpan(
                  text: "${rating.toStringAsFixed(1)} ", // نص التقييم مع رقم عشري واحد
                  style: Theme.of(context).textTheme.bodySmall,
                  children: [
                    TextSpan(
                      text: "★", // النجمة
                      style: TextStyle(
                        color: const Color.fromARGB(255, 253, 228, 3), // اللون الأصفر
                        fontSize: 20, // تغيير الحجم هنا (اختر الحجم المناسب)
                      ),
                    ),
                  ],
                ),
              ),        Text(
                        "$numOfReviews مراجعات", // عدد المراجعات
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}