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

class ProductDetailsScreen extends StatefulWidget {
  final bool isAvailable;
  final int id;
  final String name;
  final String image;
  final String address;
  final double latitude; // لإضافة خط العرض
  final double longitude; // لإضافة خط الطول
  final double distance;  // تمرير المسافة
  final String duration; // تمرير الوقت

  const ProductDetailsScreen({
    super.key,
    required this.id,
    required this.isAvailable,
    required this.name,
    required this.image,
    required this.address,
    required this.latitude, // لإضافة خط العرض
    required this.longitude, // لإضافة خط الطول
    required this.distance,
    required this.duration,
  });

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late Future<List<ServiceModel>> _services;
  double totalPrice = 0.0;  // إضافة متغير لتخزين total_price

  @override
  void initState() {
    super.initState();
    _services = fetchServices(widget.id);
    fetchTotalPrice(widget.id);  // جلب total_price من الـ API عند تحميل الصفحة
  }

  Future<void> fetchTotalPrice(serverid) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');  // جلب ID المستخدم من SharedPreferences
    final response = await http.get(Uri.parse('${APIConfig.cartfilterEndpoint}?user=$userId&laundry=$serverid'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          if (data['total_price'] == '') {
            totalPrice = 0.0; // إذا كانت total_price تساوي 0، قم بتعيين totalPrice إلى 0.0
          } else {
            // إذا كانت القيمة من نوع int، قم بتحويلها إلى double
            totalPrice = (data['total_price'] is int)
                ? (data['total_price'] as int).toDouble()
                : data['total_price']; // تحديث الـ total_price
          }
        });
      }
    } else {
      totalPrice=0.0;
    }
  }

  Future<List<ServiceModel>> fetchServices(id) async {
    final response = await http.get(Uri.parse('${APIConfig.servicesEndpoint}?laundry_id=${id}'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ServiceModel.fromJson(item)).toList();
    } else {
      throw Exception('المغسلة لا تمتلك خدمات');
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
        distance: widget.distance,  // تمرير المسافة
        duration: widget.duration, 
      ),
    );

    // تحديث totalPrice بعد إغلاق الشاشة
    await fetchTotalPrice(widget.id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CartButton(
        price: totalPrice,
        press: () async {
          // تحقق مما إذا كانت قيمة totalPrice 0
          if (totalPrice == 0.0) {
            // إذا كانت القيمة 0، أظهر رسالة للمستخدم
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('لا يمكن الانتقال إلى السلة لأن الإجمالي هو 0')),
            );
          } else {
            // إذا كانت قيمة totalPrice ليست 0، قم بالانتقال إلى شاشة السلة
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartScreen(),
                settings: RouteSettings(
                  arguments:{
                      'id': widget.id,  // تمرير الـ id هنا
                      'distance': widget.distance, // تمرير المسافة
                      'duration': widget.duration, // تمرير الوقت
                    },
                
                ),
              ),
            );

            // بعد العودة من شاشة السلة، قم بتحديث الإجمالي
            await fetchTotalPrice(widget.id);
            // تحديث الإجمالي في واجهة المستخدم
            setState(() {
              // هنا يمكنك تحديث أي حالة إذا لزم الأمر، لكن في هذا المثال لا حاجة لذلك
            });
          }
        },
      ),
      body: SafeArea(
        child: FutureBuilder<List<ServiceModel>>(
          future: _services,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('خطأ: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final services = snapshot.data!;
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    floating: true,
                    actions: [
                      IconButton(
                        onPressed: () {
                          saveLaundryData('1');
                        },
                        icon: SvgPicture.asset(
                          "assets/icons/Bookmark.svg",
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                      ),
                       IconButton(
                        onPressed: () {
                          // الانتقال إلى شاشة الخريطة عند النقر على الزر
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapScreen(
                                id:widget.id,
                                latitude: widget.latitude,
                                longitude: widget.longitude,
                              ),
                            ),
                          );
                        },
                        icon: SvgPicture.asset(
                          "assets/icons/Location.svg", // تأكد من وجود أيقونة خريطة
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                      ),
                    ],
                  ),
                  ProductImages(
                    images: [
                      widget.image.isEmpty ? '${APIConfig.static_baseUrl}/images/store.jpg' : widget.image, // إذا كانت الصورة فارغة، استخدم الصورة الافتراضية
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(defaultPadding),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        widget.distance.toString()+"كم"+" - "+widget.duration.toString()+"دقيقة",
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
                      child: Text(
                        "خدماتنا",
                        style: Theme.of(context).textTheme.titleSmall!,
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = services[index];
                        return Card(
                        color: secondaryColor,
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: ListTile(
                            leading: Image.network(
                              service.image.isEmpty ? '${APIConfig.static_baseUrl}/images/store.jpg' : service.image,  // استخدم الصورة الافتراضية إذا كانت الصورة فارغة
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            title: Text(service.name, style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255))),
                            subtitle: Text('السعر: \ر.س ${service.price.toStringAsFixed(2)}', style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255))),
                            trailing: IconButton(
                              icon: const Icon(Icons.add, color: Color.fromARGB(255, 255, 255, 255)),
                              onPressed: () {
                                showCustomBottomSheet(context, service, 1); // يمكنك هنا تعديل الكمية
                              },
                            ),
                          ),
                        );
                      },
                      childCount: services.length,
                    ),
                  ),
                ],
              );
            } else {
              return const Center(child: Text('لا توجد بيانات للخدمات'));
            }
          },
        ),
      ),
    );
  }
}
