/// ثوابت نظام الدفع
class PaymentConstants {
  // العملات المدعومة
  static const List<String> supportedCurrencies = ['SAR', 'USD', 'EUR', 'EGP'];
  
  // حدود المبالغ
  static const double minAmount = 1.0;
  static const double maxAmount = 999999.99;
  
  // URLs
  static const String paymobBaseUrl = 'https://ksa.paymob.com/api';
  
  // معرفات الدفع
  static const Map<String, String> paymentIcons = {
    'COD': 'assets/icons/cash_on_delivery.png',
    'CARD': 'assets/icons/credit_card.png',
    'STC_PAY': 'assets/icons/stc_pay.png',
    'APPLE_PAY': 'assets/icons/apple_pay.png',
  };
  
  // رسائل الخطأ الشائعة
  static const Map<String, String> errorMessages = {
    'network_error': 'خطأ في الشبكة، يرجى المحاولة مرة أخرى',
    'invalid_amount': 'المبلغ المدخل غير صحيح',
    'payment_failed': 'فشل في عملية الدفع',
    'user_cancelled': 'تم إلغاء عملية الدفع',
    'timeout': 'انتهت مهلة العملية',
    'invalid_data': 'البيانات المدخلة غير صحيحة',
  };
  
  // رسائل النجاح
  static const Map<String, String> successMessages = {
    'payment_success': 'تم الدفع بنجاح',
    'order_created': 'تم إنشاء الطلب بنجاح',
  };
  
  // إعدادات المؤقت
  static const Duration paymentTimeout = Duration(minutes: 10);
  static const Duration statusCheckInterval = Duration(seconds: 3);
  static const int maxStatusChecks = 20;
}
