import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:melaq/components/api_extintion/url_api.dart';

class AuthService {
  final String apiUrl_verifyOTP = APIConfig.otpapiverifyEndpoint; // تأكد من أن هذا هو URL الصحيح للتحقق
  final String apiUrl_sendOTP = APIConfig.otpapisendOTPEndpoint;
Future<bool> sendOTP(String phone) async {
    final response = await http.post(
      Uri.parse(apiUrl_sendOTP),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phone': phone,
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
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phone': phone,
        'otp': otp,
      }),
    );
    if (response.statusCode == 200) {
      print('OTP verified successfully');
      return true;
    } else {
    print(response.statusCode);
      print('Failed to verify  OTP: ${response.body}'); 
      return false;
    }

}
}
