/// نماذج البيانات الخاصة بنظام الدفع
class PaymentRequest {
  final String type_payment;
  
  final double amount;
  final String currency;
  final String orderId;
  final String customerData;

  PaymentRequest({
    required this.type_payment,
    required this.amount,
    required this.currency,
    required this.orderId,
    required this.customerData,
  });

  Map<String, dynamic> toJson() => {
    'amount_cents': (amount * 100).toInt().toString(),
    'currency': currency,
    'order_id': orderId,
    'customer_data': customerData,
  };
}

class CustomerData {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String apartment;
  final String floor;
  final String street;
  final String building;
  final String city;
  final String country;
  final String state;
  final String postalCode;

  CustomerData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.apartment = "NA",
    this.floor = "NA",
    this.street = "NA",
    this.building = "NA",
    this.city = "NA",
    this.country = "SA",
    this.state = "NA",
    this.postalCode = "NA",
  });

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone_number': phoneNumber,
    'apartment': apartment,
    'floor': floor,
    'street': street,
    'building': building,
    'shipping_method': "NA",
    'postal_code': postalCode,
    'city': city,
    'country': country,
    'state': state,
  };

  /// إنشاء CustomerData من بيانات المستخدم المحفوظة
  static CustomerData fromUserData(Map<String, dynamic> userData) {
    return CustomerData(
      firstName: userData['firstName'] ?? 'Customer',
      lastName: userData['lastName'] ?? 'User',
      email: userData['email'] ?? 'customer@example.com',
      phoneNumber: userData['phoneNumber'] ?? '+966500000000',
      city: userData['address'] ?? 'Riyadh',
    );
  }
}

class PaymentResponse {
  final bool success;
  final String? paymentToken;
  final String? orderId;
  final String? errorMessage;
  final Map<String, dynamic>? rawData;

  PaymentResponse({
    required this.success,
    this.paymentToken,
    this.orderId,
    this.errorMessage,
    this.rawData,
  });

  factory PaymentResponse.success({
    required String paymentToken,
    required String orderId,
    Map<String, dynamic>? rawData,
  }) {
    return PaymentResponse(
      success: true,
      paymentToken: paymentToken,
      orderId: orderId,
      rawData: rawData,
    );
  }

  factory PaymentResponse.error(String errorMessage) {
    return PaymentResponse(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

class PaymentStatus {
  final bool isSuccessful;
  final bool isPending;
  final bool hasError;
  final String? transactionId;
  final String? responseCode;
  final String? errorMessage;
  final DateTime checkedAt;

  PaymentStatus({
    required this.isSuccessful,
    required this.isPending,
    required this.hasError,
    this.transactionId,
    this.responseCode,
    this.errorMessage,
    required this.checkedAt,
  });

  factory PaymentStatus.fromApiResponse(Map<String, dynamic> data) {
    final bool success = data["success"] == true;
    final bool pending = data["pending"] == false; // false يعني غير معلق
    final bool errorOccurred = data["error_occured"] == false; // false يعني لا يوجد خطأ
    final String? txnResponseCode = data["data"]?["txn_response_code"];
    final String? migsResult = data["data"]?["migs_result"];

    // تحديد حالة النجاح بناءً على المعايير المختلفة
    final bool isSuccessful = success && 
                             pending && 
                             errorOccurred && 
                             (txnResponseCode == "APPROVED" || 
                              migsResult == "SUCCESS" ||
                              txnResponseCode == "00"); // رمز النجاح الشائع

    return PaymentStatus(
      isSuccessful: isSuccessful,
      isPending: !pending,
      hasError: !errorOccurred,
      transactionId: data["data"]?["id"]?.toString(),
      responseCode: txnResponseCode ?? migsResult,
      errorMessage: isSuccessful ? null : 'فشل الدفع أو العملية معلقة',
      checkedAt: DateTime.now(),
    );
  }
}

enum PaymentMethod {
  cod('COD', 'الدفع عند الاستلام'),
  card('CARD', 'البطاقة الائتمانية'),
  stcPay('STC_PAY', 'stc pay'),
  applePay('APPLE_PAY', 'Apple Pay');

  const PaymentMethod(this.code, this.arabicName);
  final String code;
  final String arabicName;
}

class PaymentException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  PaymentException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'PaymentException: $message${code != null ? ' (Code: $code)' : ''}';
}
