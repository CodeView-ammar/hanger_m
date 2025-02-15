import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/components/dot_indicators.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/onbording_content.dart';

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
      image: "assets/Illustration/Illustration-0.png",
      imageDarkTheme: "assets/Illustration/Illustration-0.png",
      title: "ابحث عن المغاسل التي بالقرب منك",
      description:
          "هنا ستجد جميع المغاسل مع التصنيفات الخاصة بها ومعرفة المغسلة الاقرب منك",
    ),
    Onbord(
      image: "assets/Illustration/Illustration-1.png",
      imageDarkTheme: "assets/Illustration/Illustration-1.png",
      title: "قم بإختيار المغسلة وإختيار انواع الثياب التي تريد ان تغسلها وضعها في السلة",
      description:
          "قم بإختيار المغسلة وإختيار انواع الثياب التي تريد ان تغسلها وضعها في السلة وسيتم الوصول إلا موقعك من قبل الدلفري الخاص بنا وتوصيلها للمغسلة المراد ",
    ),
    Onbord(
      image: "assets/Illustration/Illustration-2.png",
      imageDarkTheme: "assets/Illustration/Illustration-2.png",
      title: "دفع \nسريع وآمن",
      description: "هناك العديد من خيارات الدفع المتاحة لراحتك.",
    ),
    Onbord(
      image: "assets/Illustration/Illustration-3.png",
      imageDarkTheme: "assets/Illustration/Illustration-3.png",
      title: "تتبع الطلب",
      description:
          "على وجه الخصوص، يمكن لـ معلاق تعبئة طلباتك، ومساعدتك في إدارة شحناتك بسلاسة.",
    ),
    Onbord(
      image: "assets/Illustration/Illustration-4.png",
      imageDarkTheme: "assets/Illustration/Illustration-4.png",
      title: "المغاسل القريبة",
      description:
          "يمكنك بسهولة تتبع مغاسل وتصفح العناصر الخاصة بهم والحصول على معلومات حول خدماتهم.",
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

  // دالة للتنقل بناءً على حالة الرقم
  void _navigateBasedOnPhoneStatus() async {
    // bool isPhoneRegistered = await _isPhoneNumberRegistered();
    
    // if (isPhoneRegistered) {
    //   Navigator.pushNamedAndRemoveUntil(
    //       context,
    //       entryPointScreenRoute, // الشاشة التي تلي التحقق
    //       ModalRoute.withName(logInScreenRoute),
    //     ); // التوجه إلى الشاشة الرئيسية
    // } else {
      Navigator.pushNamed(context, entryPointScreenRoute); // التوجه إلى شاشة تسجيل الدخول
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _navigateBasedOnPhoneStatus();
                  },
                  child: const Text(
                    "تخطي",
                    style: TextStyle(
                        color: primaryColor),
                  ),
                ),
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
                    title: _onbordData[index].title,
                    description: _onbordData[index].description,
                    image: (Theme.of(context).brightness == Brightness.light &&
                            _onbordData[index].imageDarkTheme != null)
                        ? _onbordData[index].imageDarkTheme!
                        : _onbordData[index].image,
                    isTextOnTop: index.isOdd,
                  ),
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
    );
  }
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
