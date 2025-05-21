import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/l10n/app_localizations.dart';
import 'package:shop/screens/checkout/tools/add_card_screen.dart';
import 'package:shop/screens/checkout/views/review_order.dart';

class AddCardDetailsScreen extends StatefulWidget {
  final String name_windows;
  const AddCardDetailsScreen({Key? key, required this.name_windows}) : super(key: key);

  @override
  _AddCardDetailsScreenState createState() => _AddCardDetailsScreenState();
}

class _AddCardDetailsScreenState extends State<AddCardDetailsScreen> {
  double? totalAmount;
  int laundryId =0; 
  int? orderId;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // استلام المبلغ الإجمالي من الـ arguments
    final args = ModalRoute.of(context)?.settings.arguments as List<dynamic>?;
    if (args != null && args.length >= 2) {
      totalAmount = args[0] as double; // استلام المبلغ
      laundryId= args[1] as int; // استلام ID المغسلة
      orderId= args[1] as int; // استلام ID المغسلة
      
    }
  }
   Future<void> addPaymentMethod(String name, String description, BuildContext context) async {
    final url = Uri.parse(APIConfig.addPaymentUrl);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'description': description,
          'is_active': true,
          'user': userId,
          'default': true,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('تم إضافة طريقة الدفع بنجاح');
        print(name);
        if(name=="COD"){
               Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewOrderScreen(
                laundryId: laundryId,  
                total: totalAmount ?? 0.0,  
                isPaid: false,
                distance: 0,
                duration: '',
              ),
            ),
          );
        }
      } else {
        print('حدث خطأ: ${response.body}');
      }
    } catch (e) {
      print('فشل الاتصال بالخادم: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("اختر طريقة الدفع"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات الدفع في الأعلى
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.paymentmethods,
                    style: const TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (totalAmount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.total,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${totalAmount!.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // عنوان خيارات الدفع
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "اختر طريقة الدفع المناسبة",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ),
            
            // خيارات الدفع
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  PaymentOption(
                    title: AppLocalizations.of(context)!.poloic,
                    subtitle: AppLocalizations.of(context)!.piaopettaotrrto,
                    logo: 'assets/icons/money_hand.jpg',
                    total: totalAmount ?? 0.0,
                    onTap: () {
                      addPaymentMethod('COD', 'الدفع عند الاستلام', context);
                    },
                  ),
                  PaymentOption(
                    title: 'stc pay',
                    subtitle: AppLocalizations.of(context)!.ptaspumn,
                    logo: 'assets/icons/stc_pay.png',
                    onTap: null,
                    isReadOnly: true,
                    total: totalAmount ?? 0.0,
                  ),
                  PaymentOption(
                    title: AppLocalizations.of(context)!.aanc,
                    subtitle: AppLocalizations.of(context)!.yhnac,
                    logo: 'assets/icons/credit_card.png',
                    total: totalAmount ?? 0.0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddCardScreen(
                            name_windows: widget.name_windows,
                            total: totalAmount ?? 0.0,
                            laundryId: laundryId,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // قسم معلومات الأمان
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "جميع المعاملات مؤمنة ومشفرة",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String logo;
  final VoidCallback? onTap;
  final bool isReadOnly;
  final double total;
  
  const PaymentOption({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.logo,
    this.onTap,
    this.isReadOnly = false,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isReadOnly ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isReadOnly ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isReadOnly ? Colors.grey[300]! : Colors.grey[200]!,
            width: 1.0,
          ),
          boxShadow: isReadOnly ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Image.asset(
                logo,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isReadOnly ? Colors.grey[500] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // إظهار زر مناسب حسب حالة الدفع
            isReadOnly 
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        "قريباً",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ),
          ],
        ),
      ),
    );
  }
}