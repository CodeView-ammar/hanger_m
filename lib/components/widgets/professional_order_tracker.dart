import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:melaq/constants.dart';
import 'package:melaq/services/review_service.dart';

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
    required this.laundryName,
    this.orderId,
    this.laundryId, // إضافة معرف المغسلة
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
  final int? laundryId; // إضافة معرف المغسلة
  final Function(double serviceQuality, double deliverySpeed, double priceValue, String comment)? onRatingSubmitted; // تحديث دالة التقييم

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

  // متغير لتتبع حالة التقييم محلياً
  bool _hasRatedLocally = false;

  @override
  void initState() {
    super.initState();
    
    // تهيئة حالة التقييم المحلية
    _hasRatedLocally = widget.hasRated;

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
    return widget.currentStatus == OrderStatus.completed;
  }

  @override
  void didUpdateWidget(ProfessionalOrderTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatus != widget.currentStatus) {
      _mainAnimationController.reset();
      _progressAnimationController.reset();
      _startAnimations();
    }
    // تحديث حالة التقييم إذا تغيرت من الوالد
    if (oldWidget.hasRated != widget.hasRated) {
      setState(() {
        _hasRatedLocally = widget.hasRated;
      });
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
      title: 'بانتظار قبول الطلب',
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

  // دالة لعرض نافذة التقييم مع معالجة النتيجة
  void _showRatingDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LaundryRatingScreen(
        laundryName: widget.laundryName ?? '',
        laundryId: widget.laundryId,
        orderId: widget.trackingNumber,
        onRatingSubmitted: widget.onRatingSubmitted,
      ),
    );

    // إذا تم إرسال التقييم بنجاح (result == true)
    if (result == true) {
      setState(() {
        _hasRatedLocally = true;
      });
    }
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
                    Row(
                      children: [
                        const Text(
                      'مغسلة',
                            style: TextStyle(
                                fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                          Text(
                            widget.laundryName ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          ]
                          ),
                              Row(
                      children: [
                        const Icon(
                          Icons.info,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.currentStatus == OrderStatus.completed
                              ? 'نأمل أن تكون راضيًا عن الخدمة!'
                              : 'نأسف لإلغاء طلبك. نأمل أن نخدمك بشكل أفضل في المستقبل.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // قسم التقييم - استخدام الحالة المحلية _hasRatedLocally
          if (!_hasRatedLocally) ...[
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
                      icon: const Icon(Icons.star_rate, size: 5),
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

// شاشة التقييم الكاملة
class LaundryRatingScreen extends StatefulWidget {
  final String laundryName;
  final int? laundryId;
  final String? orderId;
  final Function(double serviceQuality, double deliverySpeed, double priceValue, String comment)? onRatingSubmitted;

  const LaundryRatingScreen({
    super.key,
    required this.laundryName,
    this.laundryId,
    this.orderId,
    this.onRatingSubmitted,
  });

  @override
  State<LaundryRatingScreen> createState() => _LaundryRatingScreenState();
}

class _LaundryRatingScreenState extends State<LaundryRatingScreen>
    with TickerProviderStateMixin {
  double _serviceQuality = 0.0;
  double _deliverySpeed = 0.0;
  double _priceValue = 0.0;
  final TextEditingController _commentController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  double get _overallRating {
    if (_serviceQuality == 0 && _deliverySpeed == 0 && _priceValue == 0) return 0.0;
    return (_serviceQuality + _deliverySpeed + _priceValue) / 3;
  }

  String get _ratingText {
    final rating = _overallRating;
    if (rating == 0) return 'اختر التقييم';
    if (rating <= 2) return 'سيئ';
    if (rating <= 3) return 'مقبول';
    if (rating <= 4) return 'جيد';
    return 'ممتاز';
  }

  Color get _ratingColor {
    final rating = _overallRating;
    if (rating <= 2) return Colors.red;
    if (rating <= 3) return Colors.orange;
    return successColor;
  }

  bool get _canSubmit {
    return _serviceQuality > 0 && _deliverySpeed > 0 && _priceValue > 0;
  }

  void _submitRating() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تقييم جميع الجوانب أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // التحقق من وجود معرف المغسلة
    if (widget.laundryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: لا يمكن إرسال التقييم بدون معرف المغسلة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // إرسال التقييم إلى الخادم
      final review = await ReviewService.addLaundryReview(
        laundryId: widget.laundryId!,
        withOrderId: int.parse(widget.orderId!),
        serviceQuality: _serviceQuality,
        deliverySpeed: _deliverySpeed,
        priceValue: _priceValue,
        comment: _commentController.text.trim(),
      );

      print('تم إرسال التقييم بنجاح: ${review.toString()}');

      // استدعاء الدالة المرسلة من الوالد فقط إذا نجح الإرسال
      if (widget.onRatingSubmitted != null) {
        widget.onRatingSubmitted!(
          _serviceQuality,
          _deliverySpeed,
          _priceValue,
          _commentController.text.trim(),
        );
      }

      // إخفاء مؤشر التحميل
      Navigator.of(context).pop();

      // إغلاق شاشة التقييم مع إرجاع true للإشارة إلى نجاح العملية
      Navigator.of(context).pop(true);
      
      // عرض رسالة نجاح فقط بعد التأكد من الإرسال
      if (review != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال التقييم بنجاح! شكراً لك'),
            backgroundColor: successColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // إخفاء مؤشر التحميل
      Navigator.of(context).pop();

      print('خطأ في إرسال التقييم: $e');

      // عرض رسالة خطأ مفصلة
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في إرسال التقييم: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'إعادة المحاولة',
            textColor: Colors.white,
            onPressed: _submitRating,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  slivers: [
                    // AppBar مخصص
                    SliverAppBar(
                      expandedHeight: 200,
                      floating: false,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      leading: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.black87,
                            size: 18,
                          ),
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                primaryColor.withOpacity(0.1),
                                Colors.white,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.star_rate,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'تقييم المغسلة',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                            
                                
                              Text(
                                widget.laundryName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // المحتوى الرئيسي
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // التقييم الإجمالي
                            if (_overallRating > 0) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _ratingColor.withOpacity(0.1),
                                      _ratingColor.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _ratingColor.withOpacity(0.3)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _ratingColor.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'التقييم الإجمالي',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: _ratingColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _overallRating.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: _ratingColor,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          children: [
                                            Row(
                                              children: List.generate(5, (index) {
                                                return Icon(
                                                  index < _overallRating
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 24,
                                                );
                                              }),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _ratingText,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: _ratingColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],

                            // التقييمات التفصيلية
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'قيم تجربتك',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'شاركنا رأيك في الجوانب التالية',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // جودة الخدمة
                                  _buildRatingAspect(
                                    title: 'جودة الخدمة',
                                    subtitle: 'مستوى النظافة وجودة الغسيل',
                                    icon: Icons.clean_hands,
                                    value: _serviceQuality,
                                    onChanged: (value) {
                                      setState(() {
                                        _serviceQuality = value;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 20),

                                  // سرعة التسليم
                                  _buildRatingAspect(
                                    title: 'سرعة التسليم',
                                    subtitle: 'الالتزام بالمواعيد المحددة',
                                    icon: Icons.speed,
                                    value: _deliverySpeed,
                                    onChanged: (value) {
                                      setState(() {
                                        _deliverySpeed = value;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 20),

                                  // قيمة السعر
                                  _buildRatingAspect(
                                    title: 'قيمة السعر',
                                    subtitle: 'مناسبة السعر مقابل الخدمة',
                                    icon: Icons.monetization_on,
                                    value: _priceValue,
                                    onChanged: (value) {
                                      setState(() {
                                        _priceValue = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // حقل التعليق
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.comment,
                                        color: primaryColor,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'تعليقك',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _commentController,
                                    maxLines: 4,
                                    textAlign: TextAlign.right,
                                    decoration: InputDecoration(
                                      hintText: 'شاركنا المزيد من التفاصيل حول تجربتك (اختياري)',
                                      hintStyle: const TextStyle(color: Colors.grey),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(color: primaryColor, width: 2),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // أزرار العمل
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.grey[400]!),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
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
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: _canSubmit ? _submitRating : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _canSubmit ? primaryColor : Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: _canSubmit ? 3 : 0,
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.send, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'إرسال التقييم',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRatingAspect({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required Function(double) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: value > 0 ? primaryColor.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value > 0 ? primaryColor.withOpacity(0.3) : Colors.grey[300]!,
          width: value > 0 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: value > 0 ? primaryColor : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (value > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1.0;
              return GestureDetector(
                onTap: () => onChanged(starValue),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    starValue <= value ? Icons.star : Icons.star_border,
                    color: starValue <= value ? Colors.amber : Colors.grey[400],
                    size: 36,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}