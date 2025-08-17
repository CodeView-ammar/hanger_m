import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/route/route_constants.dart';
import 'package:melaq/screens/force_update_screen.dart';
import 'package:melaq/screens/version_checker.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(_controller);

    // الانتظار لمدة 3 ثوانٍ قبل الانتقال
    _checkForUpdate();
  }

  void _checkForUpdate() async {
    final updateResult = await CheckUpdateService().checkAppVersion();

  if (updateResult != null && !updateResult.updateAvailable) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => UpdateScreen(
        message: updateResult.message,
        forceUpdate: updateResult.forceUpdate,
        updateUrl: Platform.isAndroid
            ? 'https://play.google.com/store/apps/details?id=com.hangerapp.hanger_m'
            : 'https://apps.apple.com/us/app/melaq/id6746159760',
        
      ),
    ));
     
  } else {
    _navigateToNextScreen();
  }
}
  Future<void> _navigateToNextScreen() async {
    await Future.delayed(Duration(seconds: 3));
    
    // التحقق من إذا كانت الشاشة ما تزال موجودة
    if (mounted) {
        Navigator.of(context).pushReplacementNamed(WelcomeScreenScreenRoute);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor,
              secondaryColor,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _animation,
                child: Image.asset(
                  "assets/images/splash_screen.png", // استبدل بالصورة التي تريدها
                ),
              ),
              const SizedBox(height: 20),
              
            ],
          ),
        ),
      ),
    );
  }
}
