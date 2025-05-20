import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/components/api_extintion/url_api.dart';

class AuthService {
  final String apiUrl_verifyOTP = APIConfig.otpapiverifyEndpoint; // تأكد من أن هذا هو URL الصحيح للتحقق
  final String apiUrl_sendOTP = APIConfig.otpapisendOTPEndpoint;
  // final String apiSecret = '\$2y\$10\$jUwPsrvdplRWoTD5nGoaCOjD3j.3bNEhC3iIAma1TV9xDseuCYhZG';
  final String apiSecret = "\$2y\$10\$hpoyPELoF.EOEPUsnuN3getdiKmDdL9Q1e2FQYI8F27FB9fsJTs2.";
  Future<bool> sendOTP(String phone) async {
    final response = await http.post(
      Uri.parse(apiUrl_sendOTP),
      headers: {
        'Accept': 'application/json',
        'X-Authorization': apiSecret,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phone': phone,
        'method': 'sms',
        'number_of_digits': 4,
        'otp_format': 'numeric',
        'is_fallback_on': 0,
      }),
    );

    if (response.statusCode == 200) {
      print('OTP sent successfully');
      return true;
    } else {
      print('Failed to send OTP: ${response.body}');
      return false;
    }
  }
   
   Future<bool> verifyOTP(String phone, String otp) async {
    final response = await http.post(
      Uri.parse(apiUrl_verifyOTP),
      headers: {
        'Accept': 'application/json',
        'X-Authorization': apiSecret,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phone': phone,
        'otp': otp,
        'method': 'sms',
      }),
    );
    if (response.statusCode == 200) {
      print('OTP verified successfully');
      return true;
    } else {
    print(response.statusCode);
      print('Failed to verify OTP: ${response.body}');
      return false;
    }

}
}
