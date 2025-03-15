import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/components/list_tile/divider_list_tile.dart';
import 'package:shop/constants.dart';
import 'package:shop/l10n/app_localizations.dart';
import 'package:shop/l10n/language_helper.dart';
import 'package:shop/main.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/profile_card.dart';
import 'components/profile_menu_item_list_tile.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String>(
        future: getUserPhoneNumber(),  // استدعاء الدالة غير المتزامنة للحصول على رقم الهاتف
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            String userPhoneNumber = snapshot.data!;
            return FutureBuilder<bool>(
              future: checkNotificationPermission(),
              builder: (context, notificationSnapshot) {
                if (notificationSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (notificationSnapshot.hasError) {
                  return Center(child: Text('Error: ${notificationSnapshot.error}'));
                } else if (notificationSnapshot.hasData) {
                  bool isNotificationEnabled = notificationSnapshot.data!;

                  return ListView(
                    children: [
                      ProfileCard(
                        name: userPhoneNumber,
                        imageSrc: "",
                        press: () {
                          Navigator.pushNamed(context, userInfoScreenRoute);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: defaultPadding, vertical: defaultPadding * 1.5),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                        child: Text(
                          AppLocalizations.of(context)!.account,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: defaultPadding / 2),
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
                      ),
                      const SizedBox(height: defaultPadding),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: defaultPadding, vertical: defaultPadding / 2),
                        child: Text(
                          AppLocalizations.of(context)!.languagechange,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          changeLanguage(context);
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.language,  // أيقونة اللغة
                              color: primaryColor, // لون الأيقونة
                            ),
                            const SizedBox(width: 8), // المسافة بين الأيقونة والكلمة
                            FutureBuilder<String?>(
                              future: LanguageHelper.getCurrentLanguage(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else {
                                  String currentLanguage = snapshot.data ?? 'ar';
                                  return Text(
                                    currentLanguage == 'ar' ? 'الإنجليزية' : 'العربية',
                                    style: const TextStyle(color: primaryColor),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: defaultPadding),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: defaultPadding, vertical: defaultPadding / 2),
                        child: Text(
                          AppLocalizations.of(context)!.settings,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      ProfileMenuListTile(
                        text: AppLocalizations.of(context)!.location,
                        svgSrc: "assets/icons/Location.svg",
                        press: () {},
                      ),
                      const SizedBox(height: defaultPadding),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: defaultPadding, vertical: defaultPadding / 2),
                        child: Text(
                          AppLocalizations.of(context)!.helpandsupport,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
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
                      const SizedBox(height: defaultPadding),
                      ListTile(
                        onTap: () async {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          if (userPhoneNumber.isEmpty) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              logInScreenRoute,
                              (route) => false,
                            );
                          } else {
                            await prefs.clear();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              logInScreenRoute,
                              (route) => false,
                            );
                          }
                        },
                        minLeadingWidth: 24,
                        leading: SvgPicture.asset(
                          userPhoneNumber.isEmpty
                              ? "assets/icons/login.svg"
                              : "assets/icons/Logout.svg",
                          height: 24,
                          width: 24,
                          colorFilter: ColorFilter.mode(
                            userPhoneNumber.isEmpty ? Colors.green : errorColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        title: Text(
                          userPhoneNumber.isEmpty
                              ? AppLocalizations.of(context)!.login
                              : AppLocalizations.of(context)!.logout,
                          style: TextStyle(
                            color: userPhoneNumber.isEmpty ? Colors.green : errorColor,
                            fontSize: 14,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Center(child: Text('No data found.'));
                }
              },
            );
          } else {
            return Center(child: Text('No data found.'));
          }
        },
      ),
    );
  }
}