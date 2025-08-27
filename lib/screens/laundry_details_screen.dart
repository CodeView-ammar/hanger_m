import 'package:flutter/material.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../components/custom_messages.dart';
import '../services/review_service.dart';
import '../services/laundry_detail_service.dart';
import '../models/review_model.dart';
import 'product_reviews_screen.dart';

class LaundryDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> laundry;

  const LaundryDetailsScreen({
    Key? key,
    required this.laundry,
  }) : super(key: key);

  @override
  State<LaundryDetailsScreen> createState() => _LaundryDetailsScreenState();
}

class _LaundryDetailsScreenState extends State<LaundryDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LaundryReviewStats? reviewStats;
  LaundryServicesResponse? servicesResponse;
  List<LaundryWorkingHour> workingHours = [];
  bool isLoadingReviews = true;
  bool isLoadingServices = true;
  bool isLoadingHours = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLaundryData();
  }

  Future<void> _loadLaundryData() async {
    await Future.wait([
      _loadReviews(),
      _loadServices(),
      _loadWorkingHours(),
    ]);
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await ReviewService.getLaundryReviews(widget.laundry['id']);
      setState(() {
        reviewStats = reviews;
        isLoadingReviews = false;
      });
    } catch (e) {
      setState(() => isLoadingReviews = false);
    }
  }

  Future<void> _loadServices() async {
    setState(() {
      isLoadingServices = true;
    });

    try {
      final laundryId = widget.laundry['id'];
      servicesResponse = await LaundryDetailService.getLaundryServices(laundryId);
    } catch (e) {
      print('Error loading services: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingServices = false;
        });
      }
    }
  }

  Future<void> _loadWorkingHours() async {
    setState(() {
      isLoadingHours = true;
    });

    try {
      final laundryId = widget.laundry['id'];
      workingHours = await LaundryDetailService.getLaundryWorkingHours(laundryId);
    } catch (e) {
      print('Error loading working hours: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingHours = false;
        });
      }
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        AppMessageService().showErrorMessage(context, 'لا يمكن إجراء المكالمة');
      }
    }
  }

  void _openMap() async {
    final xMap = widget.laundry['x_map'] ?? '';
    final yMap = widget.laundry['y_map'] ?? '';
    
    if (xMap.isNotEmpty && yMap.isNotEmpty) {
      final Uri mapUri = Uri.parse('https://maps.google.com/?q=$yMap,$xMap');
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri);
      } else {
        if (mounted) {
          AppMessageService().showErrorMessage(context, 'لا يمكن فتح الخريطة');
        }
      }
    } else {
      if (mounted) {
        AppMessageService().showErrorMessage(context, 'لا تتوفر إحداثيات للموقع');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final laundryName = widget.laundry['name'] ?? 'غير محدد';
    final laundryAddress = widget.laundry['address'] ?? 'غير محدد';
    final laundryPhone = widget.laundry['phone'] ?? '';
    final laundryEmail = widget.laundry['email'] ?? '';
    final laundryImage = widget.laundry['image'];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                laundryName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                laundryImage != null && laundryImage.isNotEmpty
                ? Image.network(
                    laundryImage,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.local_laundry_service,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.local_laundry_service,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Basic Info Section
                _buildBasicInfoSection(laundryAddress, laundryPhone, laundryEmail),
                
                // Rating Summary
                if (!isLoadingReviews && reviewStats != null)
                  _buildRatingSummary(),
                
                // Tabs
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      // Tab(text: 'الخدمات'),
                      Tab(text: 'التقييمات'),
                      Tab(text: 'أوقات العمل'),
                    ],
                    labelColor: primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // _buildServicesTab(),
                _buildReviewsTab(),
                _buildWorkingHoursTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (laundryPhone.isNotEmpty)
            FloatingActionButton(
              heroTag: 'phone',
              onPressed: () => _makePhoneCall(laundryPhone),
              backgroundColor: Colors.green,
              child: const Icon(Icons.phone, color: Colors.white),
            ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'map',
            onPressed: _openMap,
            backgroundColor: primaryColor,
            child: const Icon(Icons.location_on, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(String address, String phone, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  phone,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
          if (email.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  email,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    final stats = reviewStats!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                stats.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < stats.averageRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
              Text(
                '${stats.totalReviews} تقييم',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _buildRatingBar('جودة الخدمة', stats.averageServiceQuality),
                _buildRatingBar('سرعة التوصيل', stats.averageDeliverySpeed),
                _buildRatingBar('قيمة السعر', stats.averagePriceValue),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductReviewsScreen(
                    orderId: widget.laundry['order_id'] ?? 0,
                    laundryId: widget.laundry['id'],
                    laundryName: widget.laundry['name'] ?? 'غير محدد',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward_ios, color: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String label, double rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: rating / 5,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHoursTab() {
    if (isLoadingHours) {
      return const Center(child: CircularProgressIndicator());
    }

    if (workingHours.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد أوقات عمل محددة',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workingHours.length,
      itemBuilder: (context, index) {
        final hour = workingHours[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              Icons.access_time,
              color: Colors.green,
            ),
            title: Text(
              hour.dayNameArabic,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Text(
              hour.formattedSchedule,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
      

Widget _buildReviewsTab() {
  if (isLoadingReviews) {
    return const Center(child: CircularProgressIndicator());
  }

  if (reviewStats == null || reviewStats!.reviews.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rate_review, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'لا توجد تقييمات بعد',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // ElevatedButton(
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => ProductReviewsScreen(
          //           laundryId: widget.laundry['id'],
          //           laundryName: widget.laundry['name'] ?? 'غير محدد',
          //         ),
          //       ),
          //     );
          //   },
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: primaryColor,
          //     foregroundColor: Colors.white,
          //   ),
          //   child: const Text('أضف أول تقييم'),
          // ),
        ],
      ),
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    itemCount: reviewStats!.reviews.length,
    itemBuilder: (context, index) {
      final review = reviewStats!.reviews[index];
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: primaryColor,
                    child: Text(
                      review.userName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < review.overallRating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 14,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${review.createdAt.day}/${review.createdAt.month}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              if (review.comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(review.comment),
              ],
            ],
          ),
        ),
      );
    },
  );
}
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}