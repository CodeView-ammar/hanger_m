import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../services/secure_storage_service.dart';
import '../models/payment_models.dart';
import '../config/environment.dart';

/// تحكم في عمليات الدفع وإدارة الحالة
class PaymentController extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  
  bool _isLoading = false;
  String? _errorMessage;
  PaymentResponse? _lastPaymentResponse;
  PaymentStatus? _lastPaymentStatus;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PaymentResponse? get lastPaymentResponse => _lastPaymentResponse;
  PaymentStatus? get lastPaymentStatus => _lastPaymentStatus;
  bool get hasError => _errorMessage != null;

  /// بدء عملية الدفع
  Future<PaymentResponse> initiatePayment({
    required String type_payment,
    required double amount,
    required String currency,
    required String merchantOrderId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // التحقق من المتغيرات البيئية
      if (!Environment.validateRequiredKeys()) {
        throw PaymentException('إعدادات الدفع غير مكتملة، يرجى التواصل مع الدعم الفني');
      }

      // التحقق من بيانات المستخدم
      // if (!await SecureStorageService.hasUserData()) {
      //   throw PaymentException('يرجى تسجيل الدخول أولاً لإتمام عملية الدفع');
      // }

      _lastPaymentResponse = await _paymentService.processPayment(
        amount: amount,
        type_payment: type_payment,
        currency: currency,
        merchantOrderId: merchantOrderId,
      );

      if (!_lastPaymentResponse!.success) {
        _setError(_lastPaymentResponse!.errorMessage ?? 'فشل في إنشاء عملية الدفع');
      }

      return _lastPaymentResponse!;

    } catch (e) {
      final errorMessage = e is PaymentException ? e.message : 'حدث خطأ غير متوقع';
      _setError(errorMessage);
      return PaymentResponse.error(errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  /// التحقق من حالة الدفع
  Future<PaymentStatus> checkPaymentStatus(int orderId) async {
    _setLoading(true);
    _clearError();

    try {
      _lastPaymentStatus = await _paymentService.checkPaymentStatus(orderId);
      return _lastPaymentStatus!;

    } catch (e) {
      final errorMessage = e is PaymentException ? e.message : 'فشل في التحقق من حالة الدفع';
      _setError(errorMessage);
      return PaymentStatus(
        isSuccessful: false,
        isPending: false,
        hasError: true,
        errorMessage: errorMessage,
        checkedAt: DateTime.now(),
      );
    } finally {
      _setLoading(false);
    }
  }

  /// الحصول على رابط الدفع
  String getPaymentUrl(String paymentToken) {
    return "${Environment.apiBaseUrl}/acceptance/iframes/${Environment.paymobIframeId}?payment_token=$paymentToken";
  }

  /// حفظ بيانات المستخدم للدفع
  Future<void> saveUserDataForPayment({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    String? address,
  }) async {
    try {
      await SecureStorageService.saveUserData(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        address: address,
      );
    } catch (e) {
      _setError('فشل في حفظ بيانات المستخدم');
    }
  }

  /// مسح بيانات الدفع
  void clearPaymentData() {
    _lastPaymentResponse = null;
    _lastPaymentStatus = null;
    _clearError();
    notifyListeners();
  }

  /// إعداد حالة التحميل
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// إعداد رسالة الخطأ
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// مسح رسالة الخطأ
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }
}
