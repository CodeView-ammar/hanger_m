import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/checkout/views/cart_screen.dart';
import 'package:shop/screens/product/views/components/product_images.dart';
import 'package:shop/screens/product/views/components/service_info.dart';
import 'package:shop/screens/product/views/map_screen_laundry.dart';
import 'package:shop/screens/product/views/product_buy_now_screen.dart';

// نموذج البيانات للخدمة
class ServiceModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final double urgentPrice;
  final String image;

  ServiceModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.urgentPrice,
    required this.image,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      name: utf8.decode(json['name'].codeUnits),
      description: json['description'],
      price: double.parse(json['price']),
      urgentPrice: double.parse(json['urgent_price']),
      image: json['image'] ?? '',
    );
  }
}

// نموذج البيانات للتصنيف
class CategoryModel {
  final int id;
  final String name;

  CategoryModel({required this.id, required this.name});
}

class ProductDetailsScreen extends StatefulWidget {
  final bool isAvailable;
  final int id;
  final String name;
  final String image;
  final String address;
  final double latitude;
  final double longitude;
  final double distance;
  final String duration;

  const ProductDetailsScreen({
    super.key,
    required this.id,
    required this.isAvailable,
    required this.name,
    required this.image,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.duration,
  });

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  List<ServiceModel> _services = []; // تعديل هنا
  double totalPrice = 0.0;

  // قائمة التصنيفات
  late Future<List<CategoryModel>> _categories;
  int? selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = 0; // تعيين التصنيف الافتراضي كـ "الكل"
    _categories = fetchCategories(widget.id); // جلب التصنيفات
    fetchServices(widget.id, selectedCategory); // جلب الخدمات مع التصنيف الافتراضي
    fetchTotalPrice(widget.id);
  }

  Future<void> fetchTotalPrice(int serverid) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');
    final response = await http.get(Uri.parse('${APIConfig.cartfilterEndpoint}?user=$userId&laundry=$serverid'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          totalPrice = (data['total_price'] is int) ? (data['total_price'] as int).toDouble() : (data['total_price'] ?? 0.0);
        });
      }
    } else {
      totalPrice = 0.0;
    }
  }

  Future<void> fetchServices(int id, int? category) async {
    String url = '${APIConfig.servicesEndpoint}?laundry_id=$id';
    if (category != null && category != 0) {
      url += '&category=$category'; // إضافة معلمة التصنيف إذا لم يكن "الكل"
    }

    final response = await http.get(Uri.parse(url));
    print("Fetching services from: $url");

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      
      setState(() {
        _services = data.map((item) => ServiceModel.fromJson(item['service'])).toList(); // تحديث القائمة مباشرة
      });
    } else {
      throw Exception('المغسلة لا تمتلك خدمات');
    }
  }
 Future<void> saveLaundryData(String laundry) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid'); // استرجاع userId من SharedPreferences إذا كان موجودًا

    final url = APIConfig.markerEndpoint;

    final body = json.encode({
      'user': userId, // إذا لم يكن هناك userId في SharedPreferences، يتم إرسال المستخدم من المعامل
      'laundry': int.parse(laundry),     // البيانات المغسلة التي يتم إرسالها
    });

    try {
     final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );
      print(response);
     print('Sending data: $body');
      if (response.statusCode == 200 || response.statusCode ==201) {
        // إذا تم الحفظ بنجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ بيانات المغسلة بنجاح')),
        );
      } else {
        // إذا كانت هناك مشكلة في الاتصال أو حفظ البيانات
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في حفظ البيانات')),
        );
      }
    } catch (e) {
      // إذا حدثت مشكلة في الاتصال بالخادم
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء الاتصال بالخادم')),
      );
    }
  }

  Future<List<CategoryModel>> fetchCategories(int id) async {
    final response = await http.get(Uri.parse('${APIConfig.categoriesEndpoint}?laundry_id=$id'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      List<CategoryModel> categories = List<CategoryModel>.from(
        data.map((item) => CategoryModel(
          id: item['id'],
          name: utf8.decode(item['name'].codeUnits),
        ))
      );

      categories.insert(0, CategoryModel(id: 0, name: "الكل"));
      return categories;
    } else {
      throw Exception('فشل في جلب التصنيفات');
    }
  }

  void showCustomBottomSheet(BuildContext context, ServiceModel service, int quantity) async {
    await customModalBottomSheet(
      context,
      height: MediaQuery.of(context).size.height * 0.92,
      child: ProductBuyNowScreen(
        serviceId: service.id,
        serviceName: service.name,
        servicePrice: service.price * quantity,
        serveiceUrgentPrice: service.urgentPrice * quantity,
        serviceImage: service.image,
        quantity: quantity,
        laundry: widget.id,
        distance: widget.distance,
        duration: widget.duration,
      ),
    );

    await fetchTotalPrice(widget.id);
  }

  void filterServices(int categoryId) {
    setState(() {
      selectedCategory = categoryId; // تعيين التصنيف المحدد
    });
    fetchServices(widget.id, selectedCategory); // فقط تحديث الخدمات
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CartButton(
        price: totalPrice,
        press: () async {
          if (totalPrice == 0.0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('لا يمكن الانتقال إلى السلة لأن الإجمالي هو 0')),
            );
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartScreen(),
                settings: RouteSettings(
                  arguments: {
                    'id': widget.id,
                    'distance': widget.distance,
                    'duration': widget.duration,
                  },
                ),
              ),
            );

            await fetchTotalPrice(widget.id);
          }
        },
      ),
      body: SafeArea(
        child: _services.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    floating: true,
                    actions: [
                      IconButton(
                        onPressed: () {
                         saveLaundryData(widget.id.toString()); // منطق حفظ بيانات المغسلة
                        },
                        icon: SvgPicture.asset(
                          "assets/icons/Bookmark.svg",
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapScreen(
                                id: widget.id,
                                latitude: widget.latitude,
                                longitude: widget.longitude,
                              ),
                            ),
                          );
                        },
                        icon: SvgPicture.asset(
                          "assets/icons/Location.svg",
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                      ),
                    ],
                  ),
                  ProductImages(
                    images: [
                      widget.image.isEmpty ? '${APIConfig.static_baseUrl}/images/store.jpg' : widget.image,
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(defaultPadding),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        "${widget.distance} كم - ${widget.duration} دقيقة",
                        style: Theme.of(context).textTheme.titleSmall!,
                      ),
                    ),
                  ),
                  ServiceInfo(
                    brand: widget.address,
                    title: widget.name,
                    isAvailable: widget.isAvailable,
                    description: "لا يوجد وصف",
                    rating: 4.3,
                    numOfReviews: 126,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(defaultPadding),
                    sliver: SliverToBoxAdapter(
                      child: FutureBuilder<List<CategoryModel>>(
                        future: _categories,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('خطأ في جلب التصنيفات'));
                          } else if (snapshot.hasData) {
                            final categories = snapshot.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: categories.map((category) {
                                      final isSelected = selectedCategory == category.id; // تعديل هنا
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: GestureDetector(
                                          onTap: () => filterServices(category.id), // استخدام id هنا
                                          child: Chip(
                                            label: Text(category.name),
                                            backgroundColor: isSelected ? primaryColor : primaryColor.withOpacity(0.2),
                                            labelStyle: TextStyle(color: isSelected ? Colors.white : primaryColor),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return const Center(child: Text('لا توجد تصنيفات'));
                          }
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(defaultPadding),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        "خدماتنا",
                        style: Theme.of(context).textTheme.titleSmall!,
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _services[index]; // استخدام القائمة المحلية
                        return Card(
                          color: secondaryColor,
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: ListTile(
                            leading: Image.network(
                              service.image.isEmpty ? '${APIConfig.static_baseUrl}/images/store.jpg' : service.image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            title: Text(service.name, style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255))),
                            subtitle: Text('السعر: \ر.س ${service.price.toStringAsFixed(2)}', style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255))),
                            trailing: IconButton(
                              icon: const Icon(Icons.add, color: Color.fromARGB(255, 255, 255, 255)),
                              onPressed: () {
                                showCustomBottomSheet(context, service, 1);
                              },
                            ),
                          )
                        );
                      },
                      childCount: _services.length,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}