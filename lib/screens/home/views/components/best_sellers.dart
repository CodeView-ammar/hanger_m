import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/l10n/app_localizations.dart';
import 'package:melaq/models/product_model.dart';
import 'package:melaq/route/route_constants.dart';
import 'package:melaq/screens/home/views/components/location_service.dart';
import 'package:melaq/screens/laundry_details_screen.dart';
class BestSellers extends StatefulWidget {
  const BestSellers({Key? key}) : super(key: key);

  @override
  State<BestSellers> createState() => BestSellersState();
}

class BestSellersState extends State<BestSellers> {
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

// دالة تحديث المنتجات الداخلية (غير متاحة للاستخدام الخارجي)
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

// دالة جديدة للتحديث المتاحة للاستخدام الخارجي (من الشاشة الرئيسية)
Future<void> refreshData() async {
  // إعادة تعيين الصفحة وتحديث البيانات
  await _refreshProducts();
  return;
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
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.closest_you,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (query) {
                  _refreshProducts(); // تحديث القائمة مباشرة عند البحث
                },
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.search,
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 56,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج مطابقة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'حاول البحث بكلمات مختلفة',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
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
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // محاولة تحميل الصورة مع قياس ثابت
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      width: 75,
                      height: 75,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return Container(
                            width: 75,
                            height: 75,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 75,
                          height: 75,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // الانتقال إلى شاشة تفاصيل المغسلة
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LaundryDetailsScreen(
                                  laundry: {
                                    'id': products[index].id,
                                    'name': products[index].name,
                                    'address': products[index].address,
                                    'phone': products[index].phone ?? '',
                                    'email': products[index].email ?? '',
                                    'image': products[index].image,
                                    'x_map': products[index].x_latitude?.toString() ?? '',
                                    'y_map': products[index].y_longitude?.toString() ?? '',
                                    'owner_name': products[index].ownerName ?? '',
                                    'created_at': DateTime.now().toIso8601String(),
                                    'updated_at': DateTime.now().toIso8601String(),
                                  },
                                ),
                              ),
                            );
                          },
                          child: Text(
                            products[index].name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F1A40),
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (products[index].address != null && products[index].address!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              products[index].address!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 8),
                        FutureBuilder<Map<String, dynamic>?>( 
                          future: _getDistanceAndDuration(products[index]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Row(
                                children: [
                                  Icon(Icons.access_time, size: 16, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context)!.loding,
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                ],
                              );
                            } else if (snapshot.hasData) {
                              final distance = snapshot.data!['distance'];
                              final duration = snapshot.data!['duration'];
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.directions_car,
                                      size: 16,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${distance!.toStringAsFixed(1)} كم - $duration',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'غير متوفر',
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[600],
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
