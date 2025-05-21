import 'dart:async';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/components/api_extintion/url_api.dart';
import 'dart:convert'; // لاستخدام json.decode
import 'package:shop/constants.dart';
import 'package:shop/l10n/app_localizations.dart';
import 'package:shop/l10n/language_helper.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/components/order_process.dart';

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
  String? _logoPath;
  // متغيرات لحالة الطلب
  OrderProcessStatus _orderStatus = OrderProcessStatus.done;
  OrderProcessStatus _processingStatus = OrderProcessStatus.notDoneYeat;
  OrderProcessStatus _packedStatus = OrderProcessStatus.notDoneYeat;
  OrderProcessStatus _shippedStatus = OrderProcessStatus.notDoneYeat;
  OrderProcessStatus _deliveredStatus = OrderProcessStatus.notDoneYeat;
  bool _isCanceled = false;
  String? _estimatedDeliveryTime;
  
  @override
  void initState() {
    super.initState();
    _startFetchingOrderStatus(); // بدء العملية لجلب حالة الطلب
    _loadLogo(); // تحميل اللوجو
    _fetchInitialOrderStatus(); // جلب حالة الطلب الأولية فوراً
  }

  @override
  void dispose() {
    _timer?.cancel(); // إلغاء المؤقت عند إغلاق الصفحة
    super.dispose();
  }

  // استدعاء الحالة الأولية عند بدء التطبيق
  Future<void> _fetchInitialOrderStatus() async {
    await _fetchOrderStatus(); // جلب حالة الطلب الأولية
  }

  void _startFetchingOrderStatus() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchOrderStatus(); // جلب حالة الطلب بشكل دوري
    });
  }

  Future<void> _fetchOrderStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userid');

    if (userId == null) {
      return;
    } else {
      try {
        final response = await http.get(Uri.parse('${APIConfig.orderstatusUrl}?user=$userId'));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          String? orderStatus = data['order_status']; // الحالة القادمة من الـ API
          String? estimatedTime = data['estimated_delivery_time']; // الوقت المتوقع للتسليم
          bool? isCanceled = data['is_canceled'] ?? false; // إذا كان الطلب ملغياً

          if (orderStatus != null) {
            // تحويل حالة الطلب النصية إلى حالات مكون تتبع الطلب
            final statuses = _getOrderProcessStatuses(orderStatus);
            
            setState(() {
              _orderStatus = statuses.orderStatus;
              _processingStatus = statuses.processingStatus;
              _packedStatus = statuses.packedStatus;
              _shippedStatus = statuses.shippedStatus;
              _deliveredStatus = statuses.deliveredStatus;
              _isCanceled = isCanceled ?? false;
              _estimatedDeliveryTime = estimatedTime;
              
              // تحديث الحالة في activeStep (للتوافق مع الكود القديم)
              activeStep = _getStepForStatus(orderStatus);
            });

          }
        } else {
          print("فشل في جلب حالة الطلب: ${response.statusCode}");
        }
      } catch (e) {
        print("حدث خطأ أثناء جلب حالة الطلب: $e");
      }
    }
  }

  // تحويل حالة الطلب النصية إلى حالات مكون تتبع الطلب
  ({
    OrderProcessStatus orderStatus,
    OrderProcessStatus processingStatus,
    OrderProcessStatus packedStatus,
    OrderProcessStatus shippedStatus,
    OrderProcessStatus deliveredStatus
  }) _getOrderProcessStatuses(String status) {
    switch (status) {
      case 'pending':
        return (
          orderStatus: OrderProcessStatus.done,
          processingStatus: OrderProcessStatus.processing,
          packedStatus: OrderProcessStatus.notDoneYeat,
          shippedStatus: OrderProcessStatus.notDoneYeat,
          deliveredStatus: OrderProcessStatus.notDoneYeat,
        );
      case 'courier_accepted':
        return (
          orderStatus: OrderProcessStatus.done,
          processingStatus: OrderProcessStatus.done,
          packedStatus: OrderProcessStatus.processing,
          shippedStatus: OrderProcessStatus.notDoneYeat,
          deliveredStatus: OrderProcessStatus.notDoneYeat,
        );
      case 'picked_up_from_customer':
        return (
          orderStatus: OrderProcessStatus.done,
          processingStatus: OrderProcessStatus.done,
          packedStatus: OrderProcessStatus.done,
          shippedStatus: OrderProcessStatus.processing,
          deliveredStatus: OrderProcessStatus.notDoneYeat,
        );
      case 'delivered_to_laundry':
        return (
          orderStatus: OrderProcessStatus.done,
          processingStatus: OrderProcessStatus.done,
          packedStatus: OrderProcessStatus.done,
          shippedStatus: OrderProcessStatus.done,
          deliveredStatus: OrderProcessStatus.done,
        );
      default:
        return (
          orderStatus: OrderProcessStatus.notDoneYeat,
          processingStatus: OrderProcessStatus.notDoneYeat,
          packedStatus: OrderProcessStatus.notDoneYeat,
          shippedStatus: OrderProcessStatus.notDoneYeat,
          deliveredStatus: OrderProcessStatus.notDoneYeat,
        );
    }
  }

  // دالة التوافق مع الكود القديم
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
  
    
  // دالة للتعامل مع النقر على خطوة في شريط الحالة
  void _onOrderStepTapped(int index) {
    // يمكن تنفيذ إجراءات إضافية عند النقر على خطوة معينة
    // مثل عرض تفاصيل تلك المرحلة
    print('تم النقر على الخطوة رقم: $index');
  }
    SvgPicture svgIcon(String src, {Color? color}) {
      return SvgPicture.asset(
        src,
        height: 24,
        colorFilter: ColorFilter.mode(
            color ?? Theme.of(context).iconTheme.color!.withOpacity(
                Theme.of(context).brightness == Brightness.light ? 0.3 : 1),
            BlendMode.srcIn),
      );
    }

  Future<void> _loadLogo() async {
    String currentLanguage = await LanguageHelper.getCurrentLanguage() ?? 'ar';
    setState(() {
      _logoPath = currentLanguage == 'ar'
          ? 'assets/logo/logo_arabic.svg'
          : 'assets/logo/logo_english.svg';
    });
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const SizedBox(),
        centerTitle: false,
        title: _logoPath == null
            ? const CircularProgressIndicator()
            : SvgPicture.asset(
                _logoPath!,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).iconTheme.color!,
                  BlendMode.srcIn,
                ),
                height: 20,
                width: 100,
              ),
        actions: [
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
          if (activeStep != 0) // إظهار شريط الحالة فقط عندما يكون هناك طلب نشط
            Container(
              padding: const EdgeInsets.all(defaultPadding / 2),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : const Color(0xFF101015),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان لشريط الحالة
                  // Padding(
                  //   padding: const EdgeInsets.only(
                  //     bottom: 8.0, 
                  //     right: 16.0, 
                  //     left: 16.0
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       Icon(
                  //         Icons.local_shipping_outlined,
                  //         color: primaryColor,
                  //         size: 16,
                  //       ),
                  //       const SizedBox(width: 8),
                  //       Text(
                  //         'حالة طلبك الحالي:',
                  //         style: TextStyle(
                  //           fontWeight: FontWeight.bold,
                  //           fontSize: 13,
                  //           color: Theme.of(context).textTheme.bodyMedium?.color,
                  //         ),
                  //       ),
                  //       const Spacer(),
                  //       GestureDetector(
                  //         onTap: () {
                  //           Navigator.pushNamed(context, ordersScreenRoute);
                  //         },
                  //         child: Text(
                  //           'تفاصيل الطلب',
                  //           style: TextStyle(
                  //             fontSize: 12,
                  //             color: primaryColor,
                  //             fontWeight: FontWeight.bold,
                  //             decoration: TextDecoration.underline,
                  //           ),
                  //         ),
                  //       ),
                  //       const SizedBox(width: 4),
                  //       Icon(
                  //         Icons.arrow_forward_ios,
                  //         size: 12,
                  //         color: primaryColor,
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  
                  // شريط حالة الطلب المحسّن
                  EnhancedOrderProgress(
                    orderStatus: _orderStatus,
                    processingStatus: _processingStatus,
                    packedStatus: _packedStatus,
                    shippedStatus: _shippedStatus, 
                    deliveredStatus: _deliveredStatus,
                    isCanceled: _isCanceled,
                    onStepTap: _onOrderStepTapped,
                    estimatedDeliveryTime: _estimatedDeliveryTime,
                    animationDuration: const Duration(milliseconds: 1200),
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
              label: AppLocalizations.of(context)!.home,
            ),
            BottomNavigationBarItem(
              icon: svgIcon("assets/icons/Category.svg", color: const Color.fromARGB(255, 255, 255, 255)),
              activeIcon: svgIcon("assets/icons/Category.svg", color: const Color.fromARGB(255, 255, 255, 255)),
              label: AppLocalizations.of(context)!.orders,
            ),
            BottomNavigationBarItem(
              icon: svgIcon("assets/icons/Bookmark.svg", color: const Color.fromARGB(255, 255, 255, 255)),
              activeIcon: svgIcon("assets/icons/Bookmark.svg", color: const Color.fromARGB(255, 255, 255, 255)),
              label: AppLocalizations.of(context)!.bookmarks,
            ),
            BottomNavigationBarItem(
              icon: svgIcon("assets/icons/Profile.svg", color: const Color.fromARGB(255, 255, 255, 255)),
              activeIcon: svgIcon("assets/icons/Profile.svg", color: const Color.fromARGB(255, 255, 255, 255)),
              label: AppLocalizations.of(context)!.profile,
            ),
          ],
        ),
      ),
    );
  }
}
