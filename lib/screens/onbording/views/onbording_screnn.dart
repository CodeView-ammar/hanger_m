import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:melaq/components/dot_indicators.dart';
import 'package:melaq/l10n/language_helper.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/main.dart';
import 'package:melaq/route/route_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/onbording_content.dart';
import 'package:melaq/l10n/app_localizations.dart';

class OnBordingScreen extends StatefulWidget {
  const OnBordingScreen({super.key});

  @override
  State<OnBordingScreen> createState() => _OnBordingScreenState();
}


class _OnBordingScreenState extends State<OnBordingScreen> {
  late PageController _pageController;
  int _pageIndex = 0;
  final List<Onbord> _onbordData = [
    Onbord(
      image: "assets/images/logo_white.png",
      imageDarkTheme: "assets/images/logo_white.png",
      title:"welcomeapp",
      description:"welcomeapp_detils",
    ),
    Onbord(
      image: "assets/Illustration/Illustration-0.png",
      imageDarkTheme: "assets/Illustration/Illustration-0.png",
      title:"search_laundries",
      description:"find_laundries_nearby",
    ),
    Onbord(
      image: "assets/Illustration/Illustration-1.png",
      imageDarkTheme: "assets/Illustration/Illustration-1.png",
      title:"choose_laundry_and_clothes",
      description:"choose_and_deliver",
    ),
    Onbord(
      image: "assets/Illustration/Illustration-2.png",
      imageDarkTheme: "assets/Illustration/Illustration-2.png",
      title: "quick_and_safe_payment",
      description:"multiple_payment_options" ,
    ),
    Onbord(
      image: "assets/Illustration/Illustration-3.png",
      imageDarkTheme: "assets/Illustration/Illustration-3.png",
      title: "track_order",
      description:
      "manage_shipments"          ,
    ),
    Onbord(
      image: "assets/Illustration/Illustration-4.png",
      imageDarkTheme: "assets/Illustration/Illustration-4.png",
      title: "nearby_laundries",
      description:"browse_and_get_info",
    ),
  ];

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // دالة للتحقق مما إذا كان الرقم مسجلًا أم لا
  Future<bool> _isPhoneNumberRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userPhone') != null;
  }

  void _navigateBasedOnPhoneStatus() async {
    
      Navigator.pushNamed(context, WelcomeScreenScreenRoute); // التوجه إلى شاشة تسجيل الدخول
  }
  
  String? get_translation(BuildContext context, String key) {
    final localizations = AppLocalizations.of(context);
    final translations = {
      'skip': localizations?.skip,
      "welcomeapp": localizations?.welcomeapp,
      "welcomeapp_detils": localizations?.welcomeapp_detils,
      'search_laundries': localizations?.search_laundries,
      'find_laundries_nearby': localizations?.find_laundries_nearby,
      'choose_laundry_and_clothes': localizations?.choose_laundry_and_clothes,
      'choose_and_deliver': localizations?.choose_and_deliver,
      'quick_and_safe_payment': localizations?.quick_and_safe_payment,
      'multiple_payment_options': localizations?.multiple_payment_options,
      'track_order': localizations?.track_order,
      'manage_shipments': localizations?.manage_shipments,
      'nearby_laundries': localizations?.nearby_laundries,
      'browse_and_get_info': localizations?.browse_and_get_info,
      'title_app': localizations?.title_app,
    };
    return translations[key];
  }
void changelangoing(BuildContext context) async {
  String? currentLanguage = await LanguageHelper.getCurrentLanguage();

  // تحديد اللغة الجديدة بناءً على اللغة الحالية
  String newLanguage = (currentLanguage == 'en') ? 'ar' : 'en';

  // حفظ اللغة الجديدة في الكاش
  await LanguageHelper.setLanguage(newLanguage);

  // إعادة تشغيل التطبيق فقط إذا كانت الـ widget ما زالت موجودة في الـ tree
  if (mounted) {
    RestartWidget.restartApp(context);
  }
}
  @override
  Widget build(BuildContext context) {
   return Scaffold(
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _navigateBasedOnPhoneStatus();
                },
                child: Text(
                  AppLocalizations.of(context)!.skip,
                  style: const TextStyle(color: primaryColor),
                ),
              ),
              const SizedBox(width: 140), // إضافة مسافة بين الزرين
              TextButton(
                onPressed: () {
                  changelangoing(context);
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
              ),)
            ],
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _onbordData.length,
              onPageChanged: (value) {
                setState(() {
                  _pageIndex = value;
                });
              },
              itemBuilder: (context, index) => OnbordingContent(

              title:  get_translation(context, _onbordData[index].title) ?? "",
              description:  get_translation(context, _onbordData[index].description) ?? "",
              image: (Theme.of(context).brightness == Brightness.light &&
                      _onbordData[index].imageDarkTheme != null)
                  ? _onbordData[index].imageDarkTheme!
                  : _onbordData[index].image,
              isTextOnTop: index.isOdd,
              )
            ),
          ),
          Row(
            children: [
              ...List.generate(
                _onbordData.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: defaultPadding / 4),
                  child: DotIndicator(isActive: index == _pageIndex),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 60,
                width: 60,
                child: ElevatedButton(
                  onPressed: () {
                    if (_pageIndex < _onbordData.length - 1) {
                      _pageController.nextPage(
                          curve: Curves.ease, duration: defaultDuration);
                    } else {
                      _navigateBasedOnPhoneStatus();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                  ),
                  child: SvgPicture.asset(
                    "assets/icons/Arrow - Right.svg",
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
        ],
      ),
    ),
  ),
);  }

}

class Onbord {
  final String image, title, description;
  final String? imageDarkTheme;

  Onbord({
    required this.image,
    required this.title,
    this.description = "",
    this.imageDarkTheme,
  });
}
