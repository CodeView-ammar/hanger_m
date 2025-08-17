import 'package:flutter/material.dart';

import '../../constants.dart';
import '../network_image_with_loader.dart';

class LaundriesCart extends StatelessWidget {
  const LaundriesCart({
    super.key,
    required this.image,
    required this.brandName,
    required this.title,
    required this.meter,
    this.priceAfetDiscount,
    this.dicountpercent,
    required this.press,
  });
  
  final String image, brandName, title;
  final double meter;
  final double? priceAfetDiscount;
  final int? dicountpercent;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: press,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(140, 220),
        maximumSize: const Size(140, 220),
        padding: const EdgeInsets.all(8),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: Stack(
              children: [
                NetworkImageWithLoader(image, radius: defaultBorderRadious),
                if (dicountpercent != null)
                  Positioned(
                    right: defaultPadding / 2,
                    top: defaultPadding / 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: defaultPadding / 2,
                      ),
                      height: 16,
                      decoration: const BoxDecoration(
                        color: errorColor,
                        borderRadius: BorderRadius.all(
                          Radius.circular(defaultBorderRadious),
                        ),
                      ),
                      child: Text(
                        "$dicountpercent% off",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding / 2,
                vertical: defaultPadding / 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end, // محاذاة العناصر إلى اليسار
                children: [
                  Text(
                    brandName.toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 10),
                    textAlign: TextAlign.left, // محاذاة النص إلى اليسار
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(fontSize: 12),
                    textAlign: TextAlign.right, // محاذاة النص إلى اليسار
                  ),
                  const Spacer(),
                  priceAfetDiscount != null
                      ? Row(
                          children: [
                            Text(
                              "\$$priceAfetDiscount",
                              style: const TextStyle(
                                color: Color(0xFF31B0D8),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.right, // محاذاة النص إلى اليسار
                            ),
                            const SizedBox(width: defaultPadding / 4),
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFF31B0D8),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "\م$meter",
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium!.color,
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                              ),
                              textAlign: TextAlign.left, // محاذاة النص إلى اليسار
                            ),
                          ],
                        )
                      : const Icon(
                          Icons.location_on,
                          color: Color(0xFF31B0D8),
                          size: 16,
                        ),
                  const SizedBox(width: 4),
                  Text(
                    "$meter م",
                    style: const TextStyle(
                      color: Color(0xFF31B0D8),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.left, // محاذاة النص إلى اليسار
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}