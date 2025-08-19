import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/components/custom_messages.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/l10n/app_localizations.dart';
import 'package:melaq/route/route_constants.dart';
import 'package:melaq/screens/checkout/views/cart_screen.dart';
import 'package:melaq/screens/checkout/views/delegate_note.dart';
import 'package:melaq/screens/checkout/views/payment_method.dart';
import 'package:melaq/screens/checkout/views/delivery_method_screen.dart';

class ReviewOrderScreen extends StatefulWidget {
  final int laundryId;
  final double total;
  final bool isPaid;
  final double distance;
  final String duration;
  final String? defaultPaymentMethod;
  const ReviewOrderScreen({
    Key? key,
    required this.laundryId,
    required this.total,
    required this.isPaid,
    required this.distance,
    required this.duration,
    this.defaultPaymentMethod,
  }) : super(key: key);

  @override
  _ReviewOrderScreenState createState() => _ReviewOrderScreenState();
}

class _ReviewOrderScreenState extends State<ReviewOrderScreen> {
  String? address;
  double? x_map;
  double? y_map;
  String delegateNote = '';
  late GoogleMapController mapController;
  late BitmapDescriptor customMarker;
  LatLng userLocationMarker = LatLng(0.0, 0.0);
  String selectedPayment = 'عادي'; // default value
  String? defaultPaymentMethod; // Store default payment method
  String? price_per_kg;
  bool isPaid = false;
  bool _isSubmittingOrder = false;
  String deliveryMethod = 'pickup'; // طريقة التوصيل الافتراضية

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

@override
void initState() {
  super.initState();
  _loadCustomMarker(); // Load custom marker image
  fetchAddress();
  _initializePaymentMethod();
  fetchPricePerKg().then((price) {
    if (price != null) {
      setState(() {
        price_per_kg = price;
      });
    } else {
      print('لم يتم جلب السعر.');
    }
  });

}

void _initializePaymentMethod() {
  // Initialize payment method from widget parameters
  setState(() {
    defaultPaymentMethod = widget.defaultPaymentMethod;
    isPaid = widget.isPaid;
  });
  
  // Fetch additional payment method data if needed
  fetchDefaultPaymentMethod();
}

  Future<String?> fetchPricePerKg() async {
    final response = await http.get(Uri.parse(APIConfig.deliverysettingEndpoint));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // print(data[0]);
      return data[0]['price_per_kg'];
    } else {
      print('فشل في جلب السعر: ${response.statusCode}');
      return null;
    }
  }

  double get totalAmount {
    double deliveryPrice = (price_per_kg != null && widget.distance != null)
        ? (double.tryParse(price_per_kg!)! * widget.distance)
        : 0.0;
    return (widget.total + deliveryPrice);
  }

  Future<void> fetchDefaultPaymentMethod() async {
    print("Payment method from widget: " + widget.defaultPaymentMethod.toString());
    
    // If payment method is already provided from widget, use it
    if (widget.defaultPaymentMethod != null && widget.defaultPaymentMethod!.isNotEmpty) {
      setState(() {
        defaultPaymentMethod = widget.defaultPaymentMethod;
        isPaid = widget.isPaid;
      });
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');
    print(userId);
    
    if (userId == null) return;
    
    try {
      final response = await http.get(
        Uri.parse("${APIConfig.getPaymentMethodViewSetUrl}?user=$userId"),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          String payment = responseData['payment_method'] ?? '';
          print("Fetched payment method: $payment");
          
          switch (payment) {
            case "الدفع عند الاستلام":
              defaultPaymentMethod = "COD";
              break;
            case "الدفع باستخدام البطاقة":
              defaultPaymentMethod = "CARD";
              break;
            case "الدفع باستخدام STC":
              defaultPaymentMethod = "STC";
              break;
            default:
              defaultPaymentMethod = "";
          }
          
          if (isPaid) {
            defaultPaymentMethod = "CARD";
          }
        });
      } else {
        print('Error fetching payment method: ${response.body}');
      }
    } catch (e) {
      print('Exception while fetching payment method: $e');
    }
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('طريقة الدفع مطلوبة'),
          content: const Text('يرجى اختيار طريقة الدفع قبل متابعة الطلب.'),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.oK),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToPaymentMethod();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToPaymentMethod() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCardDetailsScreen(
          name_windows: 'payment_selection',
          totalAmount: totalAmount,
          laundryId: widget.laundryId.toString(),
        ),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          isPaid = result['isPaid'] ?? false;
          defaultPaymentMethod = result['defaultPaymentMethod'] ?? '';
        });
        print("Payment completed with method: $defaultPaymentMethod, isPaid: $isPaid");
      }
    });
  }

  // عرض رسائل الخطأ باستخدام مكون الرسائل المخصص
  void _showErrorDialog(String message) {
    AppMessageService().showErrorMessage(context, message, duration: const Duration(seconds: 4));
  }
  
  // عرض رسالة نجاح
  void _showSuccessMessage(String message) {
    AppMessageService().showSuccessMessage(context, message, duration: const Duration(seconds: 3));
  }
  
  // عرض رسالة تنبيه
  void _showInfoMessage(String message) {
    AppMessageService().showInfoMessage(context, message, duration: const Duration(seconds: 3));
  }

  Future<void> submitOrder() async {
    if (_isSubmittingOrder) return; // Prevent multiple submissions
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');
    
    if (userId == null) {
      _showErrorDialog("لا يوجد معرف للمستخدم.");
      return;
    }
    
    print("Submitting order with payment method: $defaultPaymentMethod");
    
    // Check if payment method is selected
    if (defaultPaymentMethod == null || defaultPaymentMethod!.isEmpty) {
      _showPaymentMethodDialog();
      return;
    }
    
    setState(() {
      _isSubmittingOrder = true;
    });
    
    try {
      final response = await http.post(
        Uri.parse('${APIConfig.orderSubmitUrl}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'laundryId': widget.laundryId,
          'userId': userId,
          'delegateNote': delegateNote,
          'paymentMethod': defaultPaymentMethod,
          'isPaid': isPaid,
          'totalAmount': totalAmount,
          'deliveryMethod': deliveryMethod  // يتم تمرير طريقة التوصيل
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessMessage(AppLocalizations.of(context)!.yrhbss);
        Navigator.of(context).pushNamedAndRemoveUntil(entryPointScreenRoute, (route) => false);
      } else {
        _showErrorDialog('فشل في إرسال الطلب: ${response.body}');
      }
    } catch (e) {
      _showErrorDialog("حدث خطأ أثناء إرسال الطلب: $e");
    } finally {
      setState(() {
        _isSubmittingOrder = false;
      });
    }
  }

  Future<void> _loadCustomMarker() async {
    customMarker = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(38, 38)),
      'assets/icons/pin.png',
    );
    setState(() {});
  }

  Future<void> fetchAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');
    final response = await http.get(Uri.parse('${APIConfig.getaddressEndpoint}$userId/'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        address = utf8.decode(data['address_line'].codeUnits);
        x_map = double.tryParse(data['x_map'].toString());
        y_map = double.tryParse(data['y_map'].toString());
        if (x_map != null && y_map != null && mapController != null) {
          try {
            mapController.moveCamera(CameraUpdate.newLatLng(LatLng(x_map!, y_map!)));
          } catch (e) {
            print(e);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في تحميل العنوان.')),
          );
          Navigator.pushNamed(context, addressesScreenRoute);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في تحميل العنوان.')),
      );
      Navigator.pushNamed(context, addressesScreenRoute);
    }
  }

  String formatAddress(String address) {
    if (address.length > 20) {
      return address.substring(0, 25) + '...';
    }
    return address;
  }

  String _getPaymentMethodDisplayName() {
    switch (defaultPaymentMethod) {
      case 'COD':
        return 'الدفع عند الاستلام';
      case 'CARD':
        return 'الدفع باستخدام البطاقة';
      case 'STC':
        return 'الدفع باستخدام STC';
      default:
        return 'لم يتم تحديد طريقة الدفع';
    }
  }

  String _getPaymentStatusText() {
    switch (defaultPaymentMethod) {
      case 'COD':
        return 'لم يتم الدفع بعد';
      case 'CARD':
      case 'STC':
        return isPaid ? 'تم الدفع بنجاح' : 'لم يتم الدفع بعد';
      default:
        return '';
    }
  }

  Color _getPaymentStatusColor() {
    switch (defaultPaymentMethod) {
      case 'COD':
        return Colors.orange;
      case 'CARD':
      case 'STC':
        return isPaid ? Colors.green : Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon() {
    switch (defaultPaymentMethod) {
      case 'COD':
        return Icons.money_off;
      case 'CARD':
        return Icons.credit_card;
      case 'STC':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }

  double get deliveryPrice {
    if (price_per_kg != null && widget.distance != null) {
      return double.tryParse(price_per_kg!)! * widget.distance;
    }
    return 0.0;
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.reviewrequest,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        shadowColor: Colors.grey[200],
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: Colors.grey[700], size: 20),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartScreen(),
                settings: RouteSettings(
                  arguments: {
                    'id': widget.laundryId,
                  },
                ),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Delivery Details Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.delivery_dining, color: primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.deliverydetails,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Delivery Time
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.access_time, color: Colors.blue[700], size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "وقت التوصيل المتوقع",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.duration.contains("mins")
                                      ? "${(int.tryParse(widget.duration.split("mins")[0]) ?? 0) + 10} دقيقة"
                                      : "30-45 دقيقة",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Delivery Address with Map
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.location_on, color: primaryColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "عنوان التوصيل",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 160,
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(x_map ?? 21.612702719986466, y_map ?? 39.14032716304064),
                                zoom: 15.0,
                              ),
                              markers: {
                                if (x_map != null && y_map != null && customMarker != null)
                                  Marker(
                                    markerId: const MarkerId('delivery_location'),
                                    position: LatLng(x_map!, y_map!),
                                    icon: customMarker,
                                  ),
                              },
                              zoomControlsEnabled: false,
                              scrollGesturesEnabled: false,
                              zoomGesturesEnabled: false,
                              mapToolbarEnabled: false,
                              onMapCreated: (GoogleMapController controller) {
                                mapController = controller;
                                if (x_map != null && y_map != null) {
                                  mapController.moveCamera(CameraUpdate.newLatLng(LatLng(x_map!, y_map!)));
                                }
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              address != null ? address! : "جاري تحميل العنوان...",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Order Summary Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          "ملخص الطلب",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Order Amount
                    _buildSummaryRow(
                      "إجمالي المنتجات",
                      "${widget.total.toStringAsFixed(2)} ر.س",
                      Icons.shopping_bag_outlined,
                      Colors.blue[600]!,
                    ),
                    const SizedBox(height: 12),
                    
                    // Delivery Cost
                    _buildSummaryRow(
                      "رسوم التوصيل (${widget.distance.toStringAsFixed(1)} كم)",
                      "${deliveryPrice.toStringAsFixed(2)} ر.س",
                      Icons.delivery_dining,
                      Colors.orange[600]!,
                    ),
                    
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[300], thickness: 1),
                    const SizedBox(height: 16),
                    
                    // Total Amount
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet, color: Colors.green[700], size: 24),
                              const SizedBox(width: 12),
                              Text(
                                "المبلغ الإجمالي",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "${totalAmount.toStringAsFixed(2)} ر.س",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Delivery Method Section
              // Container(
              //   padding: const EdgeInsets.all(20),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(16),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withOpacity(0.08),
              //         blurRadius: 10,
              //         offset: const Offset(0, 4),
              //       ),
              //     ],
              //   ),
              //   child:  Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
                    // Row(
                    //   children: [
                    //     Icon(Icons.local_shipping, color: primaryColor, size: 24),
                    //     const SizedBox(width: 12),
                    //     Text(
                    //       "طريقة الاستلام",
                    //       style: TextStyle(
                    //         fontSize: 20,
                    //         fontWeight: FontWeight.bold,
                    //         color: Colors.grey[800],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: 16),
                    
                    // Container(
                    //   padding: const EdgeInsets.all(16),
                    //   decoration: BoxDecoration(
                    //     color: Colors.grey[50],
                    //     borderRadius: BorderRadius.circular(12),
                    //     border: Border.all(color: Colors.grey[200]!),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Container(
                    //         padding: const EdgeInsets.all(10),
                    //         decoration: BoxDecoration(
                    //           color: deliveryMethod == 'delivery' 
                    //               ? Colors.green.withOpacity(0.1)
                    //               : Colors.blue.withOpacity(0.1),
                    //           borderRadius: BorderRadius.circular(10),
                    //         ),
                    //         child: Icon(
                    //           deliveryMethod == 'delivery' 
                    //               ? Icons.delivery_dining
                    //               : Icons.store,
                    //           color: deliveryMethod == 'delivery' 
                    //               ? Colors.green
                    //               : Colors.blue,
                    //           size: 24,
                    //         ),
                    //       ),
                    //       const SizedBox(width: 16),
                          // Expanded(
                          //   child: Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                                // Text(
                                //   deliveryMethod == 'delivery' 
                                //       ? 'توصيل للمنزل'
                                //       : 'استلام من المغسلة',
                                //   style: const TextStyle(
                                //     fontSize: 16,
                                //     fontWeight: FontWeight.w600,
                                //   ),
                                // ),
                                // const SizedBox(height: 4),
                                // Text(
                                //   deliveryMethod == 'delivery' 
                                //       ? 'سيقوم مندوب بتوصيل الطلب'
                                //       : 'قم بزيارة المغسلة لاستلام طلبك',
                                //   style: const TextStyle(
                                //     fontSize: 12,
                                //     color: Colors.grey,
                                //   ),
                                // ),
                          //     ],
                          //   ),
                          // ),
                          // TextButton.icon(
                            // onPressed: () async {
                            //   final result = await Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //       builder: (context) => DeliveryMethodScreen(),
                            //     ),
                            //   );
                            //   if (result != null) {
                            //     setState(() {
                            //       deliveryMethod = result;
                            //     });
                            //   }
                            // },
                            // icon: const Icon(Icons.edit, size: 16),
                            // label: const Text("تغيير"),
                            // style: TextButton.styleFrom(
                            //   foregroundColor: primaryColor,
                            //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            // ),
                          // ),
              //           ],
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 20),
              
              // Payment Method Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          "طريقة الدفع",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getPaymentMethodIcon(),
                                  color: primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getPaymentMethodDisplayName(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (_getPaymentStatusText().isNotEmpty)
                                      Text(
                                        _getPaymentStatusText(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getPaymentStatusColor(),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _navigateToPaymentMethod,
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text("تغيير"),
                                style: TextButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Delegate Note Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note_add, color: primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.notedelegate,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DelegateNoteScreen(delegateNote: delegateNote),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            delegateNote = result;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              delegateNote.isEmpty ? Icons.add_comment : Icons.comment,
                              color: delegateNote.isEmpty ? Colors.grey[400] : primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                delegateNote.isEmpty ? "اضغط لإضافة ملاحظة للمندوب" : delegateNote,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: delegateNote.isEmpty ? Colors.grey[600] : Colors.grey[800],
                                  fontWeight: delegateNote.isEmpty ? FontWeight.w400 : FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.edit,
                              color: Colors.grey[400],
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Submit Order Button
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmittingOrder ? null : submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmittingOrder
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              "جاري إرسال الطلب...",
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "تأكيد الطلب",
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
