import 'package:flutter/material.dart';
import 'package:geideapay/models/order.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/screens/order/views/orders_screen.dart';
import '../services/review_service.dart';
import '../components/custom_messages.dart';
import '../models/review_model.dart';

class ProductReviewsScreen extends StatefulWidget {
  final int laundryId;
  final String laundryName;
  final int orderId;

  const ProductReviewsScreen({
    Key? key,
    required this.laundryId,
    required this.laundryName,
    required this.orderId,
  }) : super(key: key);

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  LaundryReviewStats? reviewStats;
  bool isLoading = true;
  bool isSubmittingReview = false;

  // Review form controllers
  double serviceQuality = 5.0;
  double deliverySpeed = 5.0;
  double priceValue = 5.0;
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() => isLoading = true);
      
      final reviewsData = await ReviewService.getLaundryReviews(widget.laundryId);
      
      setState(() {
        reviewStats = reviewsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        AppMessageService().showErrorMessage(context, 'خطأ في تحميل التقييمات: $e');
      }
    }
  }

  Future<void> _submitReview() async {
    if (isSubmittingReview) return;

    try {
      setState(() => isSubmittingReview = true);
      
      await ReviewService.addLaundryReview(
        laundryId: widget.laundryId,
        withOrderId: int.parse(widget.orderId.toString() ),
        serviceQuality: serviceQuality,
        deliverySpeed: deliverySpeed,
        priceValue: priceValue,
        comment: commentController.text,
      );

      if (mounted) {
        AppMessageService().showSuccessMessage(context, 'تم إرسال التقييم بنجاح');
        commentController.clear();
        _loadReviews(); // إعادة تحميل التقييمات
      }
    } catch (e) {
      if (mounted) {
        AppMessageService().showErrorMessage(context, 'خطأ في إرسال التقييم: $e');
      }
    } finally {
      setState(() => isSubmittingReview = false);
    }
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة تقييم لـ ${widget.laundryName}'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Service Quality Rating
                _buildRatingSection(
                  'جودة الخدمة',
                  serviceQuality,
                  (value) => setDialogState(() => serviceQuality = value),
                ),
                const SizedBox(height: 16),
                
                // Delivery Speed Rating
                _buildRatingSection(
                  'سرعة التوصيل',
                  deliverySpeed,
                  (value) => setDialogState(() => deliverySpeed = value),
                ),
                const SizedBox(height: 16),
                
                // Price Value Rating
                _buildRatingSection(
                  'قيمة السعر',
                  priceValue,
                  (value) => setDialogState(() => priceValue = value),
                ),
                const SizedBox(height: 16),
                
                // Comment Field
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'تعليق (اختياري)',
                    border: OutlineInputBorder(),
                    hintText: 'اكتب تعليقك هنا...',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: isSubmittingReview ? null : () async {
              Navigator.pop(context);
              await _submitReview();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: isSubmittingReview
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : const Text('إرسال التقييم'),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(String title, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: onChanged,
                activeColor: Colors.amber,
              ),
            ),
            Container(
              width: 60,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تقييمات ${widget.laundryName}', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddReviewDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: CustomScrollView(
                slivers: [
                  // Statistics Header
                  if (reviewStats != null)
                    SliverToBoxAdapter(
                      child: _buildStatsHeader(),
                    ),
                  
                  // Reviews List
                  reviewStats == null || reviewStats!.reviews.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rate_review, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'لا توجد تقييمات بعد',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'كن أول من يقيم هذه المغسلة',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildReviewCard(reviewStats!.reviews[index]),
                            childCount: reviewStats!.reviews.length,
                          ),
                        ),
                ],
              ),
            ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _showAddReviewDialog,
      //   backgroundColor: Colors.blue,
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
    );
  }

  Widget _buildStatsHeader() {
    final stats = reviewStats!;
    final avgRating = stats.averageRating;
    final totalReviews = stats.totalReviews;
    final avgServiceQuality = stats.averageServiceQuality;
    final avgDeliverySpeed = stats.averageDeliverySpeed;
    final avgPriceValue = stats.averagePriceValue;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          // Overall Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < avgRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  Text(
                    '$totalReviews تقييم',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Detailed Ratings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('جودة الخدمة', avgServiceQuality),
              _buildStatColumn('سرعة التوصيل', avgDeliverySpeed),
              _buildStatColumn('قيمة السعر', avgPriceValue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, double value) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Icon(
              index < value ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 12,
            );
          }),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(LaundryReview review) {
    final userName = "محجوب";
    final reviewDate = review.createdAt;
    final serviceQuality = review.serviceQuality;
    final deliverySpeed = review.deliverySpeed;
    final priceValue = review.priceValue;
    final comment = review.comment;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: primaryColor,
                      child: Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  '${reviewDate.day}/${reviewDate.month}/${reviewDate.year}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Ratings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRatingChip('جودة الخدمة', serviceQuality),
                _buildRatingChip('سرعة التوصيل', deliverySpeed),
                _buildRatingChip('قيمة السعر', priceValue),
              ],
            ),
            
            // Comment
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              Text(
                comment,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingChip(String label, double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.star, color: Colors.amber, size: 12),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}