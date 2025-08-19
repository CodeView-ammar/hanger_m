import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:melaq/constants.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/components/custom_messages.dart';
import 'package:melaq/models/rating_model.dart';
import 'package:melaq/widgets/rating_display.dart';

/// شاشة عرض تقييمات المغسلة
class LaundryReviewsScreen extends StatefulWidget {
  final int laundryId;
  final String laundryName;

  const LaundryReviewsScreen({
    Key? key,
    required this.laundryId,
    required this.laundryName,
  }) : super(key: key);

  @override
  _LaundryReviewsScreenState createState() => _LaundryReviewsScreenState();
}

class _LaundryReviewsScreenState extends State<LaundryReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  
  LaundryRatingStats? _ratingStats;
  List<LaundryRatingModel> _allRatings = [];
  List<LaundryRatingModel> _recentRatings = [];
  List<LaundryRatingModel> _topRatings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRatings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRatings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // جلب إحصائيات التقييم
      final statsResponse = await http.get(
        Uri.parse('${APIConfig.baseUrl}/ratings/stats/${widget.laundryId}/'),
      );

      // جلب جميع التقييمات
      final ratingsResponse = await http.get(
        Uri.parse('${APIConfig.baseUrl}/ratings/laundry/${widget.laundryId}/'),
      );

      if (statsResponse.statusCode == 200 && ratingsResponse.statusCode == 200) {
        final statsData = json.decode(statsResponse.body);
        final ratingsData = json.decode(ratingsResponse.body) as List<dynamic>;

        _ratingStats = LaundryRatingStats.fromJson(statsData);
        _allRatings = ratingsData
            .map((rating) => LaundryRatingModel.fromJson(rating))
            .toList();

        // ترتيب التقييمات
        _recentRatings = List.from(_allRatings)
          ..sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

        _topRatings = List.from(_allRatings)
          ..sort((a, b) => b.rating.compareTo(a.rating));

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل في جلب بيانات التقييم';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تقييمات ${widget.laundryName}'),
        elevation: 0,
        bottom: _ratingStats != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: primaryColor,
                labelColor: Theme.of(context).textTheme.bodyLarge!.color,
                tabs: const [
                  Tab(text: 'الإحصائيات'),
                  Tab(text: 'الأحدث'),
                  Tab(text: 'الأعلى تقييماً'),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _ratingStats == null
                  ? _buildEmptyState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildStatsTab(),
                        _buildRatingsList(_recentRatings),
                        _buildRatingsList(_topRatings),
                      ],
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchRatings,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد تقييمات حتى الآن',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'كن أول من يقيم هذه المغسلة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LaundryRatingDisplay(
        stats: _ratingStats!,
        recentRatings: _recentRatings.take(5).toList(),
        showFullStats: true,
      ),
    );
  }

  Widget _buildRatingsList(List<LaundryRatingModel> ratings) {
    if (ratings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد تقييمات في هذه القائمة',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ratings.length,
      itemBuilder: (context, index) {
        final rating = ratings[index];
        return _buildRatingCard(rating);
      },
    );
  }

  Widget _buildRatingCard(LaundryRatingModel rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Text(
                    rating.isAnonymous 
                        ? '؟' 
                        : rating.userId.toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            rating.isAnonymous 
                                ? 'مستخدم مجهول' 
                                : 'مستخدم ${rating.userId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRatingColor(rating.rating).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: _getRatingColor(rating.rating),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  rating.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getRatingColor(rating.rating),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'طلب #${rating.orderId}',
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rating.comment,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            if (rating.ratingAspects.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: rating.ratingAspects.map((aspect) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    aspect,
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryColor.withOpacity(0.8),
                    ),
                  ),
                )).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatRelativeTime(rating.dateCreated),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                if (!rating.isAnonymous) ...[
                  Icon(
                    Icons.verified_user_outlined,
                    size: 14,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'تقييم موثق',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.lightGreen;
    if (rating >= 2.5) return Colors.orange;
    return Colors.red;
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return 'منذ ${(difference.inDays / 30).floor()} شهر';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}