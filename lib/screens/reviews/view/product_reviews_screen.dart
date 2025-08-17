import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/constants.dart';

class LaundryReviewsScreen extends StatefulWidget {
  final int laundryId;
  final String laundryName;

  const LaundryReviewsScreen({
    Key? key,
    required this.laundryId,
    required this.laundryName,
  }) : super(key: key);

  @override
  State<LaundryReviewsScreen> createState() => _LaundryReviewsScreenState();
}

class _LaundryReviewsScreenState extends State<LaundryReviewsScreen> {
  List<Map<String, dynamic>> reviews = [];
  Map<String, dynamic>? reviewStats;
  bool isLoading = true;
  bool canAddReview = true;
  String userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userid') ?? '';
    });
    await _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final response = await http.get(
        Uri.parse('${APIConfig.laundryReviewsEndpoint}${widget.laundryId}/reviews/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          reviews = List<Map<String, dynamic>>.from(data['reviews'] ?? []);
          reviewStats = data['statistics'];
          isLoading = false;
          
          // التحقق من إمكانية إضافة تقييم جديد
          if (userId.isNotEmpty) {
            canAddReview = !reviews.any((review) => 
              review['user']['id'].toString() == userId
            );
          }
        });
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
    return Scaffold(
      appBar: AppBar(
        title: Text('تقييمات ${widget.laundryName}'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Review Statistics
                if (reviewStats != null) _buildReviewStats(),
                
                // Add Review Button
                if (canAddReview && userId.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _showAddReviewDialog,
                      icon: const Icon(Icons.rate_review),
                      label: const Text('إضافة تقييم'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),

                // Reviews List
                Expanded(
                  child: reviews.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rate_review, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'لا توجد تقييمات بعد',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            return _buildReviewCard(reviews[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildReviewStats() {
    final avgRating = reviewStats!['average_rating'] ?? 0.0;
    final totalReviews = reviewStats!['total_reviews'] ?? 0;
    final serviceQuality = reviewStats!['average_service_quality'] ?? 0.0;
    final deliverySpeed = reviewStats!['average_delivery_speed'] ?? 0.0;
    final priceValue = reviewStats!['average_price_value'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  _buildStarRating(avgRating.toDouble()),
                  Text(
                    '$totalReviews تقييم',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('جودة الخدمة', serviceQuality),
              _buildStatItem('سرعة التسليم', deliverySpeed),
              _buildStatItem('قيمة السعر', priceValue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double value) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        _buildStarRating(value, size: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStarRating(double rating, {double size = 16}) {
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

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final user = review['user'] ?? {};
    final userName = user['first_name'] ?? user['username'] ?? 'مستخدم';
    final rating = review['overall_rating']?.toDouble() ?? 0.0;
    final serviceQuality = review['service_quality']?.toDouble() ?? 0.0;
    final deliverySpeed = review['delivery_speed']?.toDouble() ?? 0.0;
    final priceValue = review['price_value']?.toDouble() ?? 0.0;
    final comment = review['comment'] ?? '';
    final createdAt = review['created_at'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          _buildStarRating(rating),
                          const SizedBox(width: 8),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Detailed ratings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailedRating('الجودة', serviceQuality),
                _buildDetailedRating('السرعة', deliverySpeed),
                _buildDetailedRating('السعر', priceValue),
              ],
            ),
            
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  utf8.decode(comment.codeUnits),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRating(String label, double rating) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        _buildStarRating(rating, size: 12),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(
        laundryId: widget.laundryId,
        onReviewAdded: () {
          _fetchReviews();
        },
      ),
    );
  }
}

// Dialog for adding new review
class AddReviewDialog extends StatefulWidget {
  final int laundryId;
  final VoidCallback onReviewAdded;

  const AddReviewDialog({
    Key? key,
    required this.laundryId,
    required this.onReviewAdded,
  }) : super(key: key);

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  double serviceQuality = 5.0;
  double deliverySpeed = 5.0;
  double priceValue = 5.0;
  final TextEditingController _commentController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة تقييم'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRatingSlider('جودة الخدمة', serviceQuality, (value) {
              setState(() {
                serviceQuality = value;
              });
            }),
            _buildRatingSlider('سرعة التسليم', deliverySpeed, (value) {
              setState(() {
                deliverySpeed = value;
              });
            }),
            _buildRatingSlider('قيمة السعر', priceValue, (value) {
              setState(() {
                priceValue = value;
              });
            }),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'تعليق (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submitReview,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('إرسال'),
        ),
      ],
    );
  }

  Widget _buildRatingSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: 1.0,
                max: 5.0,
                divisions: 4,
                label: value.toStringAsFixed(1),
                onChanged: onChanged,
                activeColor: primaryColor,
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submitReview() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid') ?? '';

      final response = await http.post(
        Uri.parse('${APIConfig.laundryReviewsEndpoint}${widget.laundryId}/reviews/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user': int.parse(userId),
          'service_quality': serviceQuality,
          'delivery_speed': deliverySpeed,
          'price_value': priceValue,
          'comment': _commentController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context);
        widget.onReviewAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة التقييم بنجاح')),
        );
      } else {
        throw Exception('فشل في إضافة التقييم');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
