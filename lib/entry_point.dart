import 'dart:async';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'dart:convert'; // لاستخدام json.decode
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:easy_stepper/easy_stepper.dart';

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  final List _pages = const [
    HomeScreen(),
    OrderScreen(),
    BookmarkScreen(),
    ProfileScreen(),
  ];


  int _currentIndex = 0;
  int activeStep = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startFetchingOrderStatus(); // بدء العملية لجلب حالة الطلب
  
  }

  @override
  void dispose() {
    _timer?.cancel(); // إلغاء المؤقت عند إغلاق الصفحة
    super.dispose();
  }

  void _startFetchingOrderStatus() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchOrderStatus(); // جلب حالة الطلب كل 5 ثواني
    });
  }

  Future<void> _fetchOrderStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userid');

    if (userId == null) {
      // Navigator.pushNamed(context, logInScreenRoute);
      return;
    }else{
    final response = await http.get(Uri.parse('${APIConfig.orderstatusUrl}?user=$userId'));

    if (response.statusCode == 200) {
      // افترض أن الاستجابة هي JSON تحتوي على حالة الطلب
      final data = json.decode(response.body);
      
      // استخدام المفتاح الصحيح
      String? orderStatus = data['order_status']; // الحالة القادمة من الـ API

      // تحقق من أن orderStatus ليست null
      if (orderStatus != null) {
        // تحويل حالة الطلب إلى الرقم المناسب للـ EasyStepper
        int step = _getStepForStatus(orderStatus);

        setState(() {
          activeStep = step; // تحديث الحالة بناءً على الاستجابة
        });
      } else {
        print("حالة الطلب غير متاحة");
      }
    } 
    }
  }

  // تعديل الدالة لتشمل الحالات الجديدة
  int _getStepForStatus(String status) {
    switch (status) {
      case 'pending':
        return 1; // في انتظار المعالجة
      case 'courier_accepted':
        return 2; // المندوب في الطريق
      case 'picked_up_from_customer':
        return 3; // تم أخذها من العميل
      case 'delivered_to_laundry':
        return 0; // تم تسليمها إلى المغسلة
      default:
        return 0; // حالة افتراضية
    }
  }

  @override
  Widget build(BuildContext context) {
    SvgPicture svgIcon(String src, {Color? color}) {
      return SvgPicture.asset(
        src,
        height: 24, // تصغير حجم الأيقونات
        colorFilter: ColorFilter.mode(
            color ?? Theme.of(context).iconTheme.color!.withOpacity(
                Theme.of(context).brightness == Brightness.light ? 0.3 : 1),
            BlendMode.srcIn),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const SizedBox(),
        centerTitle: false,
        title: SvgPicture.asset(
          "assets/logo/logo.svg",
          colorFilter: ColorFilter.mode(
              Theme.of(context).iconTheme.color!, BlendMode.srcIn),
          height: 20,
          width: 100,
        ),
        actions: [
          // IconButton(
          //   onPressed: () {
          //     setState(() {
          //       _currentIndex = 1;
          //     });
          //   },
          //   icon: svgIcon("assets/icons/Search.svg"),
          // ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, addressesScreenRoute);
            },
            icon: svgIcon("assets/icons/Location.svg"),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, notificationsScreenRoute);
            },
            icon: svgIcon("assets/icons/Notification.svg"),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                PageTransitionSwitcher(
                  duration: defaultDuration,
                  transitionBuilder: (child, animation, secondAnimation) {
                    return FadeThroughTransition(
                      animation: animation,
                      secondaryAnimation: secondAnimation,
                      child: child,
                    );
                  },
                  child: _pages[_currentIndex],
                ),
              ],
            ),
          ),
          // إخفاء حالة الطلب إذا كانت 0
          if (activeStep != 0)
            Container(
              padding: const EdgeInsets.only(top: defaultPadding / 2),
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : const Color(0xFF101015),
                
              child: EasyStepper(
                onStepReached: null,
                activeStep: activeStep,
                stepShape: StepShape.rRectangle,
                stepBorderRadius: 15,
                borderThickness: 4,
                stepRadius: 20,
                finishedStepBorderColor: primaryColor,
                finishedStepTextColor: primaryColor,
                finishedStepBackgroundColor: primaryColor,
                activeStepIconColor: primaryColor,
                showLoadingAnimation: false,
                steps: [
                  EasyStep(
                    customStep: AnimatedOpacity(
                      duration: Duration(milliseconds: 300),
                      opacity: activeStep >= 0 ? 1 : 0.3,
                      child: Icon(Icons.watch_later, size: 20), // أيقونة pending
                    ),
                    customTitle: const Text(
                      'المعالجة',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  EasyStep(
                    customStep: AnimatedOpacity(
                      duration: Duration(milliseconds: 300),
                      opacity: activeStep >= 1 ? 1 : 0.3,
                      child: Icon(Icons.local_shipping, size: 20), // أيقونة المندوب في الطريق
                    ),
                    customTitle: const Text(
                      'المندوب',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  EasyStep(
                    customStep: AnimatedOpacity(
                      duration: Duration(milliseconds: 300),
                      opacity: activeStep >= 2 ? 1 : 0.3,
                      child: Icon(Icons.check_circle, size: 20), // تم أخذها من العميل
                    ),
                    customTitle: const Text(
                      'مستلم',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  EasyStep(
                    customStep: AnimatedOpacity(
                      duration: Duration(milliseconds: 300),
                      opacity: activeStep >= 3 ? 1 : 0.3,
                      child: Icon(Icons.local_laundry_service, size: 20), // المغسلة استلمت الطلب
                    ),
                    customTitle: const Text(
                      'المغسلة',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: defaultPadding / 2),
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : primaryColor,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index != _currentIndex) {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? primaryColor
              : primaryColor,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 15,
          selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
          unselectedItemColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.3),
          items: [
            BottomNavigationBarItem(
              icon: svgIcon("assets/icons/Shop.svg", color: const Color.fromARGB(255, 255, 255, 255)),
              activeIcon: svgIcon("assets/icons/Shop.svg", color: const Color.fromARGB(255, 255, 255, 255)),
              label: "الرئيسي",
            ),
            BottomNavigationBarItem(
              icon: svgIcon("assets/icons/Category.svg",color: const Color.fromARGB(255, 255, 255, 255)),
              activeIcon: svgIcon("assets/icons/Category.svg", color: const Color.fromARGB(255, 255, 255, 255)),
              label: "الطلبات",
            ),
            BottomNavigationBarItem(
              icon: svgIcon("assets/icons/Bookmark.svg",color: const Color.fromARGB(255, 255, 255, 255)),
              activeIcon: svgIcon("assets/icons/Bookmark.svg", color: const Color.fromARGB(255, 255, 255, 255)),
              label: "المحفوظات",
            ),
            BottomNavigationBarItem(
              icon: svgIcon("assets/icons/Profile.svg",color: const Color.fromARGB(255, 255, 255, 255)),
              activeIcon: svgIcon("assets/icons/Profile.svg", color: const Color.fromARGB(255, 255, 255, 255)),
              label: "ملفي",
            ),
          ],
        ),
      ),
    );
  }
}
