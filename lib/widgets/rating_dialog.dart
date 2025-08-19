import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/models/rating_model.dart';

/// مربع حوار احترافي لتقييم المغاسل
class LaundryRatingDialog extends StatefulWidget {
  const LaundryRatingDialog({
    super.key,
    required this.orderId,
    required this.laundryId,
    required this.laundryName,
    required this.onRatingSubmitted,
  });

  final String orderId;
  final String laundryId;
  final String laundryName;
  final Function(LaundryRatingModel) onRatingSubmitted;

  @override
  State<LaundryRatingDialog> createState() => _LaundryRatingDialogState();
}

class _LaundryRatingDialogState extends State<LaundryRatingDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  double _overallRating = 0;
  final Map<String, double> _aspectRatings = {
    'service_quality': 0,
    'delivery_speed': 0,
    'cleanliness': 0,
    'price_value': 0,
    'staff_behavior': 0,
  };

  final TextEditingController _commentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  final Map<String, String> _aspectTitles = {
    'service_quality': 'جودة الخدمة',
    'delivery_speed': 'سرعة التوصيل',
    'cleanliness': 'النظافة',
    'price_value': 'مقابل السعر',
    'staff_behavior': 'تعامل الموظفين',
  };

  final Map<String, IconData> _aspectIcons = {
    'service_quality': Icons.star,
    'delivery_speed': Icons.speed,
    'cleanliness': Icons.cleaning_services,
    'price_value': Icons.monetization_on,
    'staff_behavior': Icons.people,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildOverallRating(),
                      const SizedBox(height: 24),
                      _buildAspectRatings(),
                      const SizedBox(height: 24),
                      _buildCommentSection(),
                      const SizedBox(height: 20),
                      _buildAnonymousOption(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // أيقونة النجوم
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.star_rate,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),

        // العنوان
        Text(
          'تقييم ${widget.laundryName}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        Text(
          'رقم الطلب: ${widget.orderId}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),

        const Text(
          'شاركنا رأيك لمساعدة العملاء الآخرين',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOverallRating() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text(
            'التقييم العام',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          RatingBar.builder(
            initialRating: _overallRating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: 40,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: Colors.amber[600],
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _overallRating = rating;
              });
            },
          ),
          const SizedBox(height: 12),

          Text(
            _getRatingDescription(_overallRating),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getRatingColor(_overallRating),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectRatings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تقييم تفصيلي',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ..._aspectRatings.keys.map((aspect) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildAspectRatingItem(aspect),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAspectRatingItem(String aspect) {
    return Row(
      children: [
        // أيقونة الجانب
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _aspectIcons[aspect],
            color: primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // عنوان الجانب
        Expanded(
          flex: 2,
          child: Text(
            _aspectTitles[aspect]!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // نجوم التقييم
        Expanded(
          flex: 3,
          child: RatingBar.builder(
            initialRating: _aspectRatings[aspect]!,
            minRating: 0,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: 24,
            itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: Colors.amber[400],
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _aspectRatings[aspect] = rating;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.comment,
                color: primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'تعليق إضافي (اختياري)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'شاركنا تجربتك مع هذه المغسلة...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnonymousOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.privacy_tip,
            color: Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تقييم مجهول',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'لن يظهر اسمك مع التقييم',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAnonymous,
            onChanged: (value) {
              setState(() {
                _isAnonymous = value;
              });
            },
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // زر الإلغاء
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey[400]!),
            ),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // زر الإرسال
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting || _overallRating == 0 ? null : _submitRating,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'إرسال التقييم',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  String _getRatingDescription(double rating) {
    if (rating >= 4.5) return 'ممتاز';
    if (rating >= 3.5) return 'جيد جداً';
    if (rating >= 2.5) return 'جيد';
    if (rating >= 1.5) return 'متوسط';
    if (rating >= 1.0) return 'ضعيف';
    return 'اختر التقييم';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    if (rating >= 2.0) return Colors.red;
    return Colors.grey;
  }

  void _submitRating() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار تقييم عام'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // إنشاء نموذج التقييم
      final rating = LaundryRatingModel(
        orderId: int.parse(widget.orderId),
        laundryId: int.parse(widget.laundryId),
        laundryName: widget.laundryName,
        userId: 1, // يجب الحصول على معرف المستخدم الحالي
        rating: _overallRating,
        comment: _commentController.text.trim(),
        dateCreated: DateTime.now(),
        isAnonymous: _isAnonymous,
        ratingAspects: _aspectRatings.entries
            .where((entry) => entry.value > 0)
            .map((entry) => '${entry.key}:${entry.value}')
            .toList(),
      );

      // إرسال التقييم
      widget.onRatingSubmitted(rating);

      // إغلاق الحوار مع رسالة نجاح
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم إرسال تقييمك بنجاح! شكراً لك'),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إرسال التقييم: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}