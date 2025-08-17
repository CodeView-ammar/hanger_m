import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:melaq/chcek_connect.dart';
import 'package:melaq/l10n/app_localizations.dart';
import 'package:melaq/route/route_constants.dart';
import 'package:melaq/route/router.dart' as router;
import 'package:melaq/services/local_notification_service.dart';
import 'package:melaq/services/notification_service.dart';
import 'package:melaq/theme/app_theme.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // تهيئة Firebase Analytics
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
 await Future.wait({
    PushNotificationsService.init(),
    LocalNotificationService.init()
  });
  await dotenv.load(fileName: ".env");
  await initNotifications();
  
  runApp(
 const MyApp(),
  );
}
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

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
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _locationFetched = false;
  Locale _appLocale = const Locale('ar');

  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions(); // طلب صلاحيات الإشعارات
    _fetchLocation();
    _fetchLanguage();
  }

Future<void> _requestNotificationPermissions() async {
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
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

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

  Future<void> _fetchLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      Position position = await _getCurrentLocation();
      await prefs.setDouble('latitude', position.latitude);
      await prefs.setDouble('longitude', position.longitude);
      setState(() {
        _locationFetched = true;
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

  Future<void> _fetchLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('language_code');
    
    if (languageCode != null) {
      setState(() {
        _appLocale = Locale(languageCode);
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
      locale: _appLocale,
      supportedLocales: const [
        Locale('ar'), 
        Locale('en'), 
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first; 
      },
    );
  }
}