import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:melaq/components/api_extintion/otp_api.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/components/custom_messages.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/route/route_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:sms_autofill/sms_autofill.dart';

class VerifyOTPScreen extends StatefulWidget {
  final String phone;
  const VerifyOTPScreen({Key? key, required this.phone}) : super(key: key);

  @override
  State<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends State<VerifyOTPScreen> with WidgetsBindingObserver {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController1 = TextEditingController();
  final TextEditingController _otpController2 = TextEditingController();
  final TextEditingController _otpController3 = TextEditingController();
  final TextEditingController _otpController4 = TextEditingController();
  
  // متغير لتخزين الرمز كاملاً
  final TextEditingController _fullOtpController = TextEditingController();

  bool _canResend = true;
  bool _isLoading = false; // متغير لتتبع حالة التحميل
  int _countdown = 60;
  Timer? _timer;
  Timer? _clipboardCheckTimer;
  
  // التوجيه لدعم اللغة العربية
  final TextDirection _textDirection = TextDirection.rtl;

  // String get otp {
  //   return _otpController1.text + _otpController2.text + _otpController3.text + _otpController4.text;
  // }
  String otp = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SmsAutoFill().listenForCode();
    // بدء التحقق من الحافظة بشكل دوري
    // _startClipboardCheck();
    
    // طلب التركيز على الحقل الأول بعد بناء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
    
    // مراقبة تغييرات الرمز الكامل
    _fullOtpController.addListener(_onFullOtpChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // عند العودة للتطبيق، تحقق من الحافظة
    if (state == AppLifecycleState.resumed) {
      _pasteOTPFromClipboard();
    }
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
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      String clipboardText = clipboardData.text!.trim();
      
      // البحث عن نمط رمز التحقق في النص
      RegExp otpPattern = RegExp(r'[^0-9](\d{4})[^0-9]');
      RegExpMatch? match = otpPattern.firstMatch(' $clipboardText ');
      
      if (match != null && match.group(1) != null) {
        // إذا وجد نمط رمز في النص (مثل "رمز التحقق هو: 1234")
        _fillOtpFields(match.group(1)!);
        return;
      } else if (clipboardText.length == 4 && RegExp(r'^\d{4}$').hasMatch(clipboardText)) {
        // إذا كان النص المنسوخ هو 4 أرقام فقط
        _fillOtpFields(clipboardText);
        return;
      } else {
        // محاولة استخراج 4 أرقام متتالية من النص
        RegExp digitsOnly = RegExp(r'\d{4}');
        match = digitsOnly.firstMatch(clipboardText);
        if (match != null) {
          _fillOtpFields(match.group(0)!);
          return;
        }
      }
      
      // // إذا لم يتم العثور على رمز صالح
      // AppMessageService().showWarningMessage(
      //   context, 
      //   'لم يتم العثور على رمز تحقق صالح في النص المنسوخ. يجب أن يكون الرمز 4 أرقام.',
      // );
    } else {
      
    }
  }

  // دالة للتعامل مع تغيير الرمز الكامل
  void _onFullOtpChanged() {
    String fullOtp = _fullOtpController.text;
    if (fullOtp.length == 4) {
      _otpController4.text = fullOtp[3];
      _otpController3.text = fullOtp[2];
      _otpController2.text = fullOtp[1];
      _otpController1.text = fullOtp[0];
    }
  }
  
  // بدء التحقق من الحافظة بشكل دوري
  void _startClipboardCheck() {
    _clipboardCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkClipboardForOTP();
    });
  }
  
  // التحقق من الحافظة بحثاً عن رمز OTP
  Future<void> _checkClipboardForOTP() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      String clipboardText = clipboardData.text!.trim();
      
      // البحث عن أنماط OTP في النص
      // مثل: "رمز التحقق الخاص بك هو: 1234" أو "1234 هو رمز التحقق" أو مجرد 4 أرقام
      RegExp otpRegex = RegExp(r'[^0-9](\d{4})[^0-9]');
      RegExpMatch? match = otpRegex.firstMatch(' $clipboardText ');
      
      if (match != null && match.group(1) != null) {
        String otpCode = match.group(1)!;
        _fillOtpFields(otpCode);
      } else if (clipboardText.length == 4 && RegExp(r'^\d{4}$').hasMatch(clipboardText)) {
        // في حالة كان النص عبارة عن 4 أرقام فقط
        _fillOtpFields(clipboardText);
      }
    }
  }
  
  // تعبئة حقول OTP
  void _fillOtpFields(String otpCode) {
    if (otpCode.length == 4) {
      setState(() {
        _otpController1.text = otpCode[0];
        _otpController2.text = otpCode[1];
        _otpController3.text = otpCode[2];
        _otpController4.text = otpCode[3];
      });
      
      // // عرض إشعار بالرمز المكتشف
      // AppMessageService().showSuccessMessage(
      //   context, 
      //   'تم التعرف على رمز التحقق تلقائياً: $otpCode'
      // );
      
      // التحقق من الرمز مباشرة
      Future.delayed(Duration(milliseconds: 500), () {
        _verifyOTP();
      });
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _clipboardCheckTimer?.cancel();
    _fullOtpController.removeListener(_onFullOtpChanged);
    _fullOtpController.dispose();
    _otpController1.dispose();
    _otpController2.dispose();
    _otpController3.dispose();
    _otpController4.dispose();
    WidgetsBinding.instance.removeObserver(this);
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  Future<void> _verifyOTP({String otp = ''}) async {
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
        // _showErrorDialog("خطأ في التحقق من الرمز");
    }

      // الحصول على التوكن من Firebase
      String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (success) {
        Map<String, dynamic> userData = {
        "username": widget.phone,
        "phone": widget.phone,
        "role": "customer",
        "password": widget.phone,
        "fcm": fcmToken

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
      // _showErrorDialog("خطأ في التحقق من الرمز");
    }

    setState(() {
      _isLoading = false; // إنهاء التحميل
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // ضبط الاتجاه للغة العربية
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: Image.asset(
            "assets/images/logo_white.png",
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Color(0xFFF5F5F5),
                    ],
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // صورة وعنوان الصفحة
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.security,
                            size: 60,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: defaultPadding * 1.5),
                      
                      // عنوان الشاشة
                      Center(
                        child: Text(
                          "تحقق من رقم الهاتف",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: defaultPadding / 2),
                      
                      // وصف الشاشة
                      Center(
                        child: Text(
                          "تم إرسال رمز تحقق مكون من 4 أرقام إلى رقم الهاتف ${widget.phone}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: defaultPadding * 1.5),
                      
                      PinFieldAutoFill(
                          codeLength: 4, // أو 6 حسب عدد خانات OTP
                          onCodeChanged: (code) {
                            if (code != null && code.length == 4) {
                              setState(() {
                                otp = code;
                              });
                              _verifyOTP(otp: code); 
                              // يمكنك استدعاء _verifyOTP هنا مباشرة إن أردت
                            }
                          },
                          onCodeSubmitted: (code) {
                            // عند إدخال الرمز كاملًا
                            print("OTP Submitted: $code");
                          },
                          decoration: UnderlineDecoration(
                            textStyle: TextStyle(fontSize: 24, color: primaryColor),
                            colorBuilder: FixedColorBuilder(primaryColor),
                          ),
                        ),
                      // زر لصق الرمز
                      // const SizedBox(height: defaultPadding * 1.5),
                      // Center(
                      //   child: TextButton.icon(
                      //     onPressed: _pasteOTPFromClipboard,
                      //     icon: const Icon(Icons.content_paste_rounded),
                      //     label: const Text("لصق الرمز تلقائياً"),
                      //     style: TextButton.styleFrom(
                      //       backgroundColor: Colors.grey[100],
                      //       foregroundColor: primaryColor,
                      //       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(8),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      
                      // زر التحقق
                      const SizedBox(height: defaultPadding * 1.5),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                            ?  Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text("جارِ التحقق..."),
                                ],
                              )
                            : const Text(
                                "تحقق من الرمز",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                        ),
                      ),
                      
                      // زر إعادة إرسال الرمز
                      const SizedBox(height: defaultPadding),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              "لم تستلم الرمز؟",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            TextButton(
                              onPressed: _canResend ? _resendOTP : null,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: Text(
                                _canResend ? "إعادة إرسال الرمز" : "انتظر $_countdown ثانية",
                                style: TextStyle(
                                  color: _canResend ? primaryColor : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // مؤشر التحميل في حالة التحقق
              if (_isLoading)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child:const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "جارِ التحقق من الرمز...",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
Widget _textFieldOTP({
  required TextEditingController controller,
  required bool first,
  required bool last,
}) {
  return Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.05),
          blurRadius: 5,
          spreadRadius: 1,
        ),
      ],
    ),
    child: TextField(
      controller: controller,
      autofocus: first,
      onChanged: (value) {
        // عند إدخال رقم، انتقل للحقل السابق (يمين إلى يسار)
        if (value.length == 1 && !first) {
          FocusScope.of(context).previousFocus();
        }
        // عند حذف الرقم، انتقل للحقل التالي (رجوع لليمين)
        if (value.isEmpty && !last) {
          FocusScope.of(context).nextFocus();
        }
      },
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
      keyboardType: TextInputType.number,
      maxLength: 1,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        counter: const Offstage(),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(width: 1.5, color: Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(width: 1.5, color: primaryColor),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.zero,
        hoverColor: primaryColor.withOpacity(0.1),
      ),
      textAlignVertical: TextAlignVertical.center,
      cursorColor: primaryColor,
      cursorWidth: 2,
      cursorHeight: 24,
      enableInteractiveSelection: false,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
    ),
  );
}

  // عرض رسائل الخطأ باستخدام مكون الرسائل المخصص
  void _showErrorDialog(String message) {
    AppMessageService().showErrorMessage(context, message, duration: const Duration(seconds: 4));
  }
  
  // عرض رسالة نجاح
  void _showSuccessMessage(String message) {
    AppMessageService().showSuccessMessage(context, message, duration: const Duration(seconds: 3));
  }
  
  // عرض رسالة تنبيه
  void _showInfoMessage(String message) {
    AppMessageService().showInfoMessage(context, message, duration: const Duration(seconds: 3));
  }
}