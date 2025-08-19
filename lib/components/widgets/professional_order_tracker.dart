import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:melaq/constants.dart';

enum OrderStatus { processing, onTheWay, pickup, deliveredToLaundry, completed, canceled, error }

class ProfessionalOrderTracker extends StatefulWidget {
  const ProfessionalOrderTracker({
    super.key,
    required this.currentStatus,
    this.estimatedTime,
    this.showProgressPercentage = true,
    this.showTimeEstimate = true,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.trackingNumber,
    this.onStepTap,
    this.compactMode = false,
    this.hasRated = false,
    this.onRatingTap,
    this.laundryName,
    this.orderId,
    this.onRatingSubmitted, // دالة جديدة لإرسال التقييم
  });

  final OrderStatus currentStatus;
  final String? estimatedTime;
  final bool showProgressPercentage;
  final bool showTimeEstimate;
  final Duration animationDuration;
  final String? trackingNumber;
  final Function(OrderStatus)? onStepTap;
  final bool compactMode;
  final bool hasRated;
  final VoidCallback? onRatingTap;
  final String? laundryName;
  final String? orderId;
  final Function(int rating, String comment)? onRatingSubmitted; // دالة جديدة

  @override
  State<ProfessionalOrderTracker> createState() => _ProfessionalOrderTrackerState();
}

class _ProfessionalOrderTrackerState extends State<ProfessionalOrderTracker>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _progressAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _mainAnimationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressAnimationController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _mainAnimationController.forward();
    // إيقاف الرسوم المتحركة النابضة عند اكتمال الطلب أو إلغائه أو حدوث خطأ
    if (_isOrderFinished()) {
      _pulseAnimationController.stop();
      _pulseAnimationController.value = 1.0;
    } else {
      _pulseAnimationController.repeat(reverse: true);
    }
    _progressAnimationController.forward();
  }

  // دالة للتحقق من انتهاء الطلب
  bool _isOrderFinished() {
    return widget.currentStatus == OrderStatus.completed ||
           widget.currentStatus == OrderStatus.canceled ||
           widget.currentStatus == OrderStatus.error;
  }

  // دالة للتحقق من إمكانية التقييم
  bool _canRate() {
    return widget.currentStatus == OrderStatus.completed ||
           widget.currentStatus == OrderStatus.canceled;
  }

  @override
  void didUpdateWidget(ProfessionalOrderTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatus != widget.currentStatus) {
      _mainAnimationController.reset();
      _progressAnimationController.reset();
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _pulseAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  List<OrderStepData> get _orderSteps => [
    const OrderStepData(
      status: OrderStatus.processing,
      title: 'يعالج',
      subtitle: 'تم استلام الطلب',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
    ),
    const OrderStepData(
      status: OrderStatus.onTheWay,
      title: 'بالطريق',
      subtitle: 'جاري التجهيز',
      icon: Icons.local_shipping_outlined,
      activeIcon: Icons.local_shipping,
    ),
    const OrderStepData(
      status: OrderStatus.pickup,
      title: 'الاستلام',
      subtitle: 'تم الاستلام من منزلك',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    const OrderStepData(
      status: OrderStatus.deliveredToLaundry,
      title: 'تسليم للمغسلة',
      subtitle: 'قيد المعالجة',
      icon: Icons.local_laundry_service_outlined,
      activeIcon: Icons.local_laundry_service,
    ),
    const OrderStepData(
      status: OrderStatus.completed,
      title: 'تم التوصيل',
      subtitle: 'اكتمل الطلب',
      icon: Icons.check_circle_outline,
      activeIcon: Icons.check_circle,
    ),
  ];

  int get _currentStepIndex {
    for (int i = 0; i < _orderSteps.length; i++) {
      if (_orderSteps[i].status == widget.currentStatus) {
        return i;
      }
    }
    return 0;
  }

  double get _progressPercentage {
    if (widget.currentStatus == OrderStatus.canceled || widget.currentStatus == OrderStatus.error) {
      return 0.0;
    }
    return (_currentStepIndex + 1) / _orderSteps.length;
  }

  // دالة لعرض نافذة التقييم
  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LaundryRatingDialog(
        laundryName: widget.laundryName ?? 'المغسلة',
        orderId: widget.orderId,
        onRatingSubmitted: widget.onRatingSubmitted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compactMode) {
      return _buildCompactTracker();
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildProgressBar(),
                  const SizedBox(height: 24),
                  _buildStepsTimeline(),
                  if (widget.estimatedTime != null && widget.showTimeEstimate) ...[
                    const SizedBox(height: 20),
                    _buildEstimatedTime(),
                  ],
                  // قسم التقييم عند اكتمال الطلب أو إلغائه
                  _buildRatingSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.track_changes,
            color: primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تتبع الطلب',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              if (widget.trackingNumber != null)
                Text(
                  'رقم التتبع: ${widget.trackingNumber}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        if (widget.showProgressPercentage)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(_progressPercentage * 100).toInt()}%',
              style: const TextStyle(
                color: successColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [
                  0.0,
                  _progressPercentage * _progressAnimation.value,
                  _progressPercentage * _progressAnimation.value,
                  1.0,
                ],
                colors: [
                  primaryColor,
                  primaryColor,
                  Colors.transparent,
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepsTimeline() {
    return Column(
      children: List.generate(_orderSteps.length, (index) {
        final step = _orderSteps[index];
        final isActive = index == _currentStepIndex;
        final isCompleted = index < _currentStepIndex;
        final isFuture = index > _currentStepIndex;

        return _buildTimelineStep(
          step: step,
          isActive: isActive,
          isCompleted: isCompleted,
          isFuture: isFuture,
          isLast: index == _orderSteps.length - 1,
        );
      }),
    );
  }

  Widget _buildTimelineStep({
    required OrderStepData step,
    required bool isActive,
    required bool isCompleted,
    required bool isFuture,
    required bool isLast,
  }) {
    Color stepColor;
    if (isCompleted) {
      stepColor = primaryColor;
    } else if (isActive) {
      stepColor = primaryColor;
    } else {
      stepColor = Colors.grey[400]!;
    }

    return InkWell(
      onTap: widget.onStepTap != null ? () => widget.onStepTap!(step.status) : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // نقطة الحالة مع خط الاتصال
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  // نقطة الحالة
                  AnimatedBuilder(
                    animation: isActive ? _pulseAnimation : 
                               const AlwaysStoppedAnimation(1.0),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isActive ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: stepColor,
                            shape: BoxShape.circle,
                            boxShadow: isActive ? [
                              BoxShadow(
                                color: stepColor.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ] : [],
                          ),
                          child: Icon(
                            isActive || isCompleted ? step.activeIcon : step.icon,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                  // خط الاتصال
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: isCompleted ? successColor : Colors.grey[300],
                      margin: const EdgeInsets.only(top: 8),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // معلومات الخطوة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                      color: isActive || isCompleted ? stepColor : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // أيقونة الحالة - تم تعديلها لإيقاف دائرة التحميل عند انتهاء الطلب
            if (isCompleted)
              const Icon(
                Icons.check_circle,
                color: successColor,
                size: 20,
              )
            else if (isActive && !_isOrderFinished())
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
            else if (isActive && _isOrderFinished())
              Icon(
                widget.currentStatus == OrderStatus.completed 
                    ? Icons.check_circle 
                    : widget.currentStatus == OrderStatus.canceled
                        ? Icons.cancel
                        : Icons.error,
                color: widget.currentStatus == OrderStatus.completed 
                    ? successColor 
                    : widget.currentStatus == OrderStatus.canceled
                        ? Colors.orange
                        : Colors.red,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimatedTime() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            color: primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الوقت المتوقع للتوصيل',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.estimatedTime!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTracker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _orderSteps[_currentStepIndex].activeIcon,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _orderSteps[_currentStepIndex].title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _orderSteps[_currentStepIndex].subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (widget.showProgressPercentage)
            Text(
              '${(_progressPercentage * 100).toInt()}%',
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  /// بناء قسم التقييم عند اكتمال الطلب أو إلغائه
  Widget _buildRatingSection() {
    // عرض قسم التقييم فقط إذا كان يمكن التقييم
    if (!_canRate()) {
      return const SizedBox.shrink();
    }

    // تحديد الألوان والنصوص حسب حالة الطلب
    Color sectionColor = widget.currentStatus == OrderStatus.completed 
        ? successColor 
        : Colors.orange;
    
    IconData sectionIcon = widget.currentStatus == OrderStatus.completed 
        ? Icons.check_circle_outline 
        : Icons.info_outline;
    
    String sectionTitle = widget.currentStatus == OrderStatus.completed 
        ? 'تم إنجاز طلبك بنجاح!' 
        : 'تم إلغاء الطلب';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            sectionColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sectionColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: sectionColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // أيقونة وعنوان القسم
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sectionColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: sectionColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  sectionIcon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: sectionColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.laundryName ?? 'مغسلة الجودة',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // قسم التقييم
          if (!widget.hasRated) ...[
            // لم يتم التقييم بعد
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.star_border,
                        color: primaryColor,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'شاركنا تجربتك مع هذه المغسلة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'تقييمك يساعدنا في تحسين الخدمة ومساعدة العملاء الآخرين',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print('تم النقر على زر التقييم'); // للتأكد من عمل الزر
                        // استدعاء الدالة المرسلة من الوالد أو عرض النافذة مباشرة
                        if (widget.onRatingTap != null) {
                          widget.onRatingTap!();
                        } else {
                          _showRatingDialog();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.star_rate, size: 20),
                      label: const Text(
                        'تقييم المغسلة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // تم التقييم مسبقاً
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: successColor.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: successColor,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'شكراً لك! تم إرسال تقييمك بنجاح',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: successColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class OrderStepData {
  final OrderStatus status;
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData activeIcon;

  const OrderStepData({
    required this.status,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.activeIcon,
  });
}

// نافذة التقييم
class LaundryRatingDialog extends StatefulWidget {
  final String laundryName;
  final String? orderId;
  final Function(int rating, String comment)? onRatingSubmitted;

  const LaundryRatingDialog({
    super.key,
    required this.laundryName,
    this.orderId,
    this.onRatingSubmitted,
  });

  @override
  State<LaundryRatingDialog> createState() => _LaundryRatingDialogState();
}

class _LaundryRatingDialogState extends State<LaundryRatingDialog>
    with TickerProviderStateMixin {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
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

  String get _ratingText {
    switch (_selectedRating) {
      case 1:
        return 'سيئ جداً';
      case 2:
        return 'سيئ';
      case 3:
        return 'مقبول';
      case 4:
        return 'جيد';
      case 5:
        return 'ممتاز';
      default:
        return 'اختر التقييم';
    }
  }

  Color get _ratingColor {
    if (_selectedRating <= 2) return Colors.red;
    if (_selectedRating <= 3) return Colors.orange;
    return successColor;
  }

  void _submitRating() {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار التقييم أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // استدعاء الدالة المرسلة
    if (widget.onRatingSubmitted != null) {
      widget.onRatingSubmitted!(_selectedRating, _commentController.text);
    }

    // إغلاق النافذة
    Navigator.of(context).pop();

    // عرض رسالة نجاح
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال التقييم بنجاح! شكراً لك'),
        backgroundColor: successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star_rate,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تقييم المغسلة',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.laundryName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color.fromRGBO(158, 158, 158, 1),
                                ),
                              ),
                                                            Text(
                                widget.laundryName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Rating Stars
                    Column(
                      children: [
                        const Text(
                          'كيف كانت تجربتك؟',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRating = index + 1;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  index < _selectedRating 
                                      ? Icons.star 
                                      : Icons.star_border,
                                  color: index < _selectedRating 
                                      ? Colors.amber 
                                      : Colors.grey[400],
                                  size: 36,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _ratingText,
                            key: ValueKey(_selectedRating),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _selectedRating > 0 ? _ratingColor : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Comment TextField
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: 'اكتب تعليقك (اختياري)',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitRating,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'إرسال التقييم',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}