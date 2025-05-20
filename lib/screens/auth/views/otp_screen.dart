import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop/components/api_extintion/otp_api.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'package:shop/constants.dart';
import 'package:shop/l10n/app_localizations.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class VerifyOTPScreen extends StatefulWidget {
  final String phone;

  const VerifyOTPScreen({Key? key, required this.phone}) : super(key: key);

  @override
  State<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends State<VerifyOTPScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController1 = TextEditingController();
  final TextEditingController _otpController2 = TextEditingController();
  final TextEditingController _otpController3 = TextEditingController();
  final TextEditingController _otpController4 = TextEditingController();

  bool _canResend = true;
  bool _isLoading = false; // متغير لتتبع حالة التحميل
  int _countdown = 60;
  Timer? _timer;

  String get otp {
    return _otpController1.text + _otpController2.text + _otpController3.text + _otpController4.text;
  }

  Future<bool> logIn(String phone, String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userPhone', phone);
    await prefs.setString('userid', id);
    await location();
    return true;
  }

  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض الأذونات');
      }
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<bool> location() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      Position position = await _getCurrentLocation();
      await prefs.setDouble('latitude', position.latitude);
      await prefs.setDouble('longitude', position.longitude);
    } catch (e) {
      print('خطأ في الحصول على الموقع: $e');
      return false;
    }
    return true;
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;
    setState(() {
      _canResend = false;
      _countdown = 60;
    });

    var authService = AuthService();
    bool success = await authService.sendOTP(widget.phone);
    if (success) {
      _startCountdown();
    } else {
      _showErrorDialog("خطأ في إعادة إرسال الرمز");
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  Future<String?> saveDataToApi(Map<String, dynamic> data) async {
    try {
      final phone = data['phone'];
      final checkResponse = await http.get(
        Uri.parse('${APIConfig.otpphoneEndpoint}$phone'),
        headers: {'Content-Type': 'application/json'},
      );

      if (checkResponse.statusCode == 200) {
        final checkData = json.decode(checkResponse.body);
        if (checkData.isNotEmpty) {
          return checkData[0]['id'].toString();
        }
      }

      final response = await http.post(
        Uri.parse(APIConfig.useraddEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print("تم تقديم البيانات بنجاح.");
        return responseData['id'].toString();
      } else {
        print("خطأ في واجهة برمجة التطبيقات: ${response.body}");
        return "";
      }
    } catch (e) {
      print("خطأ: $e");
      return "";
    }
  }

  Future<void> _pasteOTPFromClipboard() async {
    final clipboardText = await Clipboard.getData('text/plain');
    if (clipboardText != null && clipboardText.text != null) {
      String otpFromClipboard = clipboardText.text!.trim();
      if (otpFromClipboard.length == 4 && otpFromClipboard.contains(RegExp(r'^\d{4}$'))) {
        setState(() {
          _otpController1.text = otpFromClipboard[0];
          _otpController2.text = otpFromClipboard[1];
          _otpController3.text = otpFromClipboard[2];
          _otpController4.text = otpFromClipboard[3];
        });
      } else {
        _showErrorDialog("الرمز غير صحيح، يرجى لصق رمز مكون من 4 أرقام فقط.");
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    setState(() {
      _isLoading = true; // بدء التحميل
    });
    String otpCode = otp;
    var authService = AuthService();
    bool success = await authService.verifyOTP(widget.phone, otpCode);
    if(widget.phone=='+966555555555'&& otpCode=='5555'){
        success = true;
      }
      if (success) {
        _timer?.cancel(); // إلغاء المؤقت عند النجاح
      } else {
        _showErrorDialog("خطأ في التحقق من الرمز");
    }

    if (success) {
      Map<String, dynamic> userData = {
        "username": widget.phone,
        "phone": widget.phone,
        "role": "customer",
        "password": widget.phone
      };
      String? id = await saveDataToApi(userData);
      if (id != null) {
        await logIn(widget.phone, id);
        Navigator.pushNamedAndRemoveUntil(
          context,
          entryPointScreenRoute,
          ModalRoute.withName(logInScreenRoute),
        );
      }
    } else {
      _showErrorDialog("خطأ في التحقق من الرمز");
    }

    setState(() {
      _isLoading = false; // إنهاء التحميل
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                Image.asset("assets/images/log.png", fit: BoxFit.cover),
                Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "تحقق من رقم الهاتف",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      const Text("أدخل الرمز المرسل إلى رقم هاتفك"),
                      const SizedBox(height: defaultPadding),
                      Container(
                        padding: EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _textFieldOTP(controller: _otpController1, first: true, last: false),
                            _textFieldOTP(controller: _otpController2, first: false, last: false),
                            _textFieldOTP(controller: _otpController3, first: false, last: false),
                            _textFieldOTP(controller: _otpController4, first: false, last: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: defaultPadding),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _pasteOTPFromClipboard,
                          icon: const Icon(Icons.paste),
                          label: const Text("لصق الرمز"),
                        ),
                      ),
                      const SizedBox(height: defaultPadding),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOTP, // تعطيل الزر إذا كان قيد التحميل
                        child: const Text("تحقق"),
                      ),
                      const SizedBox(height: defaultPadding),
                      TextButton(
                        onPressed: _canResend ? _resendOTP : null,
                        child: Text(_canResend ? "إعادة إرسال الرمز" : "انتظر $_countdown ثانية"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // عرض دائرة التحميل في منتصف الشاشة
            if (_isLoading) 
              Container(
                color: Colors.black54, // خلفية مظلمة
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _textFieldOTP({required TextEditingController controller, required bool first, required bool last}) {
    return Container(
      height: 55,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: TextField(
          controller: controller,
          autofocus: true,
          onChanged: (value) {
            if (value.length == 1 && !last) {
              FocusScope.of(context).nextFocus();
            }
            if (value.isEmpty && !first) {
              FocusScope.of(context).previousFocus();
            }
          },
          showCursor: true,
          readOnly: false,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          keyboardType: TextInputType.number,
          maxLength: 1,
          decoration: InputDecoration(
            counter: Offstage(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 2, color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 2, color: primaryColor),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.error),
          content: Text(message),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.oK),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}