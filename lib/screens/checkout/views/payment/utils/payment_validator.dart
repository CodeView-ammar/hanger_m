/// فئة للتحقق من صحة بيانات الدفع
class PaymentValidator {
  /// التحقق من صحة المبلغ
  static bool isValidAmount(double? amount) {
    return amount != null && amount > 0 && amount <= 999999.99;
  }

  /// التحقق من صحة العملة
  static bool isValidCurrency(String? currency) {
    final validCurrencies = ['SAR', 'USD', 'EUR', 'EGP'];
    return currency != null && validCurrencies.contains(currency.toUpperCase());
  }

  /// التحقق من صحة البريد الإلكتروني
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// التحقق من صحة رقم الهاتف السعودي
  static bool isValidSaudiPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) return false;
    // التحقق من الأرقام السعودية
    return RegExp(r'^(\+966|966|0)?(5[0-9]{8})$').hasMatch(phoneNumber.replaceAll(' ', ''));
  }

  /// التحقق من صحة الاسم
  static bool isValidName(String? name) {
    if (name == null || name.isEmpty) return false;
    return name.trim().length >= 2 && name.trim().length <= 50;
  }

  /// التحقق من صحة معرف الطلب
  static bool isValidOrderId(String? orderId) {
    if (orderId == null || orderId.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9_-]{3,50}$').hasMatch(orderId);
  }

  /// التحقق من اكتمال بيانات العميل
  static ValidationResult validateCustomerData({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
  }) {
    final List<String> errors = [];

    if (!isValidName(firstName)) {
      errors.add('الاسم الأول غير صحيح');
    }

    if (!isValidName(lastName)) {
      errors.add('الاسم الأخير غير صحيح');
    }

    if (!isValidEmail(email)) {
      errors.add('البريد الإلكتروني غير صحيح');
    }

    if (!isValidSaudiPhoneNumber(phoneNumber)) {
      errors.add('رقم الهاتف غير صحيح');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// التحقق من اكتمال بيانات الدفع
  static ValidationResult validatePaymentData({
    required double amount,
    required String currency,
    required String orderId,
  }) {
    final List<String> errors = [];

    if (!isValidAmount(amount)) {
      errors.add('المبلغ غير صحيح');
    }

    if (!isValidCurrency(currency)) {
      errors.add('نوع العملة غير مدعوم');
    }

    if (!isValidOrderId(orderId)) {
      errors.add('معرف الطلب غير صحيح');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

/// نتيجة التحقق من البيانات
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });

  String get errorMessage => errors.join('\n');
}
