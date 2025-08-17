class CategoryModel {
  final String title;
  final String? image, svgSrc;
  final List<CategoryModel>? subCategories;

  CategoryModel({
    required this.title,
    this.image,
    this.svgSrc,
    this.subCategories,
  });
}

final List<CategoryModel> demoCategoriesWithImage = [
  CategoryModel(title: "Woman’s", image: "https://i.imgur.com/aA8ST9l.jpeg"),
  CategoryModel(title: "Man’s", image: "https://i.imgur.com/aA8ST9l.jpeg"),
  CategoryModel(title: "Kid’s", image: "https://i.imgur.com/aA8ST9l.jpeg"),
  CategoryModel(title: "Accessories", image: "https://i.imgur.com/aA8ST9l.jpeg"),
];

final List<CategoryModel> demoCategories = [
  CategoryModel(
    title: "للبيع",
    svgSrc: "assets/icons/Sale.svg",
    subCategories: [
      CategoryModel(title: "جميع المغاسل"),
      CategoryModel(title: "جديد في"),
      CategoryModel(title: "المعاطف والسترات"),
      CategoryModel(title: "فساتين"),
      CategoryModel(title: "جينز"),
    ],
  ),
  CategoryModel(
    title: "الرجل والمرأة",
    svgSrc: "assets/icons/Man&Woman.svg",
    subCategories: [
      CategoryModel(title: "جميع الملابس"),
      CategoryModel(title: "جديد في"),
      CategoryModel(title: "المعاطف والسترات"),
    ],
  ),
  CategoryModel(
    title: "مُكَمِّلات",
    svgSrc: "assets/icons/Accessories.svg",
    subCategories: [
      CategoryModel(title: "جميع الملابس"),
      CategoryModel(title: "جديد في"),
    ],
  ),
];
