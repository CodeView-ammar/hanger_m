import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/screens/checkout/views/payment/screens/payment_method_screen.dart';

class AddCardDetailsScreen extends StatefulWidget {
  final String name_windows;
  final double? totalAmount;
  final String? laundryId;

  const AddCardDetailsScreen({Key? key, required this.name_windows, this.totalAmount, this.laundryId}) : super(key: key);

  @override
  _AddCardDetailsScreenState createState() => _AddCardDetailsScreenState();
}

class _AddCardDetailsScreenState extends State<AddCardDetailsScreen> {
  double totalAmount = 0.0;
  int laundryId = 0;
  int? orderId;
  bool _isProcessingPayment = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get data from widget properties first
    if (widget.totalAmount != null) {
      totalAmount = widget.totalAmount!;
    }
    if (widget.laundryId != null) {
      laundryId = int.tryParse(widget.laundryId!) ?? 0;
      orderId = laundryId;
    }

    // Then check for route arguments (fallback)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is List && args.length >= 2) {
      final parsedAmount = args[0];
      final parsedLaundryId = args[1];

      if (parsedAmount is double && totalAmount == 0.0) {
        totalAmount = parsedAmount;
      } else if (parsedAmount is num && totalAmount == 0.0) {
        totalAmount = parsedAmount.toDouble();
      }

      if (parsedLaundryId is int && laundryId == 0) {
        laundryId = parsedLaundryId;
        orderId = parsedLaundryId;
      }
    }
  }

  Future<void> _registerPaymentMethod(String name, String description) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');
    final url = Uri.parse(APIConfig.addPaymentUrl);

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ تم تسجيل طريقة الدفع: $name");
      } else {
        print("❌ فشل تسجيل طريقة الدفع: ${response.body}");
      }
    } catch (e) {
      print("⚠️ استثناء أثناء تسجيل طريقة الدفع: $e");
    }
  }

  void _handlePaymentComplete(bool isPaid, String defaultPaymentMethod) {
    print("Payment completed: isPaid=$isPaid, method=$defaultPaymentMethod");
    
    setState(() {
      _isProcessingPayment = true;
    });

    // Register payment method
    _registerPaymentMethod(
      defaultPaymentMethod,
      'Payment method for ${widget.name_windows}',
    ).then((_) {
      // Return result to calling screen
      if (mounted) {
        Navigator.pop(context, {
          'isPaid': isPaid,
          'defaultPaymentMethod': defaultPaymentMethod,
        });
      }
    }).catchError((error) {
      print("Error registering payment method: $error");
      // Still return the result even if registration fails
      if (mounted) {
        Navigator.pop(context, {
          'isPaid': isPaid,
          'defaultPaymentMethod': defaultPaymentMethod,
        });
      }
    }).whenComplete(() {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    });
  }

  void _handlePaymentError(String error) {
    print("Payment failed: $error");
    
    // Show error dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('فشل في الدفع'),
          content: Text('حدث خطأ أثناء عملية الدفع: $error'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('إعادة المحاولة'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessingPayment) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('معالجة الدفع'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'جاري معالجة عملية الدفع...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return PaymentMethodScreen(
      laundryId: laundryId,
      totalAmount:  widget.totalAmount ?? 0.0, // Minimum amount
      onPaymentComplete: _handlePaymentComplete,
      onPaymentError: _handlePaymentError,
    );
  }
}
