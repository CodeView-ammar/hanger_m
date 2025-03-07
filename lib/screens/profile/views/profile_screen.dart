import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/components/list_tile/divider_list_tile.dart';
import 'package:shop/constants.dart';
import 'package:shop/l10n/app_localizations.dart';
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
    // هنا يمكنك استخدام مكتبة للتحقق من صلاحيات الإشعارات
    // على سبيل المثال، إذا كنت تستخدم firebase_messaging:
    // final Messaging messaging = FirebaseMessaging.instance;
    // NotificationSettings settings = await messaging.requestPermission();
    // return settings.authorizationStatus == AuthorizationStatus.authorized;

    // في هذا المثال، سنقوم بإرجاع قيمة عشوائية (تغييرها بناءً على منطقك):
    return Future.value(true); // أو false حسب الحاجة
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
                          AppLocalizations.of(context)!.customize,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      DividerListTileWithTrilingText(
                        svgSrc: "assets/icons/Notification.svg",
                        title: AppLocalizations.of(context)!.notifications,
                        trilingText: isNotificationEnabled ? "On" : "Off", // تغيير النص بناءً على الحالة
                        press: () {
                          Navigator.pushNamed(context, enableNotificationScreenRoute);
                        },
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
                          userPhoneNumber.isEmpty ? AppLocalizations.of(context)!.login : AppLocalizations.of(context)!.logout,
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