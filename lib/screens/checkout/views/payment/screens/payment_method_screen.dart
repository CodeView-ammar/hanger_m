import 'package:flutter/material.dart';
import 'package:pay_with_paymob/pay_with_paymob.dart';
import 'package:provider/provider.dart';
import '../controllers/payment_controller.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/error_dialog.dart';
import '../models/payment_models.dart';
import '../utils/payment_validator.dart';
import '../config/environment.dart';

/// شاشة اختيار طريقة الدفع المحسّنة
class PaymentMethodScreen extends StatefulWidget {
  final double totalAmount;
  final int laundryId;
  final Function(bool isPaid, String defaultPaymentMethod)? onPaymentComplete;
  final Function(String error)? onPaymentError;

  const PaymentMethodScreen({
    Key? key,
    required this.totalAmount,
    required this.laundryId,
    this.onPaymentComplete,
    this.onPaymentError,
  }) : super(key: key);

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  late PaymentController _paymentController;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _paymentController = PaymentController();
    _initializeEnvironment();
    PaymentData.initialize(
    apiKey: Environment.paymobPublicKey,
    iframeId: Environment.paymobIframeId,
    integrationCardId: Environment.paymobApplePayIntegrationId,
    integrationMobileWalletId: Environment.paymobApplePayIntegrationId,
  // **لا تنسَ دمج applePay داخل إعدادات الطريق**
);
  }

  Future<void> _initializeEnvironment() async {
    await Environment.initialize();
    if (!Environment.validateRequiredKeys()) {
      if (mounted) {
        ErrorDialog.show(
          context,
          title: 'خطأ في الإعدادات',
          message: 'إعدادات الدفع غير مكتملة، يرجى التواصل مع الدعم الفني',
        );
      }
    }
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _paymentController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("اختر طريقة الدفع"),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: Consumer<PaymentController>(
          builder: (context, controller, child) {
            return LoadingOverlay(
              isLoading: controller.isLoading || _isProcessingPayment,
              message: _isProcessingPayment 
                  ? 'جاري معالجة عملية الدفع...' 
                  : 'جاري تحضير عملية الدفع...',
              child: _buildBody(controller),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(PaymentController controller) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaymentSummary(),
          const SizedBox(height: 8),
          _buildSectionTitle(),
          Expanded(
            child: _buildPaymentOptions(controller),
          ),
          _buildSecurityInfo(),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
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
          const Text(
            'ملخص الدفع',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
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
                const Text(
                  'المبلغ الإجمالي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${widget.totalAmount.toStringAsFixed(2)} ر.س',
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
    );
  }

  Widget _buildSectionTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        "اختر طريقة الدفع المناسبة",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildPaymentOptions(PaymentController controller) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildPaymentOption(
          method: PaymentMethod.cod,
          subtitle: 'ادفع عند استلام الطلب',
          icon: Icons.money_off,
          onTap: () => _handleCashOnDelivery(),
        ),
        _buildPaymentOption(
          method: PaymentMethod.card,
          subtitle: 'ادفع باستخدام البطاقة الائتمانية',
          icon: Icons.credit_card,
          onTap: () => _handleCardPayment(controller),
        ),
        _buildPaymentOption(
          method: PaymentMethod.applePay,
          subtitle: 'ادفع باستخدام Apple Pay',
          icon: Icons.apple,
          onTap: () => _handleApplePayPayment(controller), // غير متاح حاليًا
          isDisabled: false,
        ),
        _buildPaymentOption(
          method: PaymentMethod.stcPay,
          subtitle: 'ادفع باستخدام STC Pay',
          icon: Icons.payment,
          onTap: () => _handleSTCPayment(),
          isDisabled: true,
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required PaymentMethod method,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        color: isDisabled ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: isDisabled ? 0 : 2,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDisabled 
                        ? Colors.grey.shade100 
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isDisabled 
                        ? Colors.grey.shade400 
                        : Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.arabicName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDisabled 
                              ? Colors.grey.shade500 
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDisabled 
                              ? Colors.grey.shade400 
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDisabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'قريباً',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
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
            color: Colors.green.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "جميع المعاملات مؤمنة ومشفرة وفقاً لمعايير الأمان العالمية",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCashOnDelivery() async {
    final confirmed = await _showConfirmDialog(
      title: 'تأكيد الدفع عند الاستلام',
      message: 'سيتم تأكيد طلبك وسيقوم مندوب التوصيل بتحصيل المبلغ عند الاستلام',
      confirmText: 'تأكيد الطلب',
      confirmColor: Colors.green,
    );

    if (confirmed) {
      setState(() {
        _isProcessingPayment = true;
      });

      // Simulate processing time
      await Future.delayed(const Duration(seconds: 1));

      widget.onPaymentComplete?.call(false, 'COD');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تأكيد طريقة الدفع بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _handleSTCPayment() async {
    final confirmed = await _showConfirmDialog(
      title: 'تأكيد الدفع باستخدام STC',
      message: 'سيتم توجيهك لتطبيق STC Pay لإتمام عملية الدفع',
      confirmText: 'متابعة',
      confirmColor: Colors.purple,
    );

    if (confirmed) {
      setState(() {
        _isProcessingPayment = true;
      });

      try {
        // Simulate STC payment processing
        await Future.delayed(const Duration(seconds: 2));
        
        // For now, we'll treat STC as successful
        // In real implementation, you would integrate with STC Pay SDK
        widget.onPaymentComplete?.call(true, 'STC');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم الدفع بنجاح باستخدام STC Pay'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        widget.onPaymentError?.call('فشل في الدفع باستخدام STC Pay: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() {
            _isProcessingPayment = false;
          });
        }
      }
    }
  }

  Future<void> _handleCardPayment(PaymentController controller) async {
    // التحقق من صحة البيانات
    final validation = PaymentValidator.validatePaymentData(
      amount: widget.totalAmount,
      currency: 'SAR',
      orderId: 'ORDER_${widget.laundryId}_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!validation.isValid) {
      ErrorDialog.show(
        context,
        title: 'بيانات غير صحيحة',
        message: validation.errorMessage,
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // بدء عملية الدفع
      final response = await controller.initiatePayment(
        amount: widget.totalAmount,
        currency: 'SAR',
        type_payment: Environment.paymobCardIntegrationId,
        merchantOrderId: 'ORDER_${widget.laundryId}_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (response.success && response.paymentToken != null) {
        await _showPaymentDialog(controller, response);
      } else {
        widget.onPaymentError?.call(response.errorMessage ?? 'حدث خطأ غير متوقع');
      }
    } catch (e) {
      widget.onPaymentError?.call('خطأ في الدفع: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }
  
  Future<void> _handleApplePayPayment(PaymentController controller) async {
    // التحقق من صحة البيانات
    final validation = PaymentValidator.validatePaymentData(
      amount: widget.totalAmount,
      currency: 'SAR',
      orderId: 'ORDER_${widget.laundryId}_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!validation.isValid) {
      ErrorDialog.show(
        context,
        title: 'بيانات غير صحيحة',
        message: validation.errorMessage,
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // بدء عملية الدفع
      final response = await controller.initiatePayment(
        amount: widget.totalAmount,
        currency: 'SAR',
        type_payment: Environment.paymobApplePayIntegrationId,
        merchantOrderId: 'ORDER_${widget.laundryId}_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (response.success && response.paymentToken != null) {
        await _showPaymentDialog(controller, response);
      } else {
        widget.onPaymentError?.call(response.errorMessage ?? 'حدث خطأ غير متوقع');
      }
    } catch (e) {
      widget.onPaymentError?.call('خطأ في الدفع: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  Future<void> _showPaymentDialog(
    PaymentController controller, 
    PaymentResponse response,
  ) async {
    final paymentUrl = controller.getPaymentUrl(response.paymentToken!);
    
    final paymentResult = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        paymentUrl: paymentUrl,
        onPaymentComplete: (success) {
          // Navigator.of(context).pop(success);
        },
        onCancel: () {
          Navigator.of(context).pop(false);
        },
      ),
    );

    if (paymentResult != null) {
      if (paymentResult) {
        widget.onPaymentComplete?.call(true, 'CARD');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم الدفع بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        widget.onPaymentError?.call('تم إلغاء عملية الدفع');
      }
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
              ),
              child: Text(
                confirmText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }
}
