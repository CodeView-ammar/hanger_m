import 'package:flutter/material.dart';
import 'package:melaq/components/widgets/professional_order_tracker.dart';
import 'package:melaq/components/widgets/order_status_indicator.dart';
import 'package:melaq/constants.dart';

/// مكون مصغر لعرض حالة الطلب في المساحات الضيقة
class CompactOrderStatus extends StatelessWidget {
  const CompactOrderStatus({
    super.key,
    required this.status,
    this.showProgressBar = true,
    this.showPercentage = false,
    this.height = 40,
    this.onTap,
  });

  final OrderStatus status;
  final bool showProgressBar;
  final bool showPercentage;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getStatusColor(status).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // أيقونة الحالة
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(status),
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            
            // شريط التقدم أو النسبة المئوية
            Expanded(
              child: showProgressBar
                  ? QuickProgressBar(
                      currentStatus: status,
                      height: 4,
                      showLabels: false,
                      animated: false,
                    )
                  : Text(
                      _getStatusText(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            
            // النسبة المئوية
            if (showPercentage) ...[
              const SizedBox(width: 8),
              Text(
                '${_getProgressPercentage(status)}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(status),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return primaryColor;
      case OrderStatus.onTheWay:
        return Colors.orange;
      case OrderStatus.pickup:
        return Colors.blue;
      case OrderStatus.deliveredToLaundry:
        return Colors.purple;
      case OrderStatus.completed:
        return successColor;
      case OrderStatus.canceled:
      case OrderStatus.error:
        return errorColor;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return Icons.receipt_long;
      case OrderStatus.onTheWay:
        return Icons.local_shipping;
      case OrderStatus.pickup:
        return Icons.home;
      case OrderStatus.deliveredToLaundry:
        return Icons.local_laundry_service;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.canceled:
        return Icons.cancel;
      case OrderStatus.error:
        return Icons.error;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return 'يعالج';
      case OrderStatus.onTheWay:
        return 'بالطريق';
      case OrderStatus.pickup:
        return 'تم الاستلام';
      case OrderStatus.deliveredToLaundry:
        return 'بالمغسلة';
      case OrderStatus.completed:
        return 'مكتمل';
      case OrderStatus.canceled:
        return 'ملغي';
      case OrderStatus.error:
        return 'خطأ';
    }
  }

  int _getProgressPercentage(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return 20;
      case OrderStatus.onTheWay:
        return 40;
      case OrderStatus.pickup:
        return 60;
      case OrderStatus.deliveredToLaundry:
        return 80;
      case OrderStatus.completed:
        return 100;
      case OrderStatus.canceled:
      case OrderStatus.error:
        return 0;
    }
  }
}

/// مكون خط زمني مبسط للحالة
class MiniTimeline extends StatelessWidget {
  const MiniTimeline({
    super.key,
    required this.currentStatus,
    this.dotSize = 8,
    this.lineHeight = 2,
  });

  final OrderStatus currentStatus;
  final double dotSize;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    final steps = [
      OrderStatus.processing,
      OrderStatus.onTheWay,
      OrderStatus.pickup,
      OrderStatus.deliveredToLaundry,
      OrderStatus.completed,
    ];

    final currentIndex = steps.indexOf(currentStatus);

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentIndex;
        final isCurrent = index == currentIndex;
        
        return Expanded(
          child: Row(
            children: [
              // النقطة
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: isActive 
                      ? (isCurrent ? primaryColor : successColor)
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              // الخط
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: lineHeight,
                    color: isActive ? successColor : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

/// مؤشر متحرك للحالة الحالية
class AnimatedStatusIndicator extends StatefulWidget {
  const AnimatedStatusIndicator({
    super.key,
    required this.status,
    this.size = 24,
  });

  final OrderStatus status;
  final double size;

  @override
  State<AnimatedStatusIndicator> createState() => _AnimatedStatusIndicatorState();
}

class _AnimatedStatusIndicatorState extends State<AnimatedStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // تشغيل الحركة بشكل متكرر للحالات النشطة
    if (_isActiveStatus(widget.status)) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      if (_isActiveStatus(widget.status)) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isActiveStatus(OrderStatus status) {
    return status == OrderStatus.processing ||
           status == OrderStatus.onTheWay ||
           status == OrderStatus.deliveredToLaundry;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _getStatusColor(widget.status),
              shape: BoxShape.circle,
              boxShadow: _isActiveStatus(widget.status) ? [
                BoxShadow(
                  color: _getStatusColor(widget.status).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ] : [],
            ),
            child: Icon(
              _getStatusIcon(widget.status),
              color: Colors.white,
              size: widget.size * 0.6,
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return primaryColor;
      case OrderStatus.onTheWay:
        return Colors.orange;
      case OrderStatus.pickup:
        return Colors.blue;
      case OrderStatus.deliveredToLaundry:
        return Colors.purple;
      case OrderStatus.completed:
        return successColor;
      case OrderStatus.canceled:
      case OrderStatus.error:
        return errorColor;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return Icons.hourglass_empty;
      case OrderStatus.onTheWay:
        return Icons.local_shipping;
      case OrderStatus.pickup:
        return Icons.check;
      case OrderStatus.deliveredToLaundry:
        return Icons.local_laundry_service;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.canceled:
        return Icons.cancel;
      case OrderStatus.error:
        return Icons.error;
    }
  }
}