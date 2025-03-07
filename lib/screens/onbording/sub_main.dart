import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/l10n/app_localizations.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/constants.dart';
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
      return;
    }else{
      Navigator.pushNamed(context, entryPointScreenRoute);
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
                child: Text(AppLocalizations.of(context)!.loginAsGuest, style: const TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 15),

              // ✅ زر تسجيل الدخول
              ElevatedButton(
                onPressed: () => _navigateToLogin(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  backgroundColor: primaryColor,
                ),
                child: Text(AppLocalizations.of(context)!.login, style: const TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
