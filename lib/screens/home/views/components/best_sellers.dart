import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/constants.dart';
import 'package:shop/l10n/app_localizations.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/home/views/components/location_service.dart';
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
  TextEditingController _searchController = TextEditingController(); // إضافة التحكم في النص

  @override
  void initState() {
    super.initState();
    _fetchedProducts = fetchProducts(page: _currentPage);
    _getUserLocation();

  }

  Future<void> _getUserLocation() async {
    var userLocation = await _locationService.getCurrentLocation();
    if (mounted) {
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

  Future<List<ProductModel>> fetchProducts({int page = 1, String? query}) async {
    String url = "${APIConfig.launderiesEndpoint}";
    if (query != null && query.isNotEmpty) {
      url += "?search=$query"; // تعديل URL لإضافة نص البحث
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      
      return data.map((item) => ProductModel.fromJson(item)).toList();
    } else {
      return [];
      // throw Exception('فشل في جلب المنتجات');
    }
  }

Future<void> _refreshProducts() async {
  setState(() {
    _isLoading = true;
    _allProducts.clear(); 
    _displayedProducts.clear();
     _fetchedProducts = fetchProducts(page: 1, query: _searchController.text); // تحديث FutureBuilder
  });

  try {
    final refreshedProducts = await fetchProducts(page: 1, query: _searchController.text);
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
      final moreProducts = await fetchProducts(page: _currentPage + 1, query: _searchController.text); // استخدام نص البحث
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context)!.closest_you,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                    controller: _searchController,
                    onChanged: (query) {
                      _refreshProducts();  // تحديث القائمة مباشرة عند البحث
                    },
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.search,
                      prefixIcon: Icon(Icons.search),
                    ),
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
                          child: Text(AppLocalizations.of(context)!.show_more,
                              style: TextStyle(color: primaryColor)),
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
   if (products.isEmpty) {
    return Center(child: Text('لا توجد نتائج مطابقة'));
  }
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
              color: const Color(0xFF0F1A40),
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
                              return Text(
                                AppLocalizations.of(context)!.loding,
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
                                'غير متوفر',
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
