import 'package:dio/dio.dart';
import '../config/environment.dart';
import '../models/payment_models.dart';
import '../utils/crypto_helper.dart';
import 'secure_storage_service.dart';

/// خدمة الدفع المحسّنة والآمنة
class PaymentService {
  late final Dio _dio;
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  PaymentService() {
    _dio = Dio(BaseOptions(
      baseUrl: Environment.apiBaseUrl,
      connectTimeout: Duration(milliseconds: Environment.apiTimeout),
      receiveTimeout: Duration(milliseconds: Environment.apiTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // إضافة interceptor للمراقبة والتسجيل
    _dio.interceptors.add(LogInterceptor(
      requestBody: false, // عدم تسجيل body للأمان
      responseBody: false,
      logPrint: (log) => print('PaymentService: $log'),
    ));
  }

  /// الحصول على رمز المصادقة مع إعادة المحاولة
  Future<String> getAuthenticationToken() async {
    return _executeWithRetry<String>(() async {
      final response = await _dio.post(
        "/auth/tokens",
        data: {"api_key": Environment.paymobApiKey},
      );

      if (response.data == null || response.data["token"] == null) {
        throw PaymentException('فشل في الحصول على رمز المصادقة');
      }

      return response.data["token"] as String;
    });
  }

  /// إنشاء طلب دفع جديد
  Future<int> createOrder({
    required String authToken,
    required PaymentRequest paymentRequest,
  }) async {
    return _executeWithRetry<int>(() async {
      final response = await _dio.post(
        "/ecommerce/orders",
        data: {
          "auth_token": authToken,
          "amount_cents": paymentRequest.toJson()['amount_cents'],
          "currency": paymentRequest.currency,
          "delivery_needed": "false",
          "items": [],
          "merchant_order_id": paymentRequest.orderId,
        },
      );

      if (response.data == null || response.data["id"] == null) {
        throw PaymentException('فشل في إنشاء طلب الدفع');
      }

      return response.data["id"] as int;
    });
  }

  /// الحصول على مفتاح الدفع
  Future<String> getPaymentKey({
    required String type_payment,
    required String authToken,
    required int orderId,
    required PaymentRequest paymentRequest,
  }) async {
    
    print("type_payment: $type_payment");
    
    
    return _executeWithRetry<String>(() async {
      final response = await _dio.post(
        "/acceptance/payment_keys",
      data: {
        "expiration": 3600,
        "auth_token": authToken,
        "order_id": orderId.toString(),
        "integration_id": type_payment,
        "amount_cents":  paymentRequest.toJson()['amount_cents'],
        "currency": paymentRequest.currency,
        "billing_data": {
          "first_name": "Clifford",
          "last_name": "Nicolas",
          "email": "claudette09@exa.com",
          "phone_number": "+86(8)9135210487",
          "apartment": "NA",
          "floor": "NA",
          "street": "NA",
          "building": "NA",
          "shipping_method": "NA",
          "postal_code": "NA",
          "city": "NA",
          "country": "NA",
          "state": "NA"
        },
      },

      );

      if (response.data == null || response.data["token"] == null) {
        throw PaymentException('فشل في الحصول على مفتاح الدفع');
      }

      return response.data["token"] as String;
    });
  }

  /// التحقق من حالة الدفع
  Future<PaymentStatus> checkPaymentStatus(int orderId) async {
    return _executeWithRetry<PaymentStatus>(() async {
      final authToken = await getAuthenticationToken();
      
      final response = await _dio.post(
        "/ecommerce/orders/transaction_inquiry",
        data: {
          "auth_token": authToken,
          "order_id": orderId,
        },
      );

      if (response.data == null) {
        throw PaymentException('فشل في التحقق من حالة الدفع');
      }

      return PaymentStatus.fromApiResponse(response.data);
    });
  }

  /// معالجة الدفع الكاملة
  Future<PaymentResponse> processPayment({
    required String type_payment,
    required double amount,
    required String currency,
    required String merchantOrderId,
  }) async {
    try {
      // الحصول على بيانات المستخدم
      // final userData = await SecureStorageService.getUserData();
      // if (userData == null) {
      //   throw PaymentException('بيانات المستخدم غير متوفرة، يرجى تسجيل الدخول مرة أخرى');
      // }

      final customerData = "ammar";
      final paymentRequest = PaymentRequest(
        amount: amount,
        type_payment: type_payment,
        currency: currency,
        orderId: merchantOrderId,
        customerData: customerData,
      );

      // 1. الحصول على رمز المصادقة
      final authToken = await getAuthenticationToken();

      // 2. إنشاء طلب الدفع
      final orderId = await createOrder(
        authToken: authToken,
        paymentRequest: paymentRequest,
      );

      // 3. الحصول على مفتاح الدفع
      final paymentKey = await getPaymentKey(
        type_payment: type_payment,
        authToken: authToken,
        orderId: orderId,
        paymentRequest: paymentRequest,
      );

      return PaymentResponse.success(
        paymentToken: paymentKey,
        orderId: orderId.toString(),
      );

    } catch (e) {
      final errorMessage = e is PaymentException ? e.message : 'حدث خطأ غير متوقع في عملية الدفع';
      return PaymentResponse.error(errorMessage);
    }
  }

  /// تنفيذ العملية مع إعادة المحاولة
  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (attempt == maxRetries) {
          break;
        }

        // تأخير قبل إعادة المحاولة
        await Future.delayed(retryDelay * attempt);
        print('إعادة المحاولة $attempt من $maxRetries...');
      }
    }

    // رفع الاستثناء الأخير بعد فشل جميع المحاولات
    if (lastException is DioException) {
      throw PaymentException(
        _getDioErrorMessage(lastException),
        originalError: lastException,
      );
    } else {
      throw PaymentException(
        lastException?.toString() ?? 'خطأ غير معروف',
        originalError: lastException,
      );
    }
  }

  /// تحويل أخطاء Dio إلى رسائل مفهومة
  String _getDioErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'انتهت مهلة الاتصال، يرجى التحقق من الإنترنت والمحاولة مرة أخرى';
      case DioExceptionType.sendTimeout:
        return 'انتهت مهلة إرسال البيانات، يرجى المحاولة مرة أخرى';
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة استقبال البيانات من الخادم';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return 'خطأ في المصادقة، يرجى التحقق من بيانات الدفع';
        } else if (statusCode == 400) {
          return 'بيانات الدفع غير صحيحة';
        } else if (statusCode != null && statusCode >= 500) {
          return 'خطأ في الخادم، يرجى المحاولة لاحقاً';
        }
        return 'حدث خطأ في الخادم (رمز الخطأ: $statusCode)';
      case DioExceptionType.cancel:
        return 'تم إلغاء العملية';
      case DioExceptionType.connectionError:
        return 'لا يمكن الاتصال بالخادم، يرجى التحقق من الإنترنت';
      default:
        return 'حدث خطأ في الشبكة، يرجى المحاولة مرة أخرى';
    }
  }

  /// تنظيف الموارد
  void dispose() {
    _dio.close();
  }
}
