import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';  // حزمة لاختيار الصور من الجهاز
import 'dart:io';

import 'package:melaq/components/api_extintion/otp_api.dart';
import 'package:melaq/l10n/app_localizations.dart';
import 'package:melaq/screens/auth/views/otp_screen.dart'; // لاستعراض الصور المحفوظة على الجهاز

class EditUserInfoScreen extends StatefulWidget {
  const EditUserInfoScreen({super.key});

  @override
  State<EditUserInfoScreen> createState() => _EditUserInfoScreenState();
}

class _EditUserInfoScreenState extends State<EditUserInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  File? _image; // متغير لحفظ الصورة المحددة
  final ImagePicker _picker = ImagePicker(); // لالتقاط الصور من جهاز المستخدم

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
      ),
      body: SingleChildScrollView(  // إضافة ScrollView للسماح بالتمرير
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عرض صورة المستخدم الحالية أو الصورة التي اختارها
              GestureDetector(
                onTap: _pickImage, // استدعاء دالة اختيار الصورة عند الضغط على الصورة
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _image == null
                      ? NetworkImage('https://example.com/user_image.jpg') // صورة افتراضية
                      : FileImage(_image!) as ImageProvider, // صورة محلية مختارة
                ),
              ),
              const SizedBox(height: 16),
              
              // تعديل الاسم
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              const SizedBox(height: 16),

              // تعديل الإيميل
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'الإيميل'),
              ),
              const SizedBox(height: 16),

              // تعديل رقم الجوال
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'رقم الجوال'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // تعديل تاريخ الميلاد
              TextField(
                controller: _dobController,
                decoration: const InputDecoration(labelText: 'تاريخ الميلاد'),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 16),

              // زر حفظ التغييرات
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لاختيار الصورة من الجهاز
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // تحديث الصورة
      });
    }
  }

  // دالة لحفظ التغييرات
  Future<void> _saveChanges() async {
    // الحصول على القيم من الحقول
    String name = _nameController.text;
    String email = _emailController.text;
    String phoneNumber = _phoneController.text;
    String dob = _dobController.text;

    // تحقق من أن رقم الجوال غير فارغ
    if (phoneNumber.isNotEmpty) {
      var sendOTP = AuthService();  // تأكد من أنك قمت بإنشاء AuthService وتفعيلها
      bool success = await sendOTP.sendOTP(phoneNumber);  // إرسال OTP

      if (success) {
        // الانتقال إلى شاشة التحقق من OTP
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOTPScreen(phone: phoneNumber),
          ),
        );
      } else {
        // عرض رسالة خطأ إذا فشل إرسال OTP
        _showErrorDialog("فشل في إرسال OTP، حاول مرة أخرى.");
      }
    } else {
      // إذا كان رقم الجوال فارغًا، عرض رسالة خطأ
      _showErrorDialog("يرجى إدخال رقم الجوال");
    }

    // يمكن إضافة المزيد من الإجراءات هنا لحفظ البيانات في السيرفر أو في التخزين المحلي
  }

  // دالة لعرض رسالة الخطأ
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('خطأ'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();  // إغلاق نافذة الخطأ
              },
              child:  Text(AppLocalizations.of(context)!.oK),
            ),
          ],
        );
      },
    );
  }
}
