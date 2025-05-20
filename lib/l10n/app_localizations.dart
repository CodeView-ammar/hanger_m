import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @welcomeapp.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Muallaq app'**
  String get welcomeapp;

  /// No description provided for @welcomeapp_detils.
  ///
  /// In en, this message translates to:
  /// **'Through the application, you can book and deliver clothes from the laundromat to your home.'**
  String get welcomeapp_detils;

  /// No description provided for @search_laundries.
  ///
  /// In en, this message translates to:
  /// **'Search for laundries near you'**
  String get search_laundries;

  /// No description provided for @find_laundries_nearby.
  ///
  /// In en, this message translates to:
  /// **'Here you will find all laundries with their specific categories and know the nearest laundry to you.'**
  String get find_laundries_nearby;

  /// No description provided for @choose_laundry_and_clothes.
  ///
  /// In en, this message translates to:
  /// **'Choose the laundry and select the types of clothes you want to wash and put them in the basket.'**
  String get choose_laundry_and_clothes;

  /// No description provided for @choose_and_deliver.
  ///
  /// In en, this message translates to:
  /// **'Choose the laundry and select the types of clothes you want to wash and put them in the basket. Our delivery will reach you to pick them up and deliver them to the desired laundry.'**
  String get choose_and_deliver;

  /// No description provided for @quick_and_safe_payment.
  ///
  /// In en, this message translates to:
  /// **'Quick and Safe Payment'**
  String get quick_and_safe_payment;

  /// No description provided for @multiple_payment_options.
  ///
  /// In en, this message translates to:
  /// **'There are many payment options available for your convenience.'**
  String get multiple_payment_options;

  /// No description provided for @track_order.
  ///
  /// In en, this message translates to:
  /// **'Track Your Order'**
  String get track_order;

  /// No description provided for @manage_shipments.
  ///
  /// In en, this message translates to:
  /// **'In particular, the delivery service can handle your orders and help you manage your shipments smoothly.'**
  String get manage_shipments;

  /// No description provided for @nearby_laundries.
  ///
  /// In en, this message translates to:
  /// **'Nearby Laundries'**
  String get nearby_laundries;

  /// No description provided for @browse_and_get_info.
  ///
  /// In en, this message translates to:
  /// **'You can easily find laundries, browse their items, and get information about their services.'**
  String get browse_and_get_info;

  /// No description provided for @title_app.
  ///
  /// In en, this message translates to:
  /// **'معلاق لخدمات المغاسل'**
  String get title_app;

  /// No description provided for @searchLaundriesText.
  ///
  /// In en, this message translates to:
  /// **'Search for laundries \n near you'**
  String get searchLaundriesText;

  /// No description provided for @findLaundriesNearbyDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you will find all laundries with their respective categories and the closest laundry to you.'**
  String get findLaundriesNearbyDescription;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'home'**
  String get home;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'orders'**
  String get orders;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'bookmark'**
  String get bookmarks;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'profile'**
  String get profile;

  /// No description provided for @laundry.
  ///
  /// In en, this message translates to:
  /// **'laundry'**
  String get laundry;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'processing'**
  String get processing;

  /// No description provided for @delegates.
  ///
  /// In en, this message translates to:
  /// **'delegate'**
  String get delegates;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'recipient'**
  String get recipient;

  /// No description provided for @closest_you.
  ///
  /// In en, this message translates to:
  /// **'The closest to you'**
  String get closest_you;

  /// No description provided for @show_more.
  ///
  /// In en, this message translates to:
  /// **'read more'**
  String get show_more;

  /// No description provided for @order_list.
  ///
  /// In en, this message translates to:
  /// **'order list'**
  String get order_list;

  /// No description provided for @loding.
  ///
  /// In en, this message translates to:
  /// **'loding'**
  String get loding;

  /// No description provided for @wellcom_you.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get wellcom_you;

  /// No description provided for @loginAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Log in as guest'**
  String get loginAsGuest;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'log in'**
  String get login;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'welcome back'**
  String get welcomeBack;

  /// No description provided for @loginWithPhone.
  ///
  /// In en, this message translates to:
  /// **'login With Phone'**
  String get loginWithPhone;

  /// No description provided for @agreementMessage.
  ///
  /// In en, this message translates to:
  /// **'agreed to'**
  String get agreementMessage;

  /// No description provided for @privacypolicy.
  ///
  /// In en, this message translates to:
  /// **'privacy policy'**
  String get privacypolicy;

  /// No description provided for @numberphone.
  ///
  /// In en, this message translates to:
  /// **'number phone'**
  String get numberphone;

  /// No description provided for @meslogin.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to view orders'**
  String get meslogin;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'logout'**
  String get logout;

  /// No description provided for @paymentdetails.
  ///
  /// In en, this message translates to:
  /// **'payment details'**
  String get paymentdetails;

  /// No description provided for @notedelegate.
  ///
  /// In en, this message translates to:
  /// **'Note to the delegate'**
  String get notedelegate;

  /// No description provided for @exampledont.
  ///
  /// In en, this message translates to:
  /// **'Example: Don\'t ring the bell.'**
  String get exampledont;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get minute;

  /// No description provided for @expecteddeliverytime.
  ///
  /// In en, this message translates to:
  /// **'Expected delivery time'**
  String get expecteddeliverytime;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'choose'**
  String get choose;

  /// No description provided for @copmtut.
  ///
  /// In en, this message translates to:
  /// **'Choose an online payment method to use the available balance.'**
  String get copmtut;

  /// No description provided for @paymentmethods.
  ///
  /// In en, this message translates to:
  /// **'payment methods'**
  String get paymentmethods;

  /// No description provided for @pmbc.
  ///
  /// In en, this message translates to:
  /// **'Payment made by card'**
  String get pmbc;

  /// No description provided for @pur.
  ///
  /// In en, this message translates to:
  /// **'Payment upon receipt'**
  String get pur;

  /// No description provided for @ymsapm.
  ///
  /// In en, this message translates to:
  /// **'You must select a payment method.'**
  String get ymsapm;

  /// No description provided for @totaldemand.
  ///
  /// In en, this message translates to:
  /// **'Total demand'**
  String get totaldemand;

  /// No description provided for @notpaid.
  ///
  /// In en, this message translates to:
  /// **'Not paid'**
  String get notpaid;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'paid'**
  String get paid;

  /// No description provided for @subService.
  ///
  /// In en, this message translates to:
  /// **'Additional services'**
  String get subService;

  /// No description provided for @submitrequest.
  ///
  /// In en, this message translates to:
  /// **'Submit the request'**
  String get submitrequest;

  /// No description provided for @deliveryprice.
  ///
  /// In en, this message translates to:
  /// **'Delivery price'**
  String get deliveryprice;

  /// No description provided for @poloic.
  ///
  /// In en, this message translates to:
  /// **'Pay online later or in cash'**
  String get poloic;

  /// No description provided for @piaopettaotrrto.
  ///
  /// In en, this message translates to:
  /// **'Pay in cash or pay electronically through the app once the representative receives the order.'**
  String get piaopettaotrrto;

  /// No description provided for @ptaspumn.
  ///
  /// In en, this message translates to:
  /// **'Pay to a specific party using a mobile number'**
  String get ptaspumn;

  /// No description provided for @aanc.
  ///
  /// In en, this message translates to:
  /// **'Add a new card'**
  String get aanc;

  /// No description provided for @yhnac.
  ///
  /// In en, this message translates to:
  /// **'You have no added cards.'**
  String get yhnac;

  /// No description provided for @yrhbss.
  ///
  /// In en, this message translates to:
  /// **'Your request has been sent successfully!'**
  String get yrhbss;

  /// No description provided for @yohbssttl.
  ///
  /// In en, this message translates to:
  /// **'Your order has been successfully sent to the laundry.'**
  String get yohbssttl;

  /// No description provided for @changing.
  ///
  /// In en, this message translates to:
  /// **'changing'**
  String get changing;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'account'**
  String get account;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'requests'**
  String get requests;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'address'**
  String get address;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'wallet'**
  String get wallet;

  /// No description provided for @customize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get customize;

  /// No description provided for @languagechange.
  ///
  /// In en, this message translates to:
  /// **'language change'**
  String get languagechange;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'search'**
  String get search;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'location'**
  String get location;

  /// No description provided for @helpandsupport.
  ///
  /// In en, this message translates to:
  /// **'Help and support'**
  String get helpandsupport;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @serviceprice.
  ///
  /// In en, this message translates to:
  /// **'Service price'**
  String get serviceprice;

  /// No description provided for @sar.
  ///
  /// In en, this message translates to:
  /// **'SR'**
  String get sar;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @servicetype.
  ///
  /// In en, this message translates to:
  /// **'Service type:'**
  String get servicetype;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'qty'**
  String get qty;

  /// No description provided for @ordernow.
  ///
  /// In en, this message translates to:
  /// **'Order now'**
  String get ordernow;

  /// No description provided for @unitprice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get unitprice;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'price'**
  String get price;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @shoppingcart.
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get shoppingcart;

  /// No description provided for @continuetocheckout.
  ///
  /// In en, this message translates to:
  /// **'Continue to checkout'**
  String get continuetocheckout;

  /// No description provided for @oK.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get oK;

  /// No description provided for @thereisnospecificsink.
  ///
  /// In en, this message translates to:
  /// **'There is no specific sink'**
  String get thereisnospecificsink;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @reviewrequest.
  ///
  /// In en, this message translates to:
  /// **'Review the request'**
  String get reviewrequest;

  /// No description provided for @deliverydetails.
  ///
  /// In en, this message translates to:
  /// **'Delivery details'**
  String get deliverydetails;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
