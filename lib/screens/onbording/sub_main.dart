import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/l10n/app_localizations.dart';
import 'package:melaq/l10n/language_helper.dart';
import 'package:melaq/main.dart';
import 'package:melaq/route/route_constants.dart';
import 'package:melaq/constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // ✅ دالة تسجيل الدخول كزائر
  Future<void> _loginAsGuest(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true); // حفظ حالة الدخول كزائر
    Navigator.pushReplacementNamed(context, entryPointScreenRoute); // الانتقال إلى الصفحة الرئيسية
  }

  // ✅ الانتقال إلى شاشة تسجيل الدخول
  Future<void> _navigateToLogin(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userid');

    if (userId == null) {
      Navigator.pushNamed(context, logInScreenRoute);
    } else {
      Navigator.pushNamed(context, entryPointScreenRoute);
    }
  }

  void changeLanguage(BuildContext context) async {
    String? currentLanguage = await LanguageHelper.getCurrentLanguage();

    // تحديد اللغة الجديدة بناءً على اللغة الحالية
    String newLanguage = (currentLanguage == 'en') ? 'ar' : 'en';

    // حفظ اللغة الجديدة في الكاش
    await LanguageHelper.setLanguage(newLanguage);

    // إعادة تشغيل التطبيق فقط إذا كانت الـ widget ما زالت موجودة في الـ tree
    if (context.mounted) {
      RestartWidget.restartApp(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
    TextButton(
                onPressed: () {
                   changeLanguage(context);
                },
                child: Row(
                    children: [
                      Icon(
                        Icons.language,  // أيقونة اللغة
                        color: primaryColor, // لون الأيقونة
                      ),
                      SizedBox(width: 8), // المسافة بين الأيقونة والكلمة
                      FutureBuilder<String?>(
                        future: LanguageHelper.getCurrentLanguage(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else {
                            String currentLanguage = snapshot.data ?? 'ar';
                            return Text(
                              currentLanguage == 'ar' ? 'انجليزي' : 'عربي', // هنا تعتمد على اللغة المخزنة
                              style: const TextStyle(color: primaryColor),
                            );
                          }
                        },
                      ),
                      SizedBox(width: 18), // المسافة بين الأيقونة والكلمة
                    ],
              ),
              ),
          
              const SizedBox(width: 8), // المسافة بين الأيقونة والكلمة
              // ✅ إضافة الشعار
              Image.asset(
                'assets/images/logo_white.png', // مسار الشعار
                width: 650, // عرض الشعار (يمكن تعديله حسب الرغبة)
                height: 400, // ارتفاع الشعار (يمكن تعديله حسب الرغبة)
              ),
              const SizedBox(height: 20), // مساحة بين الشعار والنص
              Text(
                AppLocalizations.of(context)!.wellcom_you,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // ✅ زر الدخول كزائر
              ElevatedButton(
                onPressed: () => _loginAsGuest(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  backgroundColor: Colors.grey[700],
                ),
                child: Text(
                  AppLocalizations.of(context)!.loginAsGuest,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 15),

              // ✅ زر تسجيل الدخول
              ElevatedButton(
                onPressed: () => _navigateToLogin(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  backgroundColor: primaryColor,
                ),
                child: Text(
                  AppLocalizations.of(context)!.login,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 15),

            ],
          ),
        ),
      ),
    );
  }
}