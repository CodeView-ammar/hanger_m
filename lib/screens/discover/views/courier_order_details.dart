import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/screens/checkout/views/payment_method.dart';
import 'package:melaq/screens/product/views/map_screen_laundry.dart';
import 'package:location/location.dart';

class CourierOrderDetailsScreen extends StatefulWidget {
  final int orderId;
  final bool isPaid;
  const CourierOrderDetailsScreen({Key? key, required this.orderId,required this.isPaid}) : super(key: key);

  @override
  _CourierOrderDetailsScreenState createState() => _CourierOrderDetailsScreenState();
}

class _CourierOrderDetailsScreenState extends State<CourierOrderDetailsScreen> {
  Map<String, dynamic> orderDetails = {};
  bool isLoading = true;
  bool isDistanceLoading = false;
  String? distanceText;
  double? pricePerKg;  // تخزين سعر الكيلو متر هنا
  double? totalDeliveryCost;  // تخزين تكلفة التوصيل الإجمالية هنا
  List<String> paymentMethods = [];  // تخزين طرق الدفع
  String? selectedPaymentMethod;  // طريقة الدفع المختارة
  String? defaultPaymentMethod; // Store default payment method

  @override
  void initState() {
    super.initState();
    fetchOrders(); // استدعاء دالة جلب تفاصيل الطلب
    fetchPricePerKg(); // جلب سعر الكيلو متر
    fetchDefaultPaymentMethod();
  }

Future<void> fetchDefaultPaymentMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');

    // Send request to the API
    final response = await http.post(
      Uri.parse(APIConfig.PaymentUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user': userId,
      }),
      
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      setState(() {

        // تحويل طريقة الدفع إلى القيمة التي سيقبلها الـ API
        if (defaultPaymentMethod == "الدفع عند الاستلام") {
          defaultPaymentMethod = "COD";
        } else if (defaultPaymentMethod == "الدفع باستخدام البطاقة") {
          defaultPaymentMethod = "CARD";
        } else if (defaultPaymentMethod == "الدفع باستخدام STC") {
          defaultPaymentMethod = "STC";
        }
        if (widget.isPaid) {
          defaultPaymentMethod = "تم الدفع باستخدام البطاقة"; // تم الدفع باستخدام البطاقة
        } else {
          defaultPaymentMethod = "الدفع عند الاستلام"; // الدفع عند الاستلام
        }

      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تحديد طريقة الدفع')),
      );
    }
  }

 // دالة لجلب الطلبات من API
Future<void> fetchOrders() async {
  final url = '${APIConfig.orderlaundryUrl}?orderid=${widget.orderId}'; // رابط الـ API
  final response = await http.get(Uri.parse(url));
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body); // تحويل البيانات إلى خريطة
    
    // تحقق من أن `data` ليست فارغة
    if (data.isNotEmpty) {
      setState(() {
        isLoading = false;
        orderDetails = {
          "id": data[0]['laundry_id'],
          'name': utf8.decode(data[0]['laundry_name'].codeUnits),
          'price': data[0]['total_amount']?.toString() ?? '0',
          'address': utf8.decode(data[0]['laundry_address'].codeUnits),
          'x_latitude': data[0]['laundry_x_map']?.toString() ?? 'غير متوفر',
          'y_longitude': data[0]['laundry_y_map']?.toString() ?? 'غير متوفر',
          'phone': data[0]['laundry_phone'] ?? 'رقم الهاتف غير متاح',
        };
      });
      // بعد جلب تفاصيل المغسلة، نحاول حساب المسافة
      _getUserLocationAndDistance();
    } else {
      // في حالة كانت البيانات فارغة
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("لم يتم العثور على بيانات الطلب")),
      );
    }
  } else {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("فشل في جلب البيانات من الخادم")),
    );
  }
}


  // دالة لجلب سعر الكيلو متر
  Future<void> fetchPricePerKg() async {
    final response = await http.get(Uri.parse(APIConfig.deliverysettingEndpoint));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        pricePerKg = double.tryParse(data[0]['price_per_kg'].toString()) ?? 0.0;
      });
    } else {
      print('فشل في جلب السعر: ${response.statusCode}');
    }
  }


  // دالة لحساب المسافة بين المستخدم والمغسلة
  Future<void> _getUserLocationAndDistance() async {
    setState(() {
      isDistanceLoading = true;
    });

    final location = Location();
    try {
      final currentLocation = await location.getLocation();
      final userLatitude = currentLocation.latitude ?? 0.0;
      final userLongitude = currentLocation.longitude ?? 0.0;

      final laundryLatitude = double.tryParse(orderDetails['x_latitude']) ?? 0.0;
      final laundryLongitude = double.tryParse(orderDetails['y_longitude']) ?? 0.0;

      final distanceData = await _getDistanceAndDuration(userLatitude, userLongitude, laundryLatitude, laundryLongitude);

      setState(() {
        distanceText = distanceData != null
            ? '${distanceData['distance'].toStringAsFixed(2)} كم - ${distanceData['duration']}'
            : 'المسافة غير متوفرة';
        // إذا كان لدينا المسافة وسعر الكيلو متر، نقوم بحساب التكلفة
        if (distanceData != null && pricePerKg != null) {
          totalDeliveryCost = distanceData['distance'] * pricePerKg!;
        }
        isDistanceLoading = false;
      });
    } catch (e) {
      setState(() {
        distanceText = 'فشل في جلب المسافة';
        isDistanceLoading = false;
      });
    }
  }

  // دالة لحساب المسافة والوقت بين موقعين باستخدام Google Maps Directions API
  Future<Map<String, dynamic>?> _getDistanceAndDuration(double startLat, double startLng, double destLat, double destLng) async {
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
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: [
          IconButton(
            onPressed: () {
              // الانتقال إلى شاشة الخريطة عند النقر على الزر
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapScreen(
                    id: int.parse(orderDetails['id']),
                    latitude: double.parse(orderDetails['x_latitude']),
                    longitude: double.parse(orderDetails['y_longitude']),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رقم الطلب: ${widget.orderId}', // عرض الـ orderId هنا
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoCard('اسم المغسلة:', orderDetails['name']),
                  _buildInfoCard('العنوان:', orderDetails['address']),
                  _buildInfoCard('الهاتف:', orderDetails['phone']),
                  const SizedBox(height: 20),
                  isDistanceLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          distanceText ?? 'المسافة غير متوفرة',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                  const SizedBox(height: 20),
                  totalDeliveryCost != null
                      ? Text(
                          'سعر التوصيل: ${totalDeliveryCost!.toStringAsFixed(2)} ريال',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      : const SizedBox.shrink(),
                  const SizedBox(height: 20),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.payment, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'طرق الدفع',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddCardDetailsScreen(name_windows: "secandre"),
                                settings: RouteSettings(
                                  arguments:[ double.tryParse(totalDeliveryCost!.toStringAsFixed(2)), int.parse(orderDetails['id']),widget.orderId]  // تمرير المبلغ الإجمالي
                                  
                                ),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(bottom: 10, top: 10, left: 10, right: 10),
                            child: Text(
                              'اختر',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                backgroundColor: Color.fromRGBO(251, 255, 1, 1),
                                color: Color.fromRGBO(10, 10, 10, 1),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                     const SizedBox(height: 8),
                    Text(
                      defaultPaymentMethod ?? 'جاري تحميل طريقة الدفع...',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      print("طريقة الدفع المختارة: $selectedPaymentMethod");
                    },
                    child: const Text('تأكيد الطلب'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
