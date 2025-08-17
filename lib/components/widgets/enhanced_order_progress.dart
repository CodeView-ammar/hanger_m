import 'package:flutter/material.dart';
import 'package:melaq/components/widgets/animated_progress_line.dart';
import 'dart:math' as math;

import 'package:melaq/constants.dart';

enum OrderProcessStatus { done, processing, notDoneYeat, error, canceled }

// مكون محسّن لتتبع حالة الطلب مع خطوط متحركة جذابة
class EnhancedOrderProgress extends StatefulWidget {
  const EnhancedOrderProgress({
    super.key,
    required this.orderStatus,
    required this.processingStatus,
    required this.packedStatus,
    required this.shippedStatus,
    required this.deliveredStatus,
    this.isCanceled = false,
    this.isInteractive = true,
    this.onStepTap,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.estimatedDeliveryTime,
    this.lineAnimationStyle = LineAnimationStyle.flowingDots,
    this.lineHeight = 3.0,
    this.dotSize = 4.0,
    this.flowingDotsCount = 3,
    this.usePulseEffect = true,
    this.useGradient = true,
    this.animationSpeed = 1.0,
  });

  final OrderProcessStatus orderStatus,
      processingStatus,
      packedStatus,
      shippedStatus,
      deliveredStatus;
  final bool isCanceled;
  final bool isInteractive;
  final Function(int)? onStepTap;
  final Duration animationDuration;
  final String? estimatedDeliveryTime;
  
  // خيارات إضافية للتأثيرات البصرية
  final LineAnimationStyle lineAnimationStyle;
  final double lineHeight;
  final double dotSize;
  final int flowingDotsCount;
  final bool usePulseEffect;
  final bool useGradient;
  final double animationSpeed;

  @override
  State<EnhancedOrderProgress> createState() => _EnhancedOrderProgressState();
}

// We're using LineAnimationStyle from animated_progress_line.dart

class _EnhancedOrderProgressState extends State<EnhancedOrderProgress> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(EnhancedOrderProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // إعادة تشغيل الحركة عند تغيير الحالة
    if (oldWidget.orderStatus != widget.orderStatus ||
        oldWidget.processingStatus != widget.processingStatus ||
        oldWidget.packedStatus != widget.packedStatus ||
        oldWidget.shippedStatus != widget.shippedStatus ||
        oldWidget.deliveredStatus != widget.deliveredStatus ||
        oldWidget.isCanceled != widget.isCanceled) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _getCurrentStepIndex() {
    if (widget.deliveredStatus == OrderProcessStatus.done) return 4;
    if (widget.shippedStatus == OrderProcessStatus.done ||
        widget.shippedStatus == OrderProcessStatus.processing) return 3;
    if (widget.packedStatus == OrderProcessStatus.done ||
        widget.packedStatus == OrderProcessStatus.processing) return 2;
    if (widget.processingStatus == OrderProcessStatus.done ||
        widget.processingStatus == OrderProcessStatus.processing) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentStepIndex = _getCurrentStepIndex();

    final statuses = [
      widget.orderStatus,
      widget.processingStatus,
      widget.packedStatus,
      widget.shippedStatus,
      widget.isCanceled ? OrderProcessStatus.canceled : widget.deliveredStatus,
    ];

    final titles = [
      "يعالج",
      "بالطريق",
      "تم الاستلام",
      "تسليم للمغسلة",
      widget.isCanceled ? "تم الإلغاء" : "تم التوصيل",
    ];

    final icons = [
      Icons.receipt_long,
      Icons.settings,
      Icons.inventory_2,
      Icons.local_shipping,
      widget.isCanceled ? Icons.cancel : Icons.check_circle,
    ];

    return Column(
      children: [
        if (widget.estimatedDeliveryTime != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
                        children: [
                          const TextSpan(
                            text: 'الوقت المتوقع للتوصيل: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: widget.estimatedDeliveryTime,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        SizedBox(
          height: 100, // زيادة الارتفاع قليلاً لاستيعاب التأثيرات المضافة
          child: Row(
            children: List.generate(
              5,
              (index) {
                final isActive = index == currentStepIndex;
                final isDone = index < currentStepIndex;
                final status = statuses[index];
                final nextStatus = index < 4 ? statuses[index + 1] : null;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        titles[index],
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
                          color: _getTextColor(status, isActive, isDone, context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // الخط السابق للنقطة
                          if (index > 0)
                            Expanded(
                              child: AnimatedProgressLine(
                                animation: _progressAnimation,
                                showAnimation: index <= currentStepIndex,
                                startColor: _getStatusColor(statuses[index - 1]),
                                endColor: _getStatusColor(status),
                                height: widget.lineHeight,
                                dotSize: widget.dotSize,
                                flowingDotsCount: widget.flowingDotsCount,
                                usePulseEffect: widget.usePulseEffect,
                                useGradient: widget.useGradient,
                                animationStyle: widget.lineAnimationStyle,
                                direction: AnimationDirection.leftToRight,
                                animationSpeed: widget.animationSpeed,
                              ),
                            ),
                          
                          // نقطة الحالة
                          _buildStatusDot(context, status, isActive, icons[index]),
                          
                          // الخط التالي للنقطة
                          if (index < 4)
                            Expanded(
                              child: AnimatedProgressLine(
                                animation: _progressAnimation,
                                showAnimation: index < currentStepIndex,
                                startColor: _getStatusColor(status),
                                endColor: nextStatus != null ? _getStatusColor(nextStatus) : Colors.grey,
                                height: widget.lineHeight,
                                dotSize: widget.dotSize,
                                flowingDotsCount: widget.flowingDotsCount,
                                usePulseEffect: widget.usePulseEffect,
                                useGradient: widget.useGradient,
                                animationStyle: widget.lineAnimationStyle,
                                direction: AnimationDirection.rightToLeft,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDot(BuildContext context, OrderProcessStatus status, bool isActive, IconData icon) {
    final color = _getStatusColor(status);
    final size = isActive ? 32.0 : 28.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // تأثير النبض للنقطة النشطة
        if (isActive && widget.usePulseEffect)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 10.0),
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Container(
                width: size + value * 2,
                height: size + value * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.3 - (value * 0.03)),
                ),
              );
            },
          ),
          
        CircleAvatar(
          radius: size / 2,
          backgroundColor: color,
          child: Icon(
            icon,
            size: size * 0.55,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Color _getTextColor(OrderProcessStatus status, bool isActive, bool isDone, BuildContext context) {
    if (status == OrderProcessStatus.error || status == OrderProcessStatus.canceled) {
      return errorColor;
    }
    if (isActive) {
      return primaryColor;
    }
    if (isDone) {
      return successColor;
    }
    return Theme.of(context).textTheme.bodyMedium!.color!;
  }

  Color _getStatusColor(OrderProcessStatus status) {
    switch (status) {
      case OrderProcessStatus.notDoneYeat:
        return Colors.grey;
      case OrderProcessStatus.error:
      case OrderProcessStatus.canceled:
        return errorColor;
      case OrderProcessStatus.processing:
        return primaryColor;
      case OrderProcessStatus.done:
        return successColor;
      default:
        return primaryColor;
    }
  }
}
