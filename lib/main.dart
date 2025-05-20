import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shop/l10n/app_localizations.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/route/router.dart' as router;
import 'package:shop/theme/app_theme.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
  initNotifications();  // تهيئة الإشعارات عند بداية التطبيق
}

class RestartWidget extends StatefulWidget {
  final Widget child;
  const RestartWidget({Key? key, required this.child}) : super(key: key);

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  _RestartWidgetState createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: widget.child,
    );
  }
}

// إنشاء مثيل من FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  
  // تخصيص إعدادات iOS بشكل صحيح
  const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    defaultPresentAlert: true,
    defaultPresentSound: true,
    defaultPresentBadge: true,
    defaultPresentBanner: true,
    defaultPresentList: true,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS, // تم تخصيص iOS هنا
  );
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _locationFetched = false;
  Locale _appLocale = const Locale('ar'); // اللغة الافتراضية العربية

  @override
  void initState() {
    super.initState();
    runApp(const RestartWidget(child: MyApp()));
    _fetchLocation(); // استدعاء دالة جلب الموقع عند بداية التطبيق
    _fetchLanguage(); // جلب اللغة من الكاش
  }

  Future<void> _fetchLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      Position position = await _getCurrentLocation();
      await prefs.setDouble('latitude', position.latitude);
      await prefs.setDouble('longitude', position.longitude);
      setState(() {
        _locationFetched = true; // تحديث الحالة بعد جلب الموقع
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // جلب اللغة من الكاش
  Future<void> _fetchLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('language_code');
    
    if (languageCode != null) {
      setState(() {
        _appLocale = Locale(languageCode); // تعيين اللغة من الكاش إذا كانت موجودة
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppLocalizations.of(context)?.title_app ?? 'Laundry App',
      theme: AppTheme.lightTheme(context),
      themeMode: ThemeMode.light,
      onGenerateRoute: router.generateRoute,
      initialRoute: SplashScreenRoute,
      locale: _appLocale, // استخدام اللغة من الكاش أو الافتراضي
      supportedLocales: const [
        Locale('ar'), 
        Locale('en'), 
      ],
       localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: (locale, supportedLocales) {
        // إذا كانت اللغة موجودة في supportedLocales، استخدمها
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first; // اللغة الافتراضية
      },
    );
  }
}
