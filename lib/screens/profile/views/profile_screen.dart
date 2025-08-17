
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/components/list_tile/divider_list_tile.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/l10n/app_localizations.dart';
import 'package:melaq/l10n/language_helper.dart';
import 'package:melaq/main.dart';
import 'package:melaq/route/screen_export.dart';
import 'package:melaq/screens/help/views/instructions_screen.dart';
import 'package:melaq/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'components/profile_card.dart';
import 'components/profile_menu_item_list_tile.dart';
import 'package:permission_handler/permission_handler.dart';

late BuildContext _context;

// تعداد للشاشات المختلفة
enum ProfileScreenView {
  main,
  orders,
  favorites,
  addresses,
  wallet,
  support,
  help,
  instructions,
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  bool _isNotificationEnabled = false;
  ProfileScreenView _currentView = ProfileScreenView.main;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkAndSetNotificationPermission();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToView(ProfileScreenView view) {
    setState(() {
      _currentView = view;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _navigateBack() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentView = ProfileScreenView.main;
        });
      }
    });
  }

  Future<void> _checkAndSetNotificationPermission() async {
    bool status = await checkNotificationPermission();
    setState(() {
      _isNotificationEnabled = status;
    });
  }

  Future<String> getUserPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userPhone') ?? '';
  }

  Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  void changeLanguage(BuildContext context) async {
    String? currentLanguage = await LanguageHelper.getCurrentLanguage();
    String newLanguage = (currentLanguage == 'en') ? 'ar' : 'en';
    await LanguageHelper.setLanguage(newLanguage);

    if (context.mounted) {
      RestartWidget.restartApp(context);
    }
  }

  Future<bool> deleteUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userId = await prefs.getString('userid');

    if (userId == null) {
      return false;
    }

    final response = await http.delete(
      Uri.parse('${APIConfig.useraddEndpoint}$userId/'),
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> requestNotificationPermissions() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        if (result.isGranted) {
          print("تم منح صلاحيات الإشعارات على Android");
        } else {
          print("تم رفض صلاحيات الإشعارات على Android");
        }
      }
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      final IOSFlutterLocalNotificationsPlugin? iosPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final bool? result = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        if (result == true) {
          print("تم منح صلاحيات الإشعارات على iOS");
        } else {
          print("تم رفض صلاحيات الإشعارات على iOS");
        }
      }
    }
  }

  Widget _buildMainView(String userPhoneNumber) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Profile Card
                  ProfileCard(
                    name: userPhoneNumber,
                    imageSrc: "",
                    press: () {
                      // Navigator.pushReplacementNamed(context, userInfoScreenRoute);
                    },
                  ),
                  if (userPhoneNumber.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 16, left: 16, right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoCard(
                            context,
                            Icons.shopping_bag_outlined,
                            AppLocalizations.of(context)!.requests,
                            onTap: () => _navigateToView(ProfileScreenView.orders),
                          ),
                          const SizedBox(width: 12),
                          _buildInfoCard(
                            context,
                            Icons.favorite_border,
                            "المفضلة",
                            onTap: () => _navigateToView(ProfileScreenView.favorites),
                          ),
                          const SizedBox(width: 12),
                          _buildInfoCard(
                            context,
                            Icons.location_on_outlined,
                            AppLocalizations.of(context)!.address,
                            onTap: () => _navigateToView(ProfileScreenView.addresses),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // منطقة الحساب
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: defaultPadding * 0.5,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.account,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ProfileMenuListTile(
                      text: AppLocalizations.of(context)!.requests,
                      svgSrc: "assets/icons/Order.svg",
                      press: () => _navigateToView(ProfileScreenView.orders),
                    ),
                    ProfileMenuListTile(
                      text: AppLocalizations.of(context)!.address,
                      svgSrc: "assets/icons/Address.svg",
                      press: () => _navigateToView(ProfileScreenView.addresses),
                    ),
                    ProfileMenuListTile(
                      text: AppLocalizations.of(context)!.wallet,
                      svgSrc: "assets/icons/Wallet.svg",
                      press: () => _navigateToView(ProfileScreenView.wallet),
                      isShowDivider: false,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // منطقة اللغة
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: defaultPadding * 0.5,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.language,
                          color: primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.languagechange,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      onTap: () => changeLanguage(context),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.translate,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      title: FutureBuilder<String?>(
                        future: LanguageHelper.getCurrentLanguage(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator(
                              strokeWidth: 2,
                            );
                          } else {
                            String currentLanguage =
                                snapshot.data ?? 'ar';
                            return Row(
                              children: [
                                Text(
                                  "تغيير اللغة إلى:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    currentLanguage == 'ar'
                                        ? 'الإنجليزية'
                                        : 'العربية',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // منطقة الإشعارات
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_active,
                            color: primaryColor),
                        const SizedBox(width: 10),
                        Text(
                          "الاشعارات",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    Switch(
                      value: _isNotificationEnabled,
                      activeColor: primaryColor,
                      onChanged: (value) async {
                        if (value) {
                          await requestNotificationPermissions();
                        } else {
                          openAppSettings();
                        }
                        bool updatedStatus =
                            await checkNotificationPermission();
                        setState(() {
                          _isNotificationEnabled = updatedStatus;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // منطقة الدعم
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: defaultPadding * 0.5,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                       const Icon(
                          Icons.headset_mic,
                          color: primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.helpandsupport,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ProfileMenuListTile(
                      text: "التواصل مع الدعم الفني",
                      svgSrc: "assets/icons/Chat.svg",
                      press: () => _navigateToView(ProfileScreenView.support),
                    ),
                    ProfileMenuListTile(
                      text: AppLocalizations.of(context)!.helpandsupport,
                      svgSrc: "assets/icons/Help.svg",
                      press: () => _navigateToView(ProfileScreenView.help),
                    ),
                    ProfileMenuListTile(
                      text: AppLocalizations.of(context)!.instructions,
                      svgSrc: "assets/icons/FAQ.svg",
                      press: () => _navigateToView(ProfileScreenView.instructions),
                      isShowDivider: false,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // زر تسجيل الخروج
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: defaultPadding,
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  if (userPhoneNumber.isEmpty) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      logInScreenRoute,
                      (route) => false,
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("تأكيد تسجيل الخروج"),
                        content: const Text(
                            "هل أنت متأكد من رغبتك في تسجيل الخروج؟"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("إلغاء"),
                          ),
                          TextButton(
                            onPressed: () async {
                              await prefs.clear();
                              if (context.mounted) {
                                Navigator.pop(context);
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  logInScreenRoute,
                                  (route) => false,
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: errorColor,
                            ),
                            child: const Text("تسجيل الخروج"),
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: Icon(
                  userPhoneNumber.isEmpty ? Icons.login : Icons.logout,
                  color: userPhoneNumber.isEmpty
                      ? Colors.green
                      : errorColor,
                ),
                label: Text(
                  userPhoneNumber.isEmpty
                      ? AppLocalizations.of(context)!.login
                      : AppLocalizations.of(context)!.logout,
                  style: TextStyle(
                    color: userPhoneNumber.isEmpty
                        ? Colors.green
                        : errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: userPhoneNumber.isEmpty
                      ? Colors.green.withOpacity(0.1)
                      : errorColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // زر حذف الحساب
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding,
                  vertical: defaultPadding),
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("تأكيد حذف الحساب"),
                      content: const Text(
                          "هل أنت متأكد أنك تريد حذف الحساب؟ هذا الإجراء لا يمكن التراجع عنه."),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context),
                          child: const Text("إلغاء"),
                        ),
                        TextButton(
                          onPressed: () async {
                            bool isDeleted = await deleteUser();

                            Navigator.pop(context);
                            if (isDeleted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                logInScreenRoute,
                                (route) => false,
                              );

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'تم حذف الحساب بنجاح')),
                              );
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('فشل حذف الحساب')),
                                );
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: errorColor,
                          ),
                          child: const Text("حذف الحساب"),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text("حذف الحساب"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildSubView(ProfileScreenView view) {
  String title = "";
  Widget content = Container();

  switch (view) {
    case ProfileScreenView.orders:
      title = AppLocalizations.of(context)!.requests;
      content = _buildOrdersContent();
      break;
    case ProfileScreenView.favorites:
      title = "المفضلة";
      content = _buildFavoritesContent();
      break;
    case ProfileScreenView.addresses:
      title = AppLocalizations.of(context)!.address;
      content = _buildAddressesContent();
      break;
    case ProfileScreenView.wallet:
      title = AppLocalizations.of(context)!.wallet;
      content = _buildWalletContent();
      break;
    case ProfileScreenView.support:
      title = "التواصل مع الدعم الفني";
      content = _buildSupportContent();
      break;
    case ProfileScreenView.help:
      title = AppLocalizations.of(context)!.helpandsupport;
      content = _buildHelpContent();
      break;
    case ProfileScreenView.instructions:
      title = AppLocalizations.of(context)!.instructions;
      content = _buildInstructionsContent();
      break;
    default:
      break;
  }

  return Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: _navigateBack, // استدعاء الدالة هنا
      ),
      centerTitle: true,
    ),
    body: SlideTransition(
      position: _slideAnimation,
      child: content,
    ),
  );
}
  Widget _buildOrdersContent() {
    return const OrderScreen(showAppBar: false,showBackButton: false);
  }

  Widget _buildFavoritesContent() {
    return const BookmarkScreen(showAppBar: false,showBackButton: false);
  }

  Widget _buildAddressesContent() {
    return const AddressesScreen(showAppBar: false,showBackButton: false);
  }

  Widget _buildWalletContent() {
    return const WalletScreen(showBackButton: false,showAppBar: false);
  }

  Widget _buildSupportContent() {
    return const SupportChatScreen(showBackButton: false, showAppBar: false);
  }

  Widget _buildHelpContent() {
    return const HelpScreen(showBackButton: false, showAppBar: false);
  }

  Widget _buildInstructionsContent() {
    return const InstructionsScreen(showBackButton: false, showAppBar: false);
  }

@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      // استدعاء _navigateBack عند الضغط على زر الرجوع في الهاتف
      _navigateBack();
      return false; // إلغاء العملية الافتراضية
    },
    child: Scaffold(
      body: FutureBuilder<String>(
        future: getUserPhoneNumber(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            String userPhoneNumber = snapshot.data!;

            if (_currentView == ProfileScreenView.main) {
              return _buildMainView(userPhoneNumber);
            } else {
              return _buildSubView(_currentView);
            }
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    ),
  );
}
  Widget _buildInfoCard(BuildContext context, IconData icon, String text,
      {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: primaryColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
