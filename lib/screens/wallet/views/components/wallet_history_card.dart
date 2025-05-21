import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shop/components/product/secondary_product_card.dart';

import '../../../../constants.dart';

class WalletHistoryCard extends StatelessWidget {
  const WalletHistoryCard({
    super.key,
    this.isReturn = false,
    required this.date,
    required this.amount,
    required this.products,
  });

  final bool isReturn;
  final String date;
  final double amount;
  final List products;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(defaultBorderRadious)),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(defaultPadding * 0.75),
            child: Row(
              children: [
                // أيقونة العملية
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isReturn ? successColor.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    isReturn ? "assets/icons/Return.svg" : "assets/icons/Product.svg",
                    color: isReturn ? successColor : primaryColor,
                    height: 20,
                    width: 20,
                  ),
                ),
                const SizedBox(width: defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReturn ? "استرجاع" : "شراء",
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12, 
                            color: Theme.of(context).textTheme.bodySmall!.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Theme.of(context).textTheme.bodySmall!.color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time_rounded,
                            size: 12, 
                            color: Theme.of(context).textTheme.bodySmall!.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "12:30",
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Theme.of(context).textTheme.bodySmall!.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isReturn ? successColor.withOpacity(0.1) : errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isReturn
                        ? "+ ر.س ${amount.toStringAsFixed(2)}"
                        : "- ر.س ${amount.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: isReturn ? successColor : errorColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (products.isNotEmpty) ...[
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(defaultPadding * 0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "المنتجات",
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "${products.length} عناصر",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            ...List.generate(
              products.length,
              (index) => Padding(
                padding: const EdgeInsets.only(
                    bottom: defaultPadding * 0.75,
                    left: defaultPadding,
                    right: defaultPadding),
                child: SecondaryProductCard(
                  image: products[index].image,
                  brandName: products[index].brandName,
                  title: products[index].title,
                  price: products[index].price,
                  priceAfetDiscount: products[index].priceAfetDiscount,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.grey.withOpacity(0.05),
                    maximumSize: const Size(double.infinity, 90),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(defaultBorderRadious),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Text(
                isReturn ? "تمت عملية استرجاع المبلغ بنجاح" : "تمت عملية الدفع بنجاح",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
