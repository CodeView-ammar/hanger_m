import 'package:flutter/material.dart';
import 'dart:math' as math;

enum AnimationDirection {
  leftToRight,
  rightToLeft,
}

/// مكون لرسم خط تقدم متحرك بتأثيرات بصرية جذابة
class AnimatedProgressLine extends StatelessWidget {
  const AnimatedProgressLine({
    super.key,
    required this.animation,
    required this.showAnimation,
    required this.startColor,
    required this.endColor,
    this.height = 3.0,
    this.dotSize = 4.0,
    this.flowingDotsCount = 3,
    this.usePulseEffect = true,
    this.useGradient = true,
    this.animationStyle = LineAnimationStyle.dashLine,
    this.direction = AnimationDirection.leftToRight,
  });

  final Animation<double> animation;
  final bool showAnimation;
  final Color startColor;
  final Color endColor;
  final double height;
  final double dotSize;
  final int flowingDotsCount;
  final bool usePulseEffect;
  final bool useGradient;
  final LineAnimationStyle animationStyle;
  final AnimationDirection direction;

  @override
  Widget build(BuildContext context) {
    if (!showAnimation) {
      return const SizedBox();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        // إختيار نوع التأثير المطلوب
        switch (animationStyle) {
          case LineAnimationStyle.dashLine:
            return _buildFlowingDotsLine(width);
          case LineAnimationStyle.dashLine:
            return _buildDashLine(width);
          case LineAnimationStyle.glowingLine:
            return _buildGlowingLine(width);
          case LineAnimationStyle.solidLine:
          default:
            return _buildSolidLine(width);
        }
      },
    );
  }

  /// خط متصل بسيط مع تأثير الحركة
  Widget _buildSolidLine(double width) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            gradient: useGradient
                ? LinearGradient(
                    colors: [startColor, endColor],
                    begin: direction == AnimationDirection.leftToRight
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    end: direction == AnimationDirection.leftToRight
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                  )
                : null,
            color: useGradient ? null : startColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Positioned(
                left: direction == AnimationDirection.leftToRight ? 0 : null,
                right: direction == AnimationDirection.rightToLeft ? 0 : null,
                child: Container(
                  height: height,
                  width: width * animation.value,
                  decoration: BoxDecoration(
                    color: useGradient ? null : startColor,
                    gradient: useGradient
                        ? LinearGradient(
                            colors: [startColor, endColor],
                            begin: direction == AnimationDirection.leftToRight
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            end: direction == AnimationDirection.leftToRight
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// خط متحرك مع نقاط متدفقة
  Widget _buildFlowingDotsLine(double width) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SizedBox(
          height: height + dotSize,
          width: width,
          child: CustomPaint(
            painter: FlowingDotsPainter(
              progress: animation.value,
              startColor: startColor,
              endColor: endColor,
              height: height,
              dotRadius: dotSize / 2,
              dotsCount: flowingDotsCount,
              useGradient: useGradient,
              direction: direction,
            ),
          ),
        );
      },
    );
  }

  /// خط متقطع متحرك
  Widget _buildDashLine(double width) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SizedBox(
          height: height + 2,
          width: width,
          child: CustomPaint(
            painter: DashLinePainter(
              progress: animation.value,
              startColor: startColor,
              endColor: endColor,
              height: height,
              useGradient: useGradient,
              direction: direction,
            ),
          ),
        );
      },
    );
  }

  /// خط متوهج مع تأثير الإشعاع
  Widget _buildGlowingLine(double width) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          height: height * 3,
          width: width,
          alignment: Alignment.center,
          child: CustomPaint(
            painter: GlowingLinePainter(
              progress: animation.value,
              startColor: startColor,
              endColor: endColor,
              height: height,
              useGradient: useGradient,
              direction: direction,
            ),
          ),
        );
      },
    );
  }
}

/// رسام لخط متحرك مع نقاط متدفقة
class FlowingDotsPainter extends CustomPainter {
  FlowingDotsPainter({
    required this.progress,
    required this.startColor,
    required this.endColor,
    required this.height,
    required this.dotRadius,
    required this.dotsCount,
    required this.useGradient,
    required this.direction,
  });

  final double progress;
  final Color startColor;
  final Color endColor;
  final double height;
  final double dotRadius;
  final int dotsCount;
  final bool useGradient;
  final AnimationDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = useGradient ? startColor.withOpacity(0.5) : startColor
      ..strokeWidth = height
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final baseLineStartX = direction == AnimationDirection.leftToRight ? 0.0 : size.width;
    final baseLineEndX = direction == AnimationDirection.leftToRight ? size.width * progress : size.width * (1 - progress);
    
    // رسم الخط الأساسي
    if (useGradient) {
      final gradient = LinearGradient(
        colors: [startColor, endColor],
        begin: direction == AnimationDirection.leftToRight ? Alignment.centerLeft : Alignment.centerRight,
        end: direction == AnimationDirection.leftToRight ? Alignment.centerRight : Alignment.centerLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, height));
      
      linePaint.shader = gradient;
    }
    
    canvas.drawLine(
      Offset(baseLineStartX, size.height / 2),
      Offset(baseLineEndX, size.height / 2),
      linePaint,
    );

    // رسم النقاط المتدفقة
    final dotPaint = Paint()
      ..color = endColor
      ..style = PaintingStyle.fill;

    for (int i = 1; i <= dotsCount; i++) {
      // حساب موضع كل نقطة بحسب تقدم الحركة
      final dotPosition = progress * (1.0 + 0.5 * i / dotsCount);
      final adjustedPosition = (dotPosition > 1.0) ? dotPosition - 1.0 : dotPosition;
      
      // تحديد موضع النقطة بحسب الاتجاه
      final dotX = direction == AnimationDirection.leftToRight
          ? size.width * adjustedPosition
          : size.width * (1 - adjustedPosition);
          
      // رسم النقطة مع تأثير متدرج في الحجم
      final actualDotRadius = dotRadius * (1 + 0.5 * math.sin(progress * math.pi * 2));
      canvas.drawCircle(
        Offset(dotX, size.height / 2),
        actualDotRadius,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(FlowingDotsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// رسام لخط متقطع متحرك
class DashLinePainter extends CustomPainter {
  DashLinePainter({
    required this.progress,
    required this.startColor,
    required this.endColor,
    required this.height,
    required this.useGradient,
    required this.direction,
  });

  final double progress;
  final Color startColor;
  final Color endColor;
  final double height;
  final bool useGradient;
  final AnimationDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final dashPaint = Paint()
      ..color = useGradient ? startColor : endColor
      ..strokeWidth = height
      ..strokeCap = StrokeCap.round;

    if (useGradient) {
      final gradient = LinearGradient(
        colors: [startColor, endColor],
        begin: direction == AnimationDirection.leftToRight ? Alignment.centerLeft : Alignment.centerRight,
        end: direction == AnimationDirection.leftToRight ? Alignment.centerRight : Alignment.centerLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, height));
      
      dashPaint.shader = gradient;
    }

    final dashWidth = 8.0;
    final dashSpace = 4.0;
    final dashCount = (size.width / (dashWidth + dashSpace)).ceil();
    final progressWidth = size.width * progress;

    for (int i = 0; i < dashCount; i++) {
      final startX = i * (dashWidth + dashSpace);
      final endX = startX + dashWidth;
      
      if (direction == AnimationDirection.leftToRight) {
        if (startX <= progressWidth) {
          final actualEndX = math.min(endX, progressWidth);
          canvas.drawLine(
            Offset(startX, size.height / 2),
            Offset(actualEndX, size.height / 2),
            dashPaint,
          );
        }
      } else {
        final availableWidth = size.width - progressWidth;
        if (startX >= availableWidth) {
          canvas.drawLine(
            Offset(startX, size.height / 2),
            Offset(endX, size.height / 2),
            dashPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(DashLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// رسام لخط متوهج متحرك
class GlowingLinePainter extends CustomPainter {
  GlowingLinePainter({
    required this.progress,
    required this.startColor,
    required this.endColor,
    required this.height,
    required this.useGradient,
    required this.direction,
  });

  final double progress;
  final Color startColor;
  final Color endColor;
  final double height;
  final bool useGradient;
  final AnimationDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    // رسم الخط الأساسي مع توهج
    final baseLinePaint = Paint()
      ..color = useGradient ? startColor.withOpacity(0.7) : startColor.withOpacity(0.7)
      ..strokeWidth = height
      ..strokeCap = StrokeCap.round;

    if (useGradient) {
      final gradient = LinearGradient(
        colors: [startColor, endColor],
        begin: direction == AnimationDirection.leftToRight ? Alignment.centerLeft : Alignment.centerRight,
        end: direction == AnimationDirection.leftToRight ? Alignment.centerRight : Alignment.centerLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, height));
      
      baseLinePaint.shader = gradient;
    }

    final baseLineStartX = direction == AnimationDirection.leftToRight ? 0.0 : size.width;
    final baseLineEndX = direction == AnimationDirection.leftToRight ? size.width * progress : size.width * (1 - progress);

    // رسم الخط الأساسي
    canvas.drawLine(
      Offset(baseLineStartX, size.height / 2),
      Offset(baseLineEndX, size.height / 2),
      baseLinePaint,
    );

    // رسم توهج حول الخط
    for (int i = 1; i <= 3; i++) {
      final glowPaint = Paint()
        ..color = endColor.withOpacity(0.15 / i)
        ..strokeWidth = height + (i * 4)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(baseLineStartX, size.height / 2),
        Offset(baseLineEndX, size.height / 2),
        glowPaint,
      );
    }

    // رسم النقطة المتحركة (البريق) على طول الخط
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = height / 2
      ..strokeCap = StrokeCap.round;

    final highlightPos = (progress * 2) % 2;
    if (highlightPos < 1) {
      final highlightX = direction == AnimationDirection.leftToRight
          ? size.width * highlightPos
          : size.width * (1 - highlightPos);
      
      if (highlightX <= baseLineEndX && direction == AnimationDirection.leftToRight) {
        canvas.drawLine(
          Offset(highlightX - 10, size.height / 2),
          Offset(highlightX + 10, size.height / 2),
          highlightPaint,
        );
      } else if (highlightX >= baseLineEndX && direction == AnimationDirection.rightToLeft) {
        canvas.drawLine(
          Offset(highlightX - 10, size.height / 2),
          Offset(highlightX + 10, size.height / 2),
          highlightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(GlowingLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// النمط الذي سيستخدم في تحريك الخط المتصل
enum LineAnimationStyle {
  flowingDots,  // نقاط متدفقة على طول الخط
  dashLine,     // خط متقطع متحرك
  glowingLine,  // خط متوهج مع تأثير بريق
  solidLine,    // خط متصل بسيط
}
