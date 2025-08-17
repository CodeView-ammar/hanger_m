import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/widgets/laundry_rating_display.dart';
import 'package:melaq/screens/reviews/view/product_reviews_screen.dart';
import 'package:melaq/services/review_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LaundryDetailsScreen extends StatefulWidget {
  final int laundryId;

  const LaundryDetailsScreen({
    Key? key,
    required this.laundryId,
  }) : super(key: key);

  @override
  State<LaundryDetailsScreen> createState() => _LaundryDetailsScreenState();
}

class _LaundryDetailsScreenState extends State<LaundryDetailsScreen> {
  Map<String, dynamic>? laundryData;
  Map<String, dynamic>? reviewStats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLaundryDetails();
  }

  Future<void> _fetchLaundryDetails() async {
    try {
      // جلب تفاصيل المغسلة
      final laundryResponse = await http.get(
        Uri.parse('${APIConfig.launderiesEndpoint}${widget.laundryId}/'),
      );

      if (laundryResponse.statusCode == 200) {
        final laundryJson = json.decode(laundryResponse.body);
        
        // جلب إحصائيات التقييمات
        try {
          final reviewData = await ReviewService.getLaundryReviews(widget.laundryId);
          setState(() {
            laundryData = laundryJson;
            reviewStats = {
              'average_rating': reviewData.averageRating,
              'total_reviews': reviewData.totalReviews,
              'average_service_quality': reviewData.averageServiceQuality,
              'average_delivery_speed': reviewData.averageDeliverySpeed,
              'average_price_value': reviewData.averagePriceValue,
            };
            isLoading = false;
          });
        } catch (e) {
          setState(() {
            laundryData = laundryJson;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المغسلة')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (laundryData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المغسلة')),
        body: const Center(child: Text('لم يتم العثور على المغسلة')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(laundryData!['name'] ?? 'المغسلة'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLaundry,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المغسلة
            _buildLaundryImage(),
            
            // معلومات أساسية
            _buildBasicInfo(),
            
            // التقييمات
            _buildRatingsSection(),
            
            // ساعات العمل
            _buildWorkingHours(),
            
            // معلومات الاتصال
            _buildContactInfo(),
            
            // إجراءات
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildLaundryImage() {
    final imageUrl = laundryData!['image'];
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              '${APIConfig.static_baseUrl}/$imageUrl',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.local_laundry_service, size: 64, color: Colors.grey),
                );
              },
            )
          : const Center(
              child: Icon(Icons.local_laundry_service, size: 64, color: Colors.grey),
            ),
    );
  }

  Widget _buildBasicInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      laundryData!['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'المالك: ${laundryData!['owner_name'] ?? ''}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (reviewStats != null)
                CompactRatingDisplay(
                  rating: reviewStats!['average_rating']?.toDouble() ?? 0.0,
                  reviewCount: reviewStats!['total_reviews'] ?? 0,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  laundryData!['address'] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    if (reviewStats == null) return const SizedBox.shrink();

    final avgRating = reviewStats!['average_rating']?.toDouble() ?? 0.0;
    final totalReviews = reviewStats!['total_reviews'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'التقييمات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _viewAllReviews(),
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (totalReviews > 0) ...[
            Row(
              children: [
                Text(
                  avgRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LaundryRatingDisplay(
                        rating: avgRating,
                        reviewCount: totalReviews,
                        showText: false,
                      ),
                      Text(
                        '$totalReviews تقييم',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRatingStat(
                  'جودة الخدمة',
                  reviewStats!['average_service_quality']?.toDouble() ?? 0.0,
                ),
                _buildRatingStat(
                  'سرعة التسليم',
                  reviewStats!['average_delivery_speed']?.toDouble() ?? 0.0,
                ),
                _buildRatingStat(
                  'قيمة السعر',
                  reviewStats!['average_price_value']?.toDouble() ?? 0.0,
                ),
              ],
            ),
          ] else ...[
            const Center(
              child: Column(
                children: [
                  Icon(Icons.rate_review, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'لا توجد تقييمات بعد',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingStat(String label, double value) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        LaundryRatingDisplay(
          rating: value,
          reviewCount: 0,
          size: 12,
          showText: false,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildWorkingHours() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.access_time, color: primaryColor),
              SizedBox(width: 8),
              Text(
                'ساعات العمل',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // يمكن إضافة ساعات العمل هنا من البيانات
          const Text(
            'يرجى الاتصال للاستفسار عن ساعات العمل',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.contact_phone, color: primaryColor),
              SizedBox(width: 8),
              Text(
                'معلومات الاتصال',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (laundryData!['phone'] != null) ...[
            Row(
              children: [
                const Icon(Icons.phone, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(laundryData!['phone']),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.call, color: primaryColor),
                  onPressed: () => _makePhoneCall(laundryData!['phone']),
                ),
              ],
            ),
          ],
          if (laundryData!['email'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(laundryData!['email']),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _viewAllReviews,
              icon: const Icon(Icons.rate_review),
              label: const Text('عرض جميع التقييمات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (laundryData!['x_map'] != null && laundryData!['y_map'] != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openInMap,
                icon: const Icon(Icons.map),
                label: const Text('عرض على الخريطة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _viewAllReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LaundryReviewsScreen(
          laundryId: widget.laundryId,
          laundryName: laundryData!['name'] ?? 'المغسلة',
        ),
      ),
    );
  }

  void _shareLaundry() {
    // يمكن إضافة وظيفة المشاركة هنا
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('المشاركة قيد التطوير')),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن فتح تطبيق الهاتف')),
      );
    }
  }

  void _openInMap() async {
    final xMap = laundryData!['x_map'];
    final yMap = laundryData!['y_map'];
    
    if (xMap != null && yMap != null) {
      final Uri mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$yMap,$xMap');
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح تطبيق الخرائط')),
        );
      }
    }
  }
}