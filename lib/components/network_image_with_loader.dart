import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import 'skleton/skelton.dart';

class NetworkImageWithLoader extends StatelessWidget {
  final BoxFit fit;
  final String src;
  final double radius;
  final double height; // تم تعديلها لتكون double
  final double width;  // تم تعديلها لتكون double

  const NetworkImageWithLoader(
    this.src, {
    super.key,
    this.fit = BoxFit.cover,
    this.radius = defaultPadding,
    this.height = 0, // قيمة افتراضية لتكون 0
    this.width = 0,  // قيمة افتراضية لتكون 0
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      child: CachedNetworkImage(
        fit: fit,
        imageUrl: src,
        imageBuilder: (context, imageProvider) => Container(
          height: height > 0 ? height : null, // إذا كانت القيمة أكبر من 0 سيتم استخدامها
          width: width > 0 ? width : null,   // إذا كانت القيمة أكبر من 0 سيتم استخدامها
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: fit,
            ),
          ),
        ),
        placeholder: (context, url) => const Skeleton(), // يظهر عند التحميل
        errorWidget: (context, url, error) => const Icon(Icons.error), // يظهر عند حدوث خطأ
      ),
    );
  }
}
