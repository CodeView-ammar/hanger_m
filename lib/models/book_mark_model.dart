// For demo only
import 'package:melaq/constants.dart';

class ServiceModel {
  final String image, brandName, title;
  final double price;
  final double? priceAfetDiscount;
  final int? dicountpercent;

  ServiceModel({
    required this.image,
    required this.brandName,
    required this.title,
    required this.price,
    this.priceAfetDiscount,
    this.dicountpercent,
  });
}
List<ServiceModel> bookMarkedProduct = [
  ServiceModel(
    image: productDemoImg1,
    title: "مغسلة عمار",
    brandName: "الرياض",
    price: 540,
    priceAfetDiscount: 420,
    dicountpercent: 20,
  ),
  ServiceModel(
    image: productDemoImg1,
    title: "مaaغسلة عمار",
    brandName: "sالرياض",
    price: 540,
    priceAfetDiscount: 420,
    dicountpercent: 20,
  ),
  ServiceModel(
    image: productDemoImg1,
    title: "مaaغسلة عمار",
    brandName: "sالرياض",
    price: 540,
    priceAfetDiscount: 420,
    dicountpercent: 20,
  ),
];
