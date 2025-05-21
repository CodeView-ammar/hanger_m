import 'package:flutter/material.dart';
import 'dart:math' as math;

// Export LineAnimationStyle enum to be used in other files
export 'animated_progress_line.dart' show LineAnimationStyle;

enum AnimationDirection {
  leftToRight,
  rightToLeft,
}

/// مكون لرسم خط تقدم متحرك بتأثيرات بصرية جذابة
class AnimatedProgressLine extends StatefulWidget {
  const AnimatedProgressLine({
    super.key,
    required this.animation,
    required this.showAnimation,
    required this.startColor,
    required this.endColor,
    this.height = 5.0,
    this.dotSize = 6.0,
    this.flowingDotsCount = 3,
    this.usePulseEffect = true,
    this.useGradient = true,
    this.animationStyle = LineAnimationStyle.dashLine,
    this.direction = AnimationDirection.rightToLeft,
    this.animationSpeed = 2.0,
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
  final double animationSpeed;

  @override
  State<AnimatedProgressLine> createState() => _AnimatedProgressLineState();
}

class _AnimatedProgressLineState extends State<AnimatedProgressLine> with SingleTickerProviderStateMixin {
  late AnimationController _continuousAnimationController;
  late Animation<double> _continuousAnimation;

  @override
  void initState() {
    super.initState();
    
    // إنشاء متحكم للحركة المستمرة
    _continuousAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2000 / widget.animationSpeed).round()),
    );

    _continuousAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _continuousAnimationController,
        curve: Curves.linear,
      ),
    );

    // تشغيل الحركة المستمرة بشكل لا نهائي
    _continuousAnimationController.repeat();
  }
  
  @override
  void didUpdateWidget(AnimatedProgressLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.animationSpeed != widget.animationSpeed) {
      _continuousAnimationController.duration = Duration(milliseconds: (2000 / widget.animationSpeed).round());
    }
    
    if (!_continuousAnimationController.isAnimating && widget.showAnimation) {
      _continuousAnimationController.repeat();
    } else if (_continuousAnimationController.isAnimating && !widget.showAnimation) {
      _continuousAnimationController.stop();
    }
  }

  @override
  void dispose() {
    _continuousAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAnimation) {
      return const SizedBox();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        // إختيار نوع التأثير المطلوب
        switch (widget.animationStyle) {
          case LineAnimationStyle.flowingDots:
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

  /// خط متصل بسيط مع تأثير الحركة المستمرة
  Widget _buildSolidLine(double width) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _continuousAnimation]),
      builder: (context, child) {
        final mainProgress = widget.animation.value;
        final continuousOffset = _continuousAnimation.value;
        
        return Container(
          height: widget.height,
          width: width,
          decoration: BoxDecoration(
            gradient: widget.useGradient
                ? LinearGradient(
                    colors: [widget.startColor, widget.endColor],
                    begin: widget.direction == AnimationDirection.leftToRight
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    end: widget.direction == AnimationDirection.leftToRight
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                  )
                : null,
            color: widget.useGradient ? null : widget.startColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // خط الحالة الرئيسي
              Positioned(
                left: widget.direction == AnimationDirection.leftToRight ? 0 : null,
                right: widget.direction == AnimationDirection.rightToLeft ? 0 : null,
                child: Container(
                  height: widget.height,
                  width: width * mainProgress,
                  decoration: BoxDecoration(
                    color: widget.useGradient ? null : widget.startColor,
                    gradient: widget.useGradient
                        ? LinearGradient(
                            colors: [widget.startColor, widget.endColor],
                            begin: widget.direction == AnimationDirection.leftToRight
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            end: widget.direction == AnimationDirection.leftToRight
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                          )
                        : null,
                  ),
                ),
              ),
              
              // تأثيرات متحركة داخل الخط
              if (mainProgress > 0.1)
                Positioned(
                  left: widget.direction == AnimationDirection.leftToRight 
                      ? (width * mainProgress * continuousOffset - 20) 
                      : null,
                  right: widget.direction == AnimationDirection.rightToLeft 
                      ? (width * mainProgress * (1 - continuousOffset) - 20) 
                      : null,
                  child: Container(
                    height: widget.height,
                    width: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.7),
                          Colors.white.withOpacity(0.0),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// خط متحرك مع نقاط متدفقة بشكل مستمر
  Widget _buildFlowingDotsLine(double width) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _continuousAnimation]),
      builder: (context, child) {
        return SizedBox(
          height: widget.height + widget.dotSize,
          width: width,
          child: CustomPaint(
            painter: FlowingDotsPainter(
              mainProgress: widget.animation.value,
              continuousProgress: _continuousAnimation.value,
              startColor: widget.startColor,
              endColor: widget.endColor,
              height: widget.height,
              dotRadius: widget.dotSize / 2,
              dotsCount: widget.flowingDotsCount,
              useGradient: widget.useGradient,
              direction: widget.direction,
            ),
          ),
        );
      },
    );
  }

  /// خط متقطع متحرك بشكل مستمر
  Widget _buildDashLine(double width) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _continuousAnimation]),
      builder: (context, child) {
        return SizedBox(
          height: widget.height + 2,
          width: width,
          child: CustomPaint(
            painter: DashLinePainter(
              mainProgress: widget.animation.value,
              continuousProgress: _continuousAnimation.value,
              startColor: widget.startColor,
              endColor: widget.endColor,
              height: widget.height,
              useGradient: widget.useGradient,
              direction: widget.direction,
            ),
          ),
        );
      },
    );
  }

  /// خط متوهج مع تأثير الإشعاع بشكل مستمر
  Widget _buildGlowingLine(double width) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _continuousAnimation]),
      builder: (context, child) {
        return Container(
          height: widget.height * 3,
          width: width,
          alignment: Alignment.center,
          child: CustomPaint(
            painter: GlowingLinePainter(
              mainProgress: widget.animation.value,
              continuousProgress: _continuousAnimation.value,
              startColor: widget.startColor,
              endColor: widget.endColor,
              height: widget.height,
              useGradient: widget.useGradient,
              direction: widget.direction,
            ),
          ),
        );
      },
    );
  }
}

/// رسام لخط متحرك مع نقاط متدفقة بشكل مستمر
class FlowingDotsPainter extends CustomPainter {
  FlowingDotsPainter({
    required this.mainProgress,
    required this.continuousProgress,
    required this.startColor,
    required this.endColor,
    required this.height,
    required this.dotRadius,
    required this.dotsCount,
    required this.useGradient,
    required this.direction,
  });

  final double mainProgress;
  final double continuousProgress;
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
    final baseLineEndX = direction == AnimationDirection.leftToRight ? size.width * mainProgress : size.width * (1 - mainProgress);
    
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

    // رسم النقاط المتدفقة بشكل مستمر
    if (mainProgress > 0) {
      final dotPaint = Paint()
        ..color = endColor
        ..style = PaintingStyle.fill;
  
      for (int i = 0; i < dotsCount; i++) {
        // حساب موضع كل نقطة بشكل مستمر
        final dotOffset = (continuousProgress + (i / dotsCount)) % 1.0;
        
        // تحديد موضع النقطة ضمن الجزء المكتمل من الخط فقط
        final dotX = direction == AnimationDirection.leftToRight
            ? baseLineStartX + (baseLineEndX - baseLineStartX) * dotOffset
            : baseLineEndX + (baseLineStartX - baseLineEndX) * dotOffset;
            
        // تأثير نبض للنقاط
        final pulseFactor = 0.7 + 0.5 * math.sin((continuousProgress * 10 + i) * math.pi);
        final actualDotRadius = dotRadius * pulseFactor;
        
        // لون متغير للنقاط
        final dotColor = Color.lerp(
          startColor, 
          endColor, 
          (dotOffset + continuousProgress) % 1.0
        ) ?? endColor;
        
        dotPaint.color = dotColor;
        
        // رسم النقطة المتحركة
        canvas.drawCircle(
          Offset(dotX, size.height / 2),
          actualDotRadius,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(FlowingDotsPainter oldDelegate) {
    return oldDelegate.mainProgress != mainProgress || 
           oldDelegate.continuousProgress != continuousProgress;
  }
}

/// رسام لخط متقطع متحرك بشكل مستمر
class DashLinePainter extends CustomPainter {
  DashLinePainter({
    required this.mainProgress,
    required this.continuousProgress,
    required this.startColor,
    required this.endColor,
    required this.height,
    required this.useGradient,
    required this.direction,
  });

  final double mainProgress;
  final double continuousProgress;
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
    final totalDashWidth = dashWidth + dashSpace;
    final dashCount = (size.width / totalDashWidth).ceil() + 1;
    final progressWidth = size.width * mainProgress;
    
    // حساب الإزاحة للحركة المستمرة
    final offset = (continuousProgress * totalDashWidth) % totalDashWidth;

    for (int i = -1; i < dashCount; i++) {
      // موضع الخط المتقطع المتحرك
      final startX = i * totalDashWidth - offset;
      final endX = startX + dashWidth;
      
      if (direction == AnimationDirection.leftToRight) {
        if (startX >= 0 && startX < progressWidth) {
          final actualEndX = math.min(endX, progressWidth);
          canvas.drawLine(
            Offset(startX, size.height / 2),
            Offset(actualEndX, size.height / 2),
            dashPaint,
          );
        }
      } else {
        final availableWidth = size.width - progressWidth;
        if (startX >= availableWidth && endX <= size.width) {
          canvas.drawLine(
            Offset(math.max(startX, availableWidth), size.height / 2),
            Offset(math.min(endX, size.width), size.height / 2),
            dashPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(DashLinePainter oldDelegate) {
    return oldDelegate.mainProgress != mainProgress || 
           oldDelegate.continuousProgress != continuousProgress;
  }
}

/// رسام لخط متوهج متحرك بشكل مستمر
class GlowingLinePainter extends CustomPainter {
  GlowingLinePainter({
    required this.mainProgress,
    required this.continuousProgress,
    required this.startColor,
    required this.endColor,
    required this.height,
    required this.useGradient,
    required this.direction,
  });

  final double mainProgress;
  final double continuousProgress;
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
    final baseLineEndX = direction == AnimationDirection.leftToRight ? size.width * mainProgress : size.width * (1 - mainProgress);

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

    // رسم عدة نقاط متحركة (بريق) على طول الخط بشكل مستمر
    if (mainProgress > 0) {
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..strokeWidth = height / 2
        ..strokeCap = StrokeCap.round;
  
      // رسم عدة نقاط متوهجة متحركة على طول الخط
      for (int i = 0; i < 3; i++) {
        // حساب موضع كل نقطة بشكل مستمر مع إزاحة بينها
        final highlightPos = (continuousProgress + (i * 0.33)) % 1.0;
        
        final highlightX = direction == AnimationDirection.leftToRight
            ? baseLineStartX + (baseLineEndX - baseLineStartX) * highlightPos
            : baseLineEndX + (baseLineStartX - baseLineEndX) * highlightPos;
  
        // حجم البريق متغير للتأثير الحركي
        final glowSize = 5.0 + 5.0 * math.sin((continuousProgress * 5 + i) * math.pi);
        
        // رسم البريق المتحرك
        canvas.drawLine(
          Offset(highlightX - glowSize, size.height / 2),
          Offset(highlightX + glowSize, size.height / 2),
          highlightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(GlowingLinePainter oldDelegate) {
    return oldDelegate.mainProgress != mainProgress || 
           oldDelegate.continuousProgress != continuousProgress;
  }
}

/// النمط الذي سيستخدم في تحريك الخط المتصل
enum LineAnimationStyle {
  flowingDots,  // نقاط متدفقة على طول الخط
  dashLine,     // خط متقطع متحرك
  glowingLine,  // خط متوهج مع تأثير بريق
  solidLine,    // خط متصل بسيط
}


