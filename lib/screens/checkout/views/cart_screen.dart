import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:http/http.dart' as http;
import 'package:melaq/constants.dart';
import 'package:melaq/l10n/app_localizations.dart';
import 'package:melaq/screens/checkout/views/review_order.dart';
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double totalPrice = 0.0;
  List<Map<String, dynamic>> cartItems = [];


// دالة إزالة عنصر من السلة عبر الـ API
Future<void> removeItemFromCart(int laundryId, int serviceId) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userid');

  if (userId != null) {
    // إرسال طلب DELETE إلى الـ API
    final response = await http.delete(
      Uri.parse('${APIConfig.cartRemoveEndpoint}?user=$userId&laundry=$laundryId&service=$serviceId'),
    );
    // print(response);
    if (response.statusCode == 200) {
      print('تم إزالة العنصر من السلة بنجاح');
      // تحديث واجهة المستخدم بعد إزالة العنصر
      setState(() {
        cartItems.removeWhere((item) => item['laundry'] == laundryId && item['service'] == serviceId);
        totalPrice = cartItems.fold(0.0, (sum, item) => sum + double.parse(item['price']) * item['quantity']);
      });
    } else {
      String errorMessage = 'حدث خطأ أثناء إزالة العنصر';
      if (response.statusCode == 404) {
        errorMessage = 'لم يتم العثور على العنصر';
      } else if (response.statusCode == 400) {
        errorMessage = 'البيانات المدخلة غير صحيحة';
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('خطأ'),
            content: Text(errorMessage),
            actions: <Widget>[
              TextButton(
                child: Text(AppLocalizations.of(context)!.oK),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      );
    }
  } else {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('خطأ'),
          content: const Text('لم يتم العثور على معرف المستخدم. يرجى تسجيل الدخول أولاً.'),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.oK),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}


Future<void> updateCartQuantity(int laundryId, int serviceId, int newQuantity) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userid');

  if (userId != null) {

    // Use PATCH or PUT for updating
    final response = await http.get(
      Uri.parse('${APIConfig.cartupdateEndpoint}?user=$userId&laundry=$laundryId&service=$serviceId&quantity=$newQuantity'),
    );

    if (response.statusCode == 200) {
      // In case of successful update (status 200)
      print('تم تحديث الكمية بنجاح');
      // Optionally refresh data here
    } else {
      // Handle other errors or failures
      String errorMessage = 'حدث خطأ أثناء التحديث';
      if (response.statusCode == 404) {
        errorMessage = 'لم يتم العثور على العنصر';
      } else if (response.statusCode == 400) {
        errorMessage = 'البيانات المدخلة غير صحيحة';
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title:  Text(AppLocalizations.of(context)!.error),
            content: Text(errorMessage),
            actions: <Widget>[
              TextButton(
                child:  Text(AppLocalizations.of(context)!.oK),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      );
    }
  } else {
    // Show error if userId is not found
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Text(AppLocalizations.of(context)!.error),
          content: const Text('لم يتم العثور على معرف المستخدم. يرجى تسجيل الدخول أولاً.'),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.oK),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}
Future<void> fetchCartData(int laundryId) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userid');

  if (userId != null) {
    final response = await http.get(
      Uri.parse('${APIConfig.cartfilterEndpoint}?user=$userId&laundry=$laundryId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // التحقق من أن الـ Widget ما زال في شجرة الـ Widget قبل استدعاء setState
      if (mounted) {
        setState(() {
          if (data['carts'] != null && data['carts'].isNotEmpty) {
            cartItems = List<Map<String, dynamic>>.from(data['carts']);
            totalPrice = data['carts']
                .fold(0.0, (sum, item) => sum + double.parse(item['price']) * item['quantity']);
          } else {
            cartItems = [];
            totalPrice = 0.0;
          }
        });
      }
    } else {
      throw Exception('فشل في جلب البيانات من الـ API');
    }
  } else {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.error),
          content: const Text('لم يتم العثور على معرف المستخدم. يرجى تسجيل الدخول أولاً.'),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.oK),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

  // دالة تحديث الكمية محليًا وفي الـ API
  void updateQuantity(int index, int delta) {
    setState(() {
      // تحديث الكمية في واجهة المستخدم
      cartItems[index]['quantity'] = (cartItems[index]['quantity'] + delta).clamp(1, 99);
      totalPrice = cartItems.fold(0.0, (sum, item) => sum + double.parse(item['price']) * item['quantity']);
    });

    // إرسال التحديث إلى الـ API
    final laundryId = cartItems[index]['laundry']; // تأكد من الحصول على laundryId
    final serviceId = cartItems[index]['service']; 
    updateCartQuantity(laundryId, serviceId, cartItems[index]['quantity']);
  }

// دالة إزالة عنصر من السلة
void removeItem(int index) {
  final laundryId = cartItems[index]['laundry']; // الحصول على laundryId
  final serviceId = cartItems[index]['service']; // الحصول على serviceId
// print(laundryId);
// print(serviceId);
  removeItemFromCart(laundryId, serviceId); // إزالة العنصر عبر API

  setState(() {
    cartItems.removeAt(index); // إزالة العنصر من الواجهة
    totalPrice = cartItems.fold(0.0, (sum, item) => sum + double.parse(item['price']) * item['quantity']);
  });
}
double distance = 0.0; // متغير للمسافة
  String duration = ""; // متغير للمدة
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // استرداد المتغيرات من RouteSettings
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final int laundryId = args?['id'] ?? 0;
    distance = args?['distance'] ?? 0.0; // استرداد المسافة
    duration = args?['duration'] ?? ""; // استرداد المدة
    if (laundryId > 0) {
      fetchCartData(laundryId);
    }
  }

  // واجهة المستخدم الخاصة بالشاشة
  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(
      title: Text(AppLocalizations.of(context)!.shoppingcart),
      
    ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: cartItems.isEmpty
                  ? const Center(child: Text('لا توجد عناصر في السلة'))
                  : ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        
                        return Card(
                          color: secondaryColor ,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            textColor: Colors.white,
                            title: Text(utf8.decode(item['service_name'].codeUnits)),
                            subtitle: RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.titleMedium, // استخدام ستايل الـ subtitle الافتراضي
                                  children: [
                                    TextSpan(
                                      style: const TextStyle(color: Colors.white),
                                      text: "${AppLocalizations.of(context)!.price}: \ ", // النص قبل السعر
                                    ),
                                    WidgetSpan(
                                      child: Image.asset(
                                        'assets/icons/riyal.png', // ضع مسار الصورة الصحيح
                                        width: 16,
                                        height: 16,
                                        color: Colors.white,
                                      ),
                                      alignment: PlaceholderAlignment.middle, // لمحاذاة الصورة مع النص عمودياً
                                    ),
                                    TextSpan(
                                      style: const TextStyle(color: Colors.white),
                                      text: " ${item['price']} × ${item['quantity']}", // باقي النص بعد أيقونة العملة
                                    ),
                                  ],
                                ),
                              ),

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove , color: Colors.white,),
                                  onPressed: () => updateQuantity(index, -1),
                                ),
                                Text('${item['quantity']}'),
                                IconButton(
                                  icon: const Icon(Icons.add, color: Colors.white,),
                                  onPressed: () => updateQuantity(index, 1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () => removeItem(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16.0),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.titleLarge, // استخدام ستايل الـ titleLarge
                children: [
                  TextSpan(
                    text: "${AppLocalizations.of(context)!.total}: \ ", // النص قبل السعر
                  ),
                  WidgetSpan(
                    child: Image.asset(
                      'assets/icons/riyal.png', // ضع مسار الصورة الصحيح
                      width: 20,  // يمكن تعديل الحجم ليتناسب مع النص
                      height: 20,
                    ),
                    alignment: PlaceholderAlignment.middle, // لمحاذاة الصورة مع النص عمودياً
                  ),
                  TextSpan(
                    text: " ${totalPrice.toStringAsFixed(2)}", // السعر بعد أيقونة العملة
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),
            ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: () {
                    // احصل على الـ laundryId من العناصر في السلة
                    final int laundryId = cartItems.isNotEmpty ? cartItems[0]['laundry'] : 0;

                    // تأكد من أن laundryId ليس صفرًا
                    if (laundryId > 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewOrderScreen(laundryId: laundryId,total:totalPrice,isPaid: false,distance: distance,duration: duration),
                        ),
                      );
                    } else {
                      // معالجة الحالة عندما لا يوجد laundryId
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(AppLocalizations.of(context)!.error),
                            content:  Text(AppLocalizations.of(context)!.thereisnospecificsink),
                            backgroundColor: primaryColor,
                            actions: <Widget>[
                              TextButton(
                                child:  Text(AppLocalizations.of(context)!.oK),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.continuetocheckout),
                ),

          ],
        ),
      ),
    );
  }
}
