import 'package:flutter/material.dart';
import 'package:melaq/components/product/product_card.dart';
import 'package:melaq/models/book_mark_model.dart';

import 'package:melaq/route/screen_export.dart';

import '../../../../constants.dart';

class PopularProducts extends StatelessWidget {
  const PopularProducts({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "المغاسل الاكثر الشعبية",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        // While loading use 👇
        // const ProductsSkelton(),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            // Find bookMarkedProduct on models/ProductModel.dart
            itemCount: bookMarkedProduct.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(
                left: defaultPadding,
                right: index == bookMarkedProduct.length - 1
                    ? defaultPadding
                    : 0,
              ),
              child: ProductCard(
                image: bookMarkedProduct[index].image,
                brandName: bookMarkedProduct[index].brandName,
                title: bookMarkedProduct[index].title,
                price: bookMarkedProduct[index].price,
                priceAfetDiscount: bookMarkedProduct[index].priceAfetDiscount,
                dicountpercent: bookMarkedProduct[index].dicountpercent,
                press: () {
                  Navigator.pushNamed(context, productDetailsScreenRoute,
                      arguments: index.isEven);
                },
              ),
            ),
          ),
        )
      ],
    );
  }
}
