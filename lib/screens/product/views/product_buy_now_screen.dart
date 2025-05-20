import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
import 'package:shop/l10n/app_localizations.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/product/views/added_to_cart_message_screen.dart';
import '../../../constants.dart';
import 'components/product_quantity.dart';
import 'components/unit_price.dart';

class SubService {
  final int id;
  final String name;
  final double price;

  SubService({required this.id, required this.name, required this.price});

  factory SubService.fromJson(Map<String, dynamic> json) {
    return SubService(
      id: json['id'],
      name: utf8.decode(json['name'].codeUnits) ,
      price: double.parse(json['price']),
    );
  }
}

class ProductBuyNowScreen extends StatefulWidget {
  final String serviceName;
  final double servicePrice;
  final double serveiceUrgentPrice;
  final String serviceImage;
  final int quantity;
  final int laundry;
  final int serviceId;
  final double distance;
  final String duration;

  const ProductBuyNowScreen({
    super.key,
    required this.serviceName,
    required this.servicePrice,
    required this.serveiceUrgentPrice,
    required this.serviceImage,
    required this.quantity,
    required this.laundry,
    required this.serviceId,
    required this.distance,
    required this.duration,
  });

  @override
  _ProductBuyNowScreenState createState() => _ProductBuyNowScreenState();
}

class _ProductBuyNowScreenState extends State<ProductBuyNowScreen> {
  int _quantity = 1;
  String _serviceType = 'عادية';
  List<SubService> _subServices = [];
  List<SubService> _selectedSubServices = []; // قائمة لاختيار الخدمات الفرعية

  @override
  void initState() {
    super.initState();
    _fetchSubServices(); // Fetch sub-services on init
  }

  Future<void> _fetchSubServices() async {
    final url = '${APIConfig.SubServicesEndpoint}?LaundryService_id=${widget.serviceId}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _subServices = data.map((json) => SubService.fromJson(json)).toList();
        });
      } else {
        // Handle error
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('فشل في جلب الخدمات الفرعية!')),
        // );
      }
    } catch (e) {
      // Handle connection error
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('حدث خطأ في الاتصال!')),
      // );
    }
  }

  Future<void> _addToCart() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');

    if (userId == null) {
      Navigator.pushNamed(context, logInScreenRoute);
      return;
    }

    double totalSubServicePrice = _selectedSubServices.fold(0, (sum, item) => sum + item.price);
    double selectedPrice = totalSubServicePrice + (widget.servicePrice * _quantity);
    String tServicetype = (_serviceType == 'مستعجلة') ? 'urgent' : 'normal';

    final url = APIConfig.CartsEndpoint;
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'price': selectedPrice,
          'urgent_price': widget.serveiceUrgentPrice,
          'quantity': _quantity,
          'user': userId,
          'laundry': widget.laundry,
          'service': widget.serviceId,
          'service_type': tServicetype,
          'sub_service_ids': _selectedSubServices.map((s) => s.id).toList(), // إرسال قائمة الخدمات الفرعية المختارة
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        customModalBottomSheet(
          context,
          isDismissible: false,
          child: AddedToCartMessageScreen(laundryId: widget.laundry),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في إضافة المنتج إلى السلة!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في الاتصال!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = (widget.servicePrice * _quantity) + _selectedSubServices.fold(0, (sum, item) => sum + item.price);

    return Scaffold(
      bottomNavigationBar: CartButton(
        price: totalPrice,
        title: "اضافة للسلة",
        subTitle: "الإجمالي",
        press: () {
          _addToCart();
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding / 2, vertical: defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BackButton(),
                Text(
                  widget.serviceName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(width: 18),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(defaultPadding),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: UnitPrice(price: totalPrice),
                            ),
                            ProductQuantity(
                              numOfItem: _quantity,
                              onIncrement: () {
                                setState(() {
                                  _quantity++;
                                });
                              },
                              onDecrement: () {
                                setState(() {
                                  if (_quantity > 1) {
                                    _quantity--;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: defaultPadding),
                        // اختيار نوع الخدمة
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.servicetype, style: Theme.of(context).textTheme.bodyLarge),
                            ListTile(
                              title: Text(AppLocalizations.of(context)!.normal),
                              leading: Transform.scale(
                                scale: 1.5,
                                child: Checkbox(
                                  value: _serviceType == 'عادية',
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _serviceType = 'عادية';
                                      _selectedSubServices.clear(); // إعادة تعيين اختيار الخدمات الفرعية
                                    });
                                  },
                                ),
                              ),
                            ),
                            ListTile(
                              title: Text(AppLocalizations.of(context)!.urgent),
                              leading: Transform.scale(
                                scale: 1.5,
                                child: Checkbox(
                                  value: _serviceType == 'مستعجلة',
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _serviceType = 'مستعجلة';
                                      _selectedSubServices.clear(); // إعادة تعيين اختيار الخدمات الفرعية
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: defaultPadding),
                        // عرض الخدمات الفرعية كصناديق اختيار
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.subService, style: Theme.of(context).textTheme.bodyLarge),
                            ..._subServices.map((subService) {
                              return ListTile(
                                title: Text(subService.name),
                                leading: Transform.scale(
                                  scale: 1.5,
                                  child: Checkbox(
                                    value: _selectedSubServices.contains(subService),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedSubServices.add(subService);
                                        } else {
                                          _selectedSubServices.remove(subService);
                                        }
                                      });
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: Divider()),
                const SliverToBoxAdapter(child: SizedBox(height: defaultPadding)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}