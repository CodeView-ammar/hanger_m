import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/components/cart_button.dart';
import 'package:melaq/components/custom_modal_bottom_sheet.dart';
import 'package:melaq/l10n/app_localizations.dart';
import 'package:melaq/route/route_constants.dart';
import 'package:melaq/screens/product/views/added_to_cart_message_screen.dart';
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
      name: utf8.decode(json['name'].codeUnits),
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
  List<SubService> _selectedSubServices = [];

  @override
  void initState() {
    super.initState();
    _fetchSubServices();
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
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _addToCart() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');

    if (userId == null) {
      Navigator.pushNamed(context, logInScreenRoute);
      return;
    }

    // تحديد السعر حسب نوع الخدمة
    final basePrice = _serviceType == 'مستعجلة' 
        ? widget.serveiceUrgentPrice 
        : widget.servicePrice;

    final totalSubServicePrice = _selectedSubServices.fold(0.0, (sum, item) => sum + item.price);
    final selectedPrice = totalSubServicePrice + (basePrice * _quantity);
    final tServicetype = _serviceType == 'مستعجلة' ? 'urgent' : 'normal';

    try {
      final response = await http.post(
        Uri.parse(APIConfig.CartsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'price': selectedPrice,
          'urgent_price': widget.serveiceUrgentPrice,
          'quantity': _quantity,
          'user': userId,
          'laundry': widget.laundry,
          'service': widget.serviceId,
          'service_type': tServicetype,
          'sub_service_ids': _selectedSubServices.map((s) => s.id).toList(),
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
          const SnackBar(content: Text('فشل في إضافة المنتج إلى السلة!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ في الاتصال!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // تحديد السعر الأساسي بناءً على نوع الخدمة
    final basePrice = _serviceType == 'مستعجلة' 
        ? widget.serveiceUrgentPrice 
        : widget.servicePrice;

    final totalPrice = (basePrice * _quantity) + 
        _selectedSubServices.fold(0, (sum, item) => sum + item.price);

    return Scaffold(
      bottomNavigationBar: CartButton(
        price: totalPrice,
        title: "اضافة للسلة",
        subTitle: "الإجمالي",
        press: _addToCart,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: defaultPadding / 2, 
              vertical: defaultPadding
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BackButton(),
                Text(
                  widget.serviceName,
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.black
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  UnitPrice(price: totalPrice),
                                  if (_serviceType == 'مستعجلة')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '(+${(widget.serveiceUrgentPrice - widget.servicePrice).toStringAsFixed(1)} للخدمة المستعجلة)',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            ProductQuantity(
                              numOfItem: _quantity,
                              onIncrement: () => setState(() => _quantity++),
                              onDecrement: () => setState(() {
                                if (_quantity > 1) _quantity--;
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: defaultPadding),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.servicetype,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            _buildServiceTypeTile(
                              title: AppLocalizations.of(context)!.normal,
                              price: widget.servicePrice,
                              isSelected: _serviceType == 'عادية',
                              onTap: () => setState(() {
                                _serviceType = 'عادية';
                                _selectedSubServices.clear();
                              }),
                            ),
                            _buildServiceTypeTile(
                              title: AppLocalizations.of(context)!.urgent,
                              price: widget.serveiceUrgentPrice,
                              isSelected: _serviceType == 'مستعجلة',
                              onTap: () => setState(() {
                                _serviceType = 'مستعجلة';
                                _selectedSubServices.clear();
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: defaultPadding),
                        if (_subServices.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.subService,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              ..._subServices.map(_buildSubServiceItem).toList(),
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

  Widget _buildServiceTypeTile({
    required String title,
    required double price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Row(
        children: [
          Text(title),
          const SizedBox(width: 8),
          Text(
            '${price.toStringAsFixed(1)} ر.س',
            style: TextStyle(
              color: isSelected ? primaryColor : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      leading: Transform.scale(
        scale: 1.5,
        child: Checkbox(
          activeColor: primaryColor, // اللون لما يكون محدد
          checkColor: Colors.white,
          value: isSelected,
          onChanged: (bool? value) => onTap(),
        ),
      ),
    );
  }

  Widget _buildSubServiceItem(SubService subService) {
    return ListTile(
      title: Text(subService.name),
      trailing: Text(
        '${subService.price.toStringAsFixed(1)} ر.س',
        style: TextStyle(
          color: _selectedSubServices.contains(subService)
              ? primaryColor
              : Colors.grey.shade600,
        ),
      ),
      leading: Transform.scale(
        scale: 1.5,
        child: Checkbox(
          activeColor: primaryColor, // اللون لما يكون محدد
          checkColor: Colors.white,
          value: _selectedSubServices.contains(subService),
          onChanged: (bool? value) => setState(() {
            if (value == true) {
              _selectedSubServices.add(subService);
            } else {
              _selectedSubServices.remove(subService);
            }
          }),
        ),
      ),
    );
  }
}