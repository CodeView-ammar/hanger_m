
import 'package:flutter/material.dart';

class LoadingEffect extends StatelessWidget {
  final Widget child;
  const LoadingEffect({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.5),
            Colors.white,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          tileMode: TileMode.clamp,
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
