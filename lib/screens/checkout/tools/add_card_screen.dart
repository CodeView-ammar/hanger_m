import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/screens/checkout/transaction.dart';
import 'package:melaq/screens/checkout/views/review_order.dart';
import 'package:melaq/screens/discover/views/courier_order_details.dart';

class AddCardScreen extends StatefulWidget {
  final double total; // المبلغ الذي تم تمريره
  final int laundryId; // ID المغسلة
  final String? name_windows;

  AddCardScreen({
    super.key, 
    required this.total, 
    required this.laundryId,
    required this.name_windows,
  });

  @override
  _AddCardScreenState createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  bool isLoading = false;
  bool isProcessingPayment = false;
  String? errorMessage;
  String? paymentUrl;
  
  // Telr Configuration - يحتاج المستخدم لتوفير هذه البيانات
  static const String telrStoreId = 'YOUR_TELR_STORE_ID'; 
  static const String telrAuthKey = 'YOUR_TELR_AUTH_KEY';
  static const String telrBaseUrl = 'https://secure.telr.com/gateway/order.json';
  
  @override
  void initState() {
    super.initState();
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
        if (mounted) Navigator.pop(context);
      } else {
        print('حدث خطأ: ${response.body}');
        _showErrorMessage('حدث خطأ في إضافة طريقة الدفع');
      }
    } catch (e) {
      print('فشل الاتصال بالخادم: $e');
      _showErrorMessage('فشل الاتصال بالخادم');
    }
  }

  Future<void> createTelrPayment() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid') ?? 'guest';
      
      // إنشاء معرف فريد للطلب
      final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
      
      // بيانات الدفع لـ Telr
      final paymentData = {
        'method': 'create',
        'store': telrStoreId,
        'authkey': telrAuthKey,
        'order': {
          'cartid': orderId,
          'test': 1, // 1 للاختبار، 0 للإنتاج
          'amount': widget.total.toStringAsFixed(2),
          'currency': 'SAR',
          'description': 'دفع فاتورة خدمات المغسلة',
        },
        'customer': {
          'email': 'customer@example.com', // يمكن الحصول عليه من بيانات المستخدم
          'phone': {
            'country': '966',
            'number': '500000000', // يمكن الحصول عليه من بيانات المستخدم
          },
        },
        'return': {
          'authorised': 'https://yourapp.com/payment/success',
          'declined': 'https://yourapp.com/payment/failed',
          'cancelled': 'https://yourapp.com/payment/cancelled',
        },
      };

      final response = await http.post(
        Uri.parse(telrBaseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(paymentData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['order'] != null && responseData['order']['url'] != null) {
          setState(() {
            paymentUrl = responseData['order']['url'];
            isLoading = false;
          });
          
          // فتح صفحة الدفع
          _openPaymentPage(responseData['order']['url'], responseData['order']['ref']);
        } else {
          throw Exception('رابط الدفع غير متوفر');
        }
      } else {
        throw Exception('فشل في إنشاء عملية الدفع: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'خطأ في إنشاء الدفع: ${e.toString()}';
      });
      
      // في حالة كانت المفاتيح غير صحيحة، اطلب من المستخدم التحقق
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        _showTelrConfigDialog();
      }
    }
  }

  void _openPaymentPage(String url, String orderRef) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelrPaymentWebView(
          paymentUrl: url,
          orderRef: orderRef,
          onPaymentComplete: _handlePaymentResult,
        ),
      ),
    );
  }

  void _handlePaymentResult(String status, String? orderRef) {
    setState(() {
      isProcessingPayment = false;
    });

    switch (status.toLowerCase()) {
      case 'success':
      case 'authorised':
        _processSuccessfulPayment();
        break;
      case 'failed':
      case 'declined':
        _showErrorMessage('فشل في عملية الدفع');
        break;
      case 'cancelled':
        _showErrorMessage('تم إلغاء عملية الدفع');
        break;
      default:
        _showErrorMessage('حالة دفع غير معروفة');
    }
  }

  void _processSuccessfulPayment() {
    // إضافة المعاملة
    addTransaction(
      "debit",
      "deposit",
      widget.total,
      "تم ايداع المبلغ مقابل فاتورة ",
      context
    );
    
    // إضافة طريقة الدفع
    addPaymentMethod('Telr', 'الدفع عبر Telr', context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم الدفع بنجاح"),
        backgroundColor: Colors.green,
      ),
    );

    // الانتقال للشاشة المناسبة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.name_windows == "main") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewOrderScreen(
              laundryId: widget.laundryId,
              total: widget.total,
              isPaid: true,
              distance: 0,
              duration: '',
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CourierOrderDetailsScreen(
              orderId: widget.laundryId,
              isPaid: true,
            ),
          ),
        );
      }
    });
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showTelrConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعداد Telr مطلوب'),
        content: const Text(
          'يرجى التحقق من بيانات Telr الخاصة بك:\n'
          '• Store ID\n'
          '• Auth Key\n\n'
          'تواصل مع المطور لتوفير هذه البيانات.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("الدفع عبر Telr"),
        backgroundColor: const Color(0xFF2563EB), // لون Telr الأزرق
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة تفاصيل الدفع
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // شعار Telr
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.credit_card,
                      size: 48,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'الدفع الآمن عبر Telr',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'منصة دفع آمنة ومعتمدة',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // تفاصيل المبلغ
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'إجمالي المبلغ:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${widget.total.toStringAsFixed(2)} ر.س',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // رسالة خطأ إن وجدت
            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            
            // زر الدفع
            ElevatedButton(
              onPressed: isLoading ? null : createTelrPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('جاري إعداد الدفع...'),
                      ],
                    )
                  : const Text(
                      'الدفع الآن',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            
            const SizedBox(height: 16),
            
            // معلومات الأمان
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.green.shade600),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'جميع المعاملات محمية بتشفير SSL 256-bit',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
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

// شاشة WebView للدفع
class TelrPaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final String orderRef;
  final Function(String status, String? orderRef) onPaymentComplete;

  const TelrPaymentWebView({
    super.key,
    required this.paymentUrl,
    required this.orderRef,
    required this.onPaymentComplete,
  });

  @override
  State<TelrPaymentWebView> createState() => _TelrPaymentWebViewState();
}

class _TelrPaymentWebViewState extends State<TelrPaymentWebView> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => isLoading = false);
            _checkPaymentResult(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            _checkPaymentResult(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentResult(String url) {
    // فحص رابط النتيجة لتحديد حالة الدفع
    if (url.contains('/payment/success') || url.contains('authorised')) {
      Navigator.pop(context);
      widget.onPaymentComplete('success', widget.orderRef);
    } else if (url.contains('/payment/failed') || url.contains('declined')) {
      Navigator.pop(context);
      widget.onPaymentComplete('failed', widget.orderRef);
    } else if (url.contains('/payment/cancelled') || url.contains('cancelled')) {
      Navigator.pop(context);
      widget.onPaymentComplete('cancelled', widget.orderRef);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدفع الآمن'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ),
        ],
      ),
    );
  }
}