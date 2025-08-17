import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateResult {
  final bool updateAvailable;
  final bool forceUpdate;
  final String message;
  final String latestVersion;

  UpdateResult({
    required this.updateAvailable,
    required this.forceUpdate,
    required this.message,
    required this.latestVersion,
  });
}


class CheckUpdateService {
  static String baseUrl = APIConfig.checkUpdateEndpoint; // تأكد من أن هذا هو URL الصحيح للتحقق من التحديث

Future<UpdateResult?> checkAppVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final platform = Platform.isAndroid ? "android" : "ios";
  final currentVersion = packageInfo.version; // Use your app version dynamically
  final url = "$baseUrl?platform=$platform&current_version=$currentVersion&type_app=hangermain";
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);


      return UpdateResult(
        updateAvailable: data['update'],
        forceUpdate: data['force_update'] == true || data['force_update'] == 1,
        message: data['message'] ?? '',
        latestVersion: data['latest_version'] ?? '',
      
      );

  }
}
}



