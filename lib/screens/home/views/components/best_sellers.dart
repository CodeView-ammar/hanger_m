import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';

class ProductModel {
  final int id;
  final String name;
  final String? address;
  final String? image;
  final double? x_latitude;
  final double? y_longitude;

  ProductModel({
    required this.id,
    required this.name,
    this.address,
    this.image,
    this.x_latitude,
    this.y_longitude,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: utf8.decode(json['name'].codeUnits),
      address: utf8.decode(json['address'].codeUnits),
      image: json['image']?.isNotEmpty == true ? json['image'] : null,
      x_latitude: json['x_map'] != "" ? double.parse(json['x_map'].toString()) : 0,
      y_longitude: json['y_map'] != "" ? double.parse(json['y_map'].toString()) : 0,
    );
  }
}

class LocationService {
  Future<Map<String, dynamic>?> getDistanceAndDuration(double startLat, double startLng, double destLat, double destLng) async {
    final apiKey = APIConfig.apiMap; // استبدل بـ API Key الخاص بك
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=$destLat,$destLng&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['routes'].isNotEmpty) {
        final distance = data['routes'][0]['legs'][0]['distance']['value'] as int; // المسافة بالمتر
        final duration = data['routes'][0]['legs'][0]['duration']['text']; // الوقت المستغرق
        return {
          'distance': distance / 1000, // تحويل إلى كيلومترات
          'duration': duration,
        };
      }
    } else {
      throw Exception('فشل تحميل المسافة والوقت');
    }

    return null;
  }

  Future<Map<String, double?>> getCurrentLocation() async {
    final prefs = await SharedPreferences.getInstance();
    // جلب الموقع المحفوظ في SharedPreferences
    double? savedLatitude = prefs.getDouble('latitude');
    double? savedLongitude = prefs.getDouble('longitude');
    return {
      'latitude': savedLatitude,
      'longitude': savedLongitude,
    };
  }
}

class BestSellers extends StatefulWidget {
  const BestSellers({super.key});

  @override
  State<BestSellers> createState() => _BestSellersState();
}

class _BestSellersState extends State<BestSellers> {
  late Future<List<ProductModel>> _fetchedProducts;
  List<ProductModel> _allProducts = [];
  List<ProductModel> _displayedProducts = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final LocationService _locationService = LocationService();
  double? _userLatitude;
  double? _userLongitude;

  @override
  void initState() {
    super.initState();
  try{

      _fetchedProducts = fetchProducts(page: _currentPage);
      _getUserLocation();
  }catch(e){
    print(e);
  }
  }

  Future<void> _getUserLocation() async {
    var userLocation = await _locationService.getCurrentLocation();
    if (mounted) { // تحقق من أن الـ widget لا يزال موجودًا في الشجرة
      setState(() {
        _userLatitude = userLocation['latitude'];
        _userLongitude = userLocation['longitude'];
      });
    }
  }

  Future<Map<String, dynamic>?> _getDistanceAndDuration(ProductModel product) async {
    if (_userLatitude != null && _userLongitude != null) {
      return await _locationService.getDistanceAndDuration(
        _userLatitude!,
        _userLongitude!,
        product.x_latitude!,
        product.y_longitude!,
      );
    } else {
      return null;
    }
  }

  Future<List<ProductModel>> fetchProducts({int page = 1}) async {
    final response = await http.get(Uri.parse("${APIConfig.launderiesEndpoint}"));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ProductModel.fromJson(item)).toList();
    } else {
      throw Exception('فشل في جلب المنتجات');
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final refreshedProducts = await fetchProducts(page: 1);
      if (mounted) {
        setState(() {
          _currentPage = 1;
          _allProducts = refreshedProducts;
          _displayedProducts = _allProducts.take(10).toList();
        });
      }
    } catch (e) {
      print("خطأ في تحديث المنتجات: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final moreProducts = await fetchProducts(page: _currentPage + 1);
      if (mounted) {
        setState(() {
          _currentPage++;
          _allProducts.addAll(moreProducts);
        });
      }
    } catch (e) {
      print("خطأ في تحميل المزيد من المنتجات: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshProducts,
      child: SingleChildScrollView( // إضافة SingleChildScrollView هنا
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "الاقرب لكم",
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            FutureBuilder<List<ProductModel>>(
              future: _fetchedProducts,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final demoBestSellersProducts = snapshot.data!;
                  if (_currentPage == 1) {
                    _allProducts = demoBestSellersProducts;
                    _displayedProducts = _allProducts.take(10).toList();
                  }
                  return Column(
                    children: [
                      _buildProductList(_displayedProducts),
                      if (!_isLoading)
                        TextButton(
                          onPressed: _loadMore,
                          child: const Text("عرض المزيد",
                              style: TextStyle(
                                color:primaryColor)),
                        ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('خطأ: ${snapshot.error}'),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<ProductModel> products) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: products.length,
      itemBuilder: (context, index) {
        String imageUrl = products[index].image ?? '${APIConfig.static_baseUrl}/images/store.jpg';

        return Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          child: GestureDetector(
            onTap: () async {
              final distanceData = await _getDistanceAndDuration(products[index]);
              if (distanceData != null) {
                Navigator.pushNamed(
                  context,
                  productDetailsScreenRoute,
                  arguments: {
                    "isAvailable": index.isEven,
                    "id": products[index].id,
                    "name": products[index].name,
                    "image": products[index].image,
                    "address": products[index].address,
                    "latitude": products[index].x_latitude,
                    "longitude": products[index].y_longitude,
                    "distance": distanceData['distance'], // إضافة المسافة
                    "duration": distanceData['duration'], // إضافة الوقت
                  },
                );
              } else {
                // معالجة الحالة عندما تكون بيانات المسافة غير متاحة
                Navigator.pushNamed(
                  context,
                  productDetailsScreenRoute,
                  arguments: {
                    "isAvailable": index.isEven,
                    "id": products[index].id,
                    "name": products[index].name,
                    "image": products[index].image,
                    "address": products[index].address,
                    "latitude": products[index].x_latitude,
                    "longitude": products[index].y_longitude,
                    "distance": null,
                    "duration": null,
                  },
                );
              }
            },
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1A40), // Use the correct integer format
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRect(
                      child: Image.network(
                        imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          } else {
                            return const CircularProgressIndicator();
                          }
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/store.jpg',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            products[index].name,
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 5),
                          FutureBuilder<Map<String, dynamic>?>( 
                            future: _getDistanceAndDuration(products[index]),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text(
                                  'قيد التحميل...', // عرض "قيد التحميل" أثناء الانتظار
                                  style: TextStyle(fontSize: 14, color: Colors.white),
                                );
                              } else if (snapshot.hasData) {
                                final distance = snapshot.data!['distance'];
                                final duration = snapshot.data!['duration'];
                                return Row(
                                  children: [
                                    SvgPicture.asset(
                                      "assets/icons/Location.svg",
                                      height: 20,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${distance!.toStringAsFixed(2)} كم - $duration',
                                      style: const TextStyle(fontSize: 14, color: Colors.white),
                                    ),
                                  ],
                                );
                              } else {
                                return Text(
                                  'غير متوفر', // في حال كانت البيانات غير متاحة
                                  style: const TextStyle(fontSize: 14, color: Colors.white),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
