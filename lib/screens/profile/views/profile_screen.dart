import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/components/list_tile/divider_list_tile.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/l10n/app_localizations.dart';
import 'package:melaq/l10n/language_helper.dart';
import 'package:melaq/main.dart';
import 'package:melaq/route/screen_export.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'components/profile_card.dart';
import 'components/profile_menu_item_list_tile.dart';

late BuildContext _context;
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});



  Future<String> getUserPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userPhone') ?? '';  // إرجاع رقم الهاتف المحفوظ
  }

  Future<bool> checkNotificationPermission() async {
    // هنا يمكن استخدام مكتبة للتحقق من صلاحيات الإشعارات
    return Future.value(true); // مثال على إرجاع قيمة ثابتة
  }

  void changeLanguage(BuildContext context) async {
    String? currentLanguage = await LanguageHelper.getCurrentLanguage();

    // تحديد اللغة الجديدة بناءً على اللغة الحالية
    String newLanguage = (currentLanguage == 'en') ? 'ar' : 'en';

    // حفظ اللغة الجديدة في الكاش
    await LanguageHelper.setLanguage(newLanguage);

    // إعادة تشغيل التطبيق فقط إذا كانت الـ widget ما زالت موجودة في الـ tree
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

  // تحقق أن الواجهة لا تزال فعالة بعد await
  
  if (response.statusCode == 204) {
    return true;
  } else {
    return false;
    }
  
}

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String>(
        future: getUserPhoneNumber(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            String userPhoneNumber = snapshot.data!;
            return FutureBuilder<bool>(
              future: checkNotificationPermission(),
              builder: (context, notificationSnapshot) {
                if (notificationSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (notificationSnapshot.hasError) {
                  return Center(child: Text('Error: ${notificationSnapshot.error}'));
                } else if (notificationSnapshot.hasData) {
                  bool isNotificationEnabled = notificationSnapshot.data!;

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
                                    Navigator.pushNamed(context, userInfoScreenRoute);
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
                                          "طلباتي",
                                          onTap: () => Navigator.pushNamed(
                                            context, ordersScreenRoute),
                                        ),
                                        const SizedBox(width: 12),
                                        _buildInfoCard(
                                          context,
                                          Icons.favorite_border,
                                          "المفضلة",
                                          onTap: () => Navigator.pushNamed(
                                            context, bookmarkScreenRoute),
                                        ),
                                        const SizedBox(width: 12),
                                        _buildInfoCard(
                                          context,
                                          Icons.location_on_outlined,
                                          "عناويني",
                                          onTap: () => Navigator.pushNamed(
                                            context, addressesScreenRoute),
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
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  ProfileMenuListTile(
                                    text: AppLocalizations.of(context)!.requests,
                                    svgSrc: "assets/icons/Order.svg",
                                    press: () {
                                      Navigator.pushNamed(context, ordersScreenRoute);
                                    },
                                  ),
                                  ProfileMenuListTile(
                                    text: AppLocalizations.of(context)!.address,
                                    svgSrc: "assets/icons/Address.svg",
                                    press: () {
                                      Navigator.pushNamed(context, addressesScreenRoute);
                                    },
                                  ),
                                  ProfileMenuListTile(
                                    text: AppLocalizations.of(context)!.wallet,
                                    svgSrc: "assets/icons/Wallet.svg",
                                    press: () {
                                      Navigator.pushNamed(context, walletScreenRoute);
                                    },
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
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const CircularProgressIndicator(
                                            strokeWidth: 2,
                                          );
                                        } else {
                                          String currentLanguage = snapshot.data ?? 'ar';
                                          return Row(
                                            children: [
                                              Text(
                                                "تغيير اللغة إلى:",
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12, 
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: primaryColor,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  currentLanguage == 'ar' ? 'الإنجليزية' : 'العربية',
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
                                      Icon(
                                        Icons.headset_mic,
                                        color: primaryColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.of(context)!.helpandsupport,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  ProfileMenuListTile(
                                    text: "التواصل مع الدعم الفني",
                                    svgSrc: "assets/icons/Chat.svg",
                                    press: () {
                                      Navigator.pushNamed(context, supportChatScreenRoute);
                                    },
                                  ),
                                  
                                  ProfileMenuListTile(
                                    text: AppLocalizations.of(context)!.helpandsupport,
                                    svgSrc: "assets/icons/Help.svg",
                                    press: () {
                                      Navigator.pushNamed(context, getHelpScreenRoute);
                                    },
                                  ),
                                  
                                  ProfileMenuListTile(
                                    text: AppLocalizations.of(context)!.instructions,
                                    svgSrc: "assets/icons/FAQ.svg",
                                    press: () {
                                      Navigator.pushNamed(context, instructionsScreenRoute);
                                    },
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
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                if (userPhoneNumber.isEmpty) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    logInScreenRoute,
                                    (route) => false,
                                  );
                                } else {
                                  // عرض تأكيد الخروج
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("تأكيد تسجيل الخروج"),
                                      content: const Text("هل أنت متأكد من رغبتك في تسجيل الخروج؟"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("إلغاء"),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await prefs.clear();
                                            if (context.mounted) {
                                              Navigator.pop(context); // إغلاق الحوار
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
                                color: userPhoneNumber.isEmpty ? Colors.green : errorColor,
                              ),
                              label: Text(
                                userPhoneNumber.isEmpty
                                  ? AppLocalizations.of(context)!.login
                                  : AppLocalizations.of(context)!.logout,
                                style: TextStyle(
                                  color: userPhoneNumber.isEmpty ? Colors.green : errorColor,
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
                          SliverToBoxAdapter(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: defaultPadding),
                                            child: ElevatedButton(
                                              onPressed: () {
                                                // عرض تأكيد الحذف
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text("تأكيد حذف الحساب"),
                                                    content: const Text("هل أنت متأكد أنك تريد حذف الحساب؟ هذا الإجراء لا يمكن التراجع عنه."),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context), // إلغاء
                                                        child: const Text("إلغاء"),
                                                      ),
                                                      TextButton(
                                                       onPressed: () async {
                                                        bool isDeleted = await deleteUser();

                                                          Navigator.pop(context);
                                                        if (isDeleted) {
                                                          // if (context.mounted) return;
                                                          Navigator.pushNamedAndRemoveUntil(
                                                            context,
                                                            logInScreenRoute,
                                                            (route) => false,
                                                          );

                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('تم حذف الحساب بنجاح')),
                                                          );
                                                        } else {
                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(content: Text('فشل حذف الحساب')),
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
                                                backgroundColor: Colors.red, // لون الزر
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                              ),
                                            ),
                                          ),
                                        ),

                        // معلومات التطبيق
                        SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: 24, 
                                top: 8,
                              ),
                              child: Text(
                                "نسخة التطبيق: 2.0.5",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Center(child: Text('No data found.'));
                }
              },
            );
          } else {
            return const Center(child: Text('No data found.'));
          }
        },
      ),
    );
  }
  
  Widget _buildInfoCard(BuildContext context, IconData icon, String text, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: primaryColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}