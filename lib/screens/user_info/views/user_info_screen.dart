import 'package:flutter/material.dart';
import 'package:melaq/route/route_constants.dart';
import 'package:melaq/screens/user_info/views/edit_user_info_screen.dart';

class UserInfoScreen extends StatelessWidget {
  const UserInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            // Handle back button press
            Navigator.pop(context);
          },
        ),
        title: const Text('الملف الشخصي'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, editUserInfoScreenRoute);
            },
            child: const Text('تعديل'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage('https://example.com/user_avatar.jpg'), // Replace with actual image URL
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('عفيف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('ammarwadood@gmail.com', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildProfileItem('الاسم', 'عمار'),
            _buildProfileItem('تاريخ الميلاد', 'Oct 31, 1997'),
            _buildProfileItem('رقم الجوال', '+966-553259885'),
            _buildProfileItem('الجنس', 'رجل'),
            _buildProfileItem('الايميل', 'ammarwadood@gmail.com'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}