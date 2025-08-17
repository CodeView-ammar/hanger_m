import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/network_image_with_loader.dart';
import 'package:melaq/l10n/app_localizations.dart';
import 'package:melaq/screens/auth/views/login_screen.dart';
import 'package:melaq/screens/profile/views/profile_screen.dart';

import '../../../../constants.dart';

class ProfileCard extends StatefulWidget {
  const ProfileCard({
    super.key,
    required this.name,
    this.proLableText = "Pro",
    this.isPro = false,
    this.press,
    this.isShowHi = true,
    this.isShowArrow = true,
    this.imageSrc = "", // تغيير لتقبل قيمة فارغة
  });

  final String name;
  final String proLableText;
  final bool isPro, isShowHi, isShowArrow;
  final String imageSrc;  // إذا كانت فارغة سنعرض الأيقونة بدلاً من الصورة
  final VoidCallback? press;

  @override
  _ProfileCardState createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  late bool isLoggedIn = false;  // متغير لتخزين حالة تسجيل الدخول
  String phoneNumber = ""; // لتخزين رقم الهاتف بعد تسجيل الدخول

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // دالة للتحقق من حالة تسجيل الدخول
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedPhone = prefs.getString('userPhone');  // جلب رقم الهاتف

    setState(() {
      // إذا كان هناك رقم هاتف محفوظ، يعني أن المستخدم مسجل دخول
      isLoggedIn = savedPhone != null && savedPhone.isNotEmpty;
      phoneNumber = savedPhone ?? "";  // إذا كان موجودًا، قم بتخزينه في المتغير
    });
  }

  // دالة للتنقل بين الشاشات بناءً على حالة المستخدم
  void _onTap() {
    if (isLoggedIn) {
      // إذا كان المستخدم مسجل دخول، افتح الشاشة الحالية
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => ProfileScreen()),  // تأكد من تعديل هذا ليفتح شاشة الملف الشخصي أو الصفحة التي تريدها.
      // );
    } else {
      // إذا كان المستخدم غير مسجل، افتح شاشة تسجيل الدخول
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),  // تأكد من تعديل هذا ليفتح شاشة تسجيل الدخول الخاصة بك.
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: _onTap,  // استبدال الضغط باستخدام الدالة _onTap
      leading: CircleAvatar(
        radius: 28,
        child: Icon(
                Icons.person,  // أيقونة المستخدم
                size: 28,
                color: const Color.fromARGB(255, 0, 0, 0),  // لون الأيقونة
              ),
            
      ),
      title: Row(
        children: [
          Text(
            isLoggedIn ? "هلا, ${widget.name}" : AppLocalizations.of(context)!.login, // إظهار "هلا" أو "تسجيل الدخول"
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: defaultPadding / 2),
          if (widget.isPro)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding / 2, vertical: defaultPadding / 4),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius:
                    BorderRadius.all(Radius.circular(defaultBorderRadious)),
              ),
              child: Text(
                widget.proLableText,
                style: const TextStyle(
                  fontFamily: grandisExtendedFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.7,
                  height: 1,
                ),
              ),
            ),
        ],
      ),
      subtitle: isLoggedIn
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${AppLocalizations.of(context)!.numberphone}: $phoneNumber",
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: _onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.login,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      // trailing: widget.isShowArrow
      //     ? SvgPicture.asset(
      //         "assets/icons/miniRight.svg",
      //         color: Theme.of(context).iconTheme.color!.withOpacity(0.4),
      //       )
      //     : null,
    );
  }
}
