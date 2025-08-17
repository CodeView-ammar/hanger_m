import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              'سياسة الخصوصية',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'نحن نأخذ حماية خصوصيتك على محمل الجد. في هذه السياسة، نشرح كيف نقوم بجمع واستخدام وحماية المعلومات الخاصة بك.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              '1. جمع المعلومات:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'نقوم بجمع المعلومات التالية عند استخدامك لتطبيقنا:\n\n- رقم الهاتف المحمول الخاص بك.\n- الموقع الجغرافي الخاص بك (عند السماح لنا بالوصول إلى الموقع).',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              '2. استخدام المعلومات:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'نستخدم المعلومات التي نجمعها لتحسين تجربة المستخدم في تطبيقنا. نستخدم رقم الهاتف لتسجيل الدخول وتقديم الدعم. كما نستخدم الموقع الجغرافي لتحسين الخدمة المقدمة لك.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              '3. حماية المعلومات:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'نحن نحرص على حماية بياناتك الشخصية باستخدام أفضل أساليب الأمان المتاحة، ولكن لا يمكننا ضمان الأمان التام عند نقل البيانات عبر الإنترنت.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              '4. التعديلات على سياسة الخصوصية:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'قد نقوم بتعديل سياسة الخصوصية هذه من وقت لآخر. سيتم نشر أي تغييرات على هذه الصفحة، وستمثل هذه التعديلات سارية فور نشرها.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              '5. قبول سياسة الخصوصية:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'باستخدامك لتطبيقنا، فإنك توافق على جمع واستخدام المعلومات كما هو موضح في هذه السياسة.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
