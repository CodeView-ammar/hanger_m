import 'dart:convert';

class ProductModel {
  final int id;
  final String name;
  final String? address;
  final String? image;
  final double? x_latitude;
  final double? y_longitude;
  final String? phone;
  final String? email;
  final String? ownerName;

  ProductModel({
    required this.id,
    required this.name,
    this.address,
    this.image,
    this.x_latitude,
    this.y_longitude,
    this.phone,
    this.email,
    this.ownerName,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: utf8.decode(json['name'].codeUnits),
      address: utf8.decode(json['address'].codeUnits),
      image: json['image']?.isNotEmpty == true ? json['image'] : null,
      x_latitude: json['x_map'] != "" ? double.parse(json['x_map'].toString()) : 0,
      y_longitude: json['y_map'] != "" ? double.parse(json['y_map'].toString()) : 0,
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      ownerName: json['owner_name']?.toString(),
    );
  }
}
