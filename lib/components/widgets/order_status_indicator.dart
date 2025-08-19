import 'package:flutter/material.dart';
import 'package:melaq/constants.dart';
import 'professional_order_tracker.dart';

/// مكون صغير لعرض حالة الطلب في القوائم والبطاقات
class OrderStatusIndicator extends StatelessWidget {
  const OrderStatusIndicator({
    super.key,
    required this.status,
    this.size = OrderStatusIndicatorSize.medium,
    this.showLabel = true,
    this.onTap,
  });

  final OrderStatus status;
  final OrderStatusIndicatorSize size;
  final bool showLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    final dimensions = _getSizeDimensions(size);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dimensions.horizontalPadding,
          vertical: dimensions.verticalPadding,
        ),
        decoration: BoxDecoration(
          color: config.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(dimensions.borderRadius),
          border: Border.all(
            color: config.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: dimensions.dotSize,
              height: dimensions.dotSize,
              decoration: BoxDecoration(
                color: config.color,
                shape: BoxShape.circle,
              ),
            ),
            if (showLabel) ...[
              SizedBox(width: dimensions.spacing),
              Text(
                config.label,
                style: TextStyle(
                  color: config.color,
                  fontSize: dimensions.fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  OrderStatusConfig _getStatusConfig(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return OrderStatusConfig(
          color: primaryColor,
          label: 'يعالج',
          icon: Icons.hourglass_empty,
        );
      case OrderStatus.onTheWay:
        return OrderStatusConfig(
          color: Colors.orange,
          label: 'بالطريق',
          icon: Icons.local_shipping,
        );
      case OrderStatus.pickup:
        return OrderStatusConfig(
          color: Colors.blue,
          label: 'تم الاستلام',
          icon: Icons.home,
        );
      case OrderStatus.deliveredToLaundry:
        return OrderStatusConfig(
          color: Colors.purple,
          label: 'بالمغسلة',
          icon: Icons.local_laundry_service,
        );
      case OrderStatus.completed:
        return OrderStatusConfig(
          color: successColor,
          label: 'مكتمل',
          icon: Icons.check_circle,
        );
      case OrderStatus.canceled:
        return OrderStatusConfig(
          color: errorColor,
          label: 'ملغي',
          icon: Icons.cancel,
        );
      case OrderStatus.error:
        return OrderStatusConfig(
          color: errorColor,
          label: 'خطأ',
          icon: Icons.error,
        );
    }
  }

  SizeDimensions _getSizeDimensions(OrderStatusIndicatorSize size) {
    switch (size) {
      case OrderStatusIndicatorSize.small:
        return SizeDimensions(
          dotSize: 6,
          fontSize: 10,
          horizontalPadding: 6,
          verticalPadding: 3,
          borderRadius: 8,
          spacing: 4,
        );
      case OrderStatusIndicatorSize.medium:
        return SizeDimensions(
          dotSize: 8,
          fontSize: 12,
          horizontalPadding: 8,
          verticalPadding: 4,
          borderRadius: 10,
          spacing: 6,
        );
      case OrderStatusIndicatorSize.large:
        return SizeDimensions(
          dotSize: 10,
          fontSize: 14,
          horizontalPadding: 12,
          verticalPadding: 6,
          borderRadius: 12,
          spacing: 8,
        );
    }
  }
}

/// مكون مبسط لعرض شريط تقدم سريع
class QuickProgressBar extends StatefulWidget {
  const QuickProgressBar({
    super.key,
    required this.currentStatus,
    this.height = 6,
    this.showLabels = false,
    this.animated = true,
  });

  final OrderStatus currentStatus;
  final double height;
  final bool showLabels;
  final bool animated;

  @override
  State<QuickProgressBar> createState() => _QuickProgressBarState();
}

class _QuickProgressBarState extends State<QuickProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    if (widget.animated) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(QuickProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatus != widget.currentStatus && widget.animated) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double get _progressPercentage {
    switch (widget.currentStatus) {
      case OrderStatus.processing:
        return 0.2;
      case OrderStatus.onTheWay:
        return 0.4;
      case OrderStatus.pickup:
        return 0.6;
      case OrderStatus.deliveredToLaundry:
        return 0.8;
      case OrderStatus.completed:
        return 1.0;
      case OrderStatus.canceled:
      case OrderStatus.error:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: AnimatedBuilder(
            animation: widget.animated ? _progressAnimation : 
                       const AlwaysStoppedAnimation(1.0),
            builder: (context, child) {
              final animatedProgress = widget.animated 
                  ? _progressPercentage * _progressAnimation.value
                  : _progressPercentage;

              return Container(
                width: double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0.0, animatedProgress, animatedProgress, 1.0],
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
        ),
        if (widget.showLabels) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('بدء', 0.0),
              _buildLabel('منتصف', 0.5),
              _buildLabel('مكتمل', 1.0),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLabel(String text, double position) {
    final isActive = _progressPercentage >= position;
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        color: isActive ? primaryColor : Colors.grey[600],
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

/// شريط حالة بمؤشرات متدرجة
class GradientStatusBar extends StatelessWidget {
  const GradientStatusBar({
    super.key,
    required this.currentStatus,
    this.height = 8,
    this.showCurrentStep = true,
  });

  final OrderStatus currentStatus;
  final double height;
  final bool showCurrentStep;

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
          child: Container(
            height: height,
            margin: EdgeInsets.only(right: index < steps.length - 1 ? 2 : 0),
            decoration: BoxDecoration(
              color: isActive 
                  ? (isCurrent ? primaryColor : successColor)
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: isCurrent && showCurrentStep
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(height / 2),
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.6),
                          primaryColor,
                          primaryColor.withOpacity(0.6),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
        );
      }),
    );
  }
}

enum OrderStatusIndicatorSize { small, medium, large }

class OrderStatusConfig {
  final Color color;
  final String label;
  final IconData icon;

  const OrderStatusConfig({
    required this.color,
    required this.label,
    required this.icon,
  });
}

class SizeDimensions {
  final double dotSize;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final double spacing;

  const SizeDimensions({
    required this.dotSize,
    required this.fontSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
    required this.spacing,
  });
}