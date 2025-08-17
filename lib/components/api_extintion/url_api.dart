class APIConfig {
  static const String _baseUrl = 'https://hangerapp.com.sa';
  static const String baseUrl = _baseUrl;
  static const String api_baseUrl='$_baseUrl/api';
 
  static const String static_baseUrl='$_baseUrl/static';


  static String get launderiesEndpoint => '$api_baseUrl/laundries/';
  static String get categoriesEndpoint => '$api_baseUrl/categores/';
  static String get bannerEndpoint => '$api_baseUrl/slide-show/';
  static String get userEndpoint => '$api_baseUrl/users/register/';
  static String get markEndpoint_get => '$api_baseUrl/user_laundry_marks_a/';
  static String get markEndpoint_delete => '$api_baseUrl/user_laundry_marks_delete/';
  // static String get servicesEndpoint => '$api_baseUrl/services/';
  static String get servicesEndpoint => '$api_baseUrl/laundry-services/';
  
  static String get otpphoneEndpoint => '$api_baseUrl/user_phone/';
  static String get useraddEndpoint => '$api_baseUrl/users/';
  static String get markerEndpoint => '$api_baseUrl/user_laundry_marks/';
  static String get CartsEndpoint => '$api_baseUrl/carts/';
  static String get addressesEndpoint => '$api_baseUrl/addresses/';
  static String get getaddressEndpoint => '$api_baseUrl/address/';
  static String get cartfilterEndpoint => '$api_baseUrl/cart/filter/';
  static String get cartupdateEndpoint => '$api_baseUrl/cart/update/';
  static String get cartRemoveEndpoint => '$api_baseUrl/cart/delete/';
  static String get orderSubmitUrl => '$api_baseUrl/submit-order/';
  static String get addPaymentUrl => '$api_baseUrl/add-payment-method/';
  static String get getPaymentMethodViewSetUrl => '$api_baseUrl/getPaymentMethodViewSet';
  static String get PaymentUrl => '$api_baseUrl/payment-methods/';
  static String get orderuserUrl => '$api_baseUrl/orders-user/';
  static String get orderlaundryUrl => '$api_baseUrl/orders-laundry/';
  static String get orderstatusUrl => '$api_baseUrl/orders-status/';
  static String get orderdetilsUrl => '$api_baseUrl/orders-detils/';
  static String get orderitemget_order_itemsUrl => '$api_baseUrl/orders-items/get_order_items/';
  static String get orderStatusEdit => '$api_baseUrl/order';
  static String get deliverysettingEndpoint => '$api_baseUrl/delivery-setting/';
  static String get notificationsEndpoint => '$api_baseUrl/notifications/';
  static String get salesagentorderEndpoint => '$api_baseUrl/sales-agent-order/';
  static String get addTransactionEndpoint => '$api_baseUrl/transactions/';
  
  // Support System APIs
  static String get supportTicketsEndpoint => '$api_baseUrl/support/tickets/';
  static String get supportMessagesEndpoint => '$api_baseUrl/support/messages/';
  static String get supportFAQEndpoint => '$api_baseUrl/support/faq/';
  static String get supportStatisticsEndpoint => '$api_baseUrl/support/statistics/';
  static String get supportChatEndpoint => '$api_baseUrl/support-chat/';
  
  // Reviews APIs
  static String get laundryReviewsEndpoint => '$api_baseUrl/reviews/laundry/';
  static String get reviewStatsEndpoint => '$api_baseUrl/reviews/laundry/';
  
  // Enhanced Notifications APIs
  static String get notificationUserEndpoint => '$api_baseUrl/notifications/user/';
  static String get notificationUnreadCountEndpoint => '$api_baseUrl/notifications/user/';
  
  static String get SubServicesEndpoint => '$api_baseUrl/subservices/';
  
  static String get checkUpdateEndpoint => '$api_baseUrl/check-update/';
  static String get updatefcmEndpoint => "$api_baseUrl/update-fcm/";
  
  static String get apiMap=>'AIzaSyA903FiEEzDSEmogbe9-PkmA_v520gnrQ4';
  static String get apiPayment=>'pk_test_gLVjbsVjL1U2XZiKtFD9sRr6abDTJZS3GgKstC2G';
 
 
  static String get otpapiverifyEndpoint => "$api_baseUrl/sdk/v1/verifyOTP";
  static String get otpapisendOTPEndpoint => "$api_baseUrl/sdk/v1/sendOTP";
  
}