import 'package:shared_preferences/shared_preferences.dart';

class GetUser {
  // Method to check if the user is found in SharedPreferences
  Future<bool> isUserFound() async {
    // Get instance of SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Check for the user key (change 'userKey' to your actual key)
    return prefs.containsKey('userId');
  }

  // Method to get user data (if needed)
  Future<String?> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Retrieve user data (change 'userKey' to your actual key)
    return prefs.getString('userId');
  }
}
