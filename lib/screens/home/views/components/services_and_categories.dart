import 'package:flutter/material.dart';

import '../../../../constants.dart';
import 'categories.dart';

class ServicesAndCategories extends StatelessWidget {
  const ServicesAndCategories({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // While loading use 👇
        // const OffersSkelton(),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "فئات",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const Categories(),
      ],
    );
  }
}
