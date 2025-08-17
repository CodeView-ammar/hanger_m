import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/route/route_constants.dart';


import 'package:url_launcher/url_launcher.dart';

class UpdateScreen extends StatelessWidget {
  final String message;
  final bool forceUpdate;
  final String updateUrl;
  final VoidCallback? onSkipUpdate;  // دالة اختيارية
  const UpdateScreen({
    Key? key,
    required this.message,
    required this.forceUpdate,
    required this.updateUrl,
    this.onSkipUpdate,
  }) : super(key: key);

  void _launchUpdateUrl() async {
    if (await canLaunchUrl(Uri.parse(updateUrl))) {
      await launchUrl(Uri.parse(updateUrl), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async => !forceUpdate, // منع الرجوع إذا التحديث إجباري
      child: Scaffold(
        backgroundColor: primaryColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.system_update, size: 100, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  "تحديث متوفر",
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  utf8.decode(message.codeUnits),
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _launchUpdateUrl,
                  child: const Text("تحديث الآن"),
                ),
                 if (!forceUpdate)
                  TextButton(
                    onPressed: () async {

                      Navigator.of(context).pushReplacementNamed(WelcomeScreenScreenRoute);

                  //   Navigator.of(context).pushReplacement(
                  // PageRouteBuilder(
                  //   pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
                  //   transitionDuration: const Duration(milliseconds: 800),
                  //   transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  //     return FadeTransition(
                  //       opacity: animation,
                  //       child: SlideTransition(
                  //         position: Tween<Offset>(
                  //           begin: const Offset(0, 0.1),
                  //           end: Offset.zero,
                  //         ).animate(CurvedAnimation(
                  //           parent: animation,
                  //           curve: Curves.easeOutCubic,
                  //         )),
                  //         child: child,
                  //       ),
                  //     );
                  //   },
                  // ),);
                          },
                    child: const Text("تحديث لاحقاً", style: TextStyle(color: Colors.white70)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
