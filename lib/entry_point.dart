import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:melaq/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'dart:convert';
import 'package:melaq/constants.dart';
import 'package:melaq/l10n/app_localizations.dart';
import 'package:melaq/l10n/language_helper.dart';
import 'package:melaq/route/screen_export.dart';
import 'package:melaq/components/order_process.dart';
import 'package:melaq/widgets/notification_badge.dart';
import 'dart:async';
import 'package:animations/animations.dart';

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  final List _pages = const [
    HomeScreen(),
    OrderScreen(showBackButton: false,showAppBar: false),
    BookmarkScreen(showBackButton: false,showAppBar: false),
    ProfileScreen(),
  ];
  int _currentIndex = 0;
  int activeStep = 0;
  Timer? _timer;
  String? _logoPath;
  OrderProcessStatus _orderStatus = OrderProcessStatus.done;
  OrderProcessStatus _processingStatus = OrderProcessStatus.notDoneYeat;
  OrderProcessStatus _packedStatus = OrderProcessStatus.notDoneYeat;
  OrderProcessStatus _shippedStatus = OrderProcessStatus.notDoneYeat;
  OrderProcessStatus _deliveredStatus = OrderProcessStatus.notDoneYeat;
  bool _isCanceled = false;
  String? _estimatedDeliveryTime;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _startFetchingOrderStatus();
    _loadLogo();
    _fetchInitialOrderStatus();
    // _fetchUnreadCount();
    // _startUnreadCountTimer();
    // NotificationService.initNotifications(); // تهيئة الإشعارات
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startUnreadCountTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      // _fetchUnreadCount();
    });
  }

  Future<void> _fetchInitialOrderStatus() async {
    await _fetchOrderStatus();
  }

  void _startFetchingOrderStatus() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchOrderStatus();
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
          String? orderStatus = data['order_status'];
          String? estimatedTime = data['estimated_delivery_time'];
          bool? isCanceled = data['is_canceled'] ?? false;

          if (orderStatus != null) {
            final statuses = _getOrderProcessStatuses(orderStatus);
            
            setState(() {
              _orderStatus = statuses.orderStatus;
              _processingStatus = statuses.processingStatus;
              _packedStatus = statuses.packedStatus;
              _shippedStatus = statuses.shippedStatus;
              _deliveredStatus = statuses.deliveredStatus;
              _isCanceled = isCanceled ?? false;
              _estimatedDeliveryTime = estimatedTime;
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

  int _getStepForStatus(String status) {
    switch (status) {
      case 'pending':
        return 1;
      case 'courier_accepted':
        return 2;
      case 'picked_up_from_customer':
        return 3;
      case 'delivered_to_laundry':
        return 0;
      default:
        return 0;
    }
  }
  
  void _onOrderStepTapped(int index) {
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

  // Future<void> _fetchUnreadCount() async {
  //   final userId = await NotificationService.getUserId();
  //   if (userId.isNotEmpty) {
  //     final count = await NotificationService.getUnreadNotificationsCount(userId);
  //     if (mounted) {
  //       setState(() {
  //         _unreadNotificationCount = count;
  //       });
  //     }
      // NotificationService.startListeningForNewNotifications();
      // إذا كان هناك إشعار غير مقروء، يتم عرض إشعار
      // if (count > 0) {
        // print("aa");
        // await NotificationService.showNotification(
        //   'إشعار جديد',
        //   'لديك $count إشعارات غير مقروءة',
        // );
      // }
  //   }
  // }

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
          NotificationBadge(
            unreadCount: _unreadNotificationCount,
            onTap: () async {
              await Navigator.pushNamed(context, notificationsScreenRoute);
            },
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, notificationsScreenRoute);
              },
              icon: svgIcon("assets/icons/Notification.svg"),
            ),
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