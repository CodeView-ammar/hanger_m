/// النمط الذي سيستخدم في تحريك الخط المتصل
enum LineAnimationStyle {
  flowingDots,  // نقاط متدفقة على طول الخط
  dashLine,     // خط متقطع متحرك
  glowingLine,  // خط متوهج مع تأثير بريق
  solidLine,    // خط متصل بسيط
}

enum AnimationDirection {
  leftToRight,
  rightToLeft,
}