import 'dart:convert';  // لإجراء عمليات تحويل JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;  // لإرسال الطلبات HTTP
import 'package:shared_preferences/shared_preferences.dart';  // لاستخدام SharedPreferences
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/components/cart_button.dart';
import 'package:shop/components/custom_modal_bottom_sheet.dart';
import 'package:shop/l10n/app_localizations.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/product/views/added_to_cart_message_screen.dart';

import '../../../constants.dart';
import 'components/product_quantity.dart';
import 'components/unit_price.dart';

class ProductBuyNowScreen extends StatefulWidget {
  final String serviceName;
  final double servicePrice;
  final double serveiceUrgentPrice;
  final String serviceImage;
  final int quantity;
  final int laundry;
  final int serviceId;
  final double distance; // إضافة المسافة
  final String duration; // إضافة الوقت

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
  String _serviceType = 'عادية';  // إضافة متغير لتحديد نوع الخدمة (مستعجلة أو عادية)

  // دالة لإضافة المنتج إلى السلة
  Future<void> _addToCart() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');  // جلب ID المستخدم من SharedPreferences

    if (userId == null) {
      // إذا لم يكن ID المستخدم موجودًا، يمكنك عرض رسالة خطأ
      Navigator.pushNamed(context, logInScreenRoute);
      return;
    }

    // تحديد السعر بناءً على نوع الخدمة
    double selectedPrice = (_serviceType == 'مستعجلة') ? widget.serveiceUrgentPrice : widget.servicePrice;
    String tServicetype = (_serviceType == 'مستعجلة') ? 'urgent' : 'normal';

    final url = APIConfig.CartsEndpoint;  // استبدل بـ URL الخاص بك
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'price': selectedPrice,  // استخدام السعر الذي تم اختياره بناءً على نوع الخدمة
          "urgent_price": widget.serveiceUrgentPrice,
          'quantity': _quantity,
          'user': userId,
          'laundry': widget.laundry,
          'service': widget.serviceId,
          'service_type': tServicetype,  // إرسال نوع الخدمة
        }),
      );

      // print(response.statusCode);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // إذا تم إضافة المنتج بنجاح

        customModalBottomSheet(
          context,
          isDismissible: false,
          child: AddedToCartMessageScreen(laundryId: widget.laundry),
        );
      } else {
        // معالجة الخطأ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إضافة المنتج إلى السلة!'),
          ),
        );
      }
    } catch (e) {
      // في حال حدوث أي خطأ في الاتصال
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في الاتصال!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // حساب السعر الإجمالي بناءً على نوع الخدمة
    double totalPrice = (_serviceType == 'مستعجلة') 
        ? widget.serveiceUrgentPrice * _quantity
        : widget.servicePrice * _quantity;

    return Scaffold(
      bottomNavigationBar: CartButton(
        price: totalPrice,
        title: "اضافة للسلة",
        subTitle: "الإجمالي",
        press: () {
          _addToCart();  // استدعاء دالة إضافة المنتج إلى السلة
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding / 2, vertical: defaultPadding),
            child: Row(
              
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BackButton(),
                    Text(
                      widget.serviceName,
                      style: TextStyle(
                        fontSize: 16, // حجم الخط
                        fontWeight: FontWeight.bold, // سمك الخط
                        color: Colors.black, // لون النص
                      ),
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
                              child: UnitPrice(
                                price: (_serviceType == 'مستعجلة') 
                                  ? widget.serveiceUrgentPrice
                                  : widget.servicePrice,
                              ),
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
                        // إضافة اختيار نوع الخدمة كقائمة
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.servicetype, style: Theme.of(context).textTheme.bodyLarge),
                            ListTile(
                              title: Text(AppLocalizations.of(context)!.normal),
                              leading: Transform.scale(
                                scale: 1.5,  // تكبير الراديو بوتون
                                child: Radio<String>(
                                  focusColor: primaryColor,
                                  value: 'عادية',
                                  groupValue: _serviceType,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _serviceType = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                            ListTile(
                              title: Text(AppLocalizations.of(context)!.urgent),
                              leading: Transform.scale(
                                scale: 1.5,  // تكبير الراديو بوتون
                                child: Radio<String>(
                                  focusColor: primaryColor,
                                  value: 'مستعجلة',
                                  groupValue: _serviceType,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _serviceType = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
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
