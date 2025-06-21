import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:melaq/constants.dart';

class DelegateNoteScreen extends StatelessWidget {
  const DelegateNoteScreen({Key? key, required String delegateNote}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController noteController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملاحظة المندوب'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أدخل ملاحظتك للمندوب:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 5, // عدد الأسطر المسموح بها
              key: const ValueKey('noteKey'), // استخدم مفتاحًا فريدًا
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'اكتب ملاحظتك هنا...',
                filled: true, // لملء الخلفية
                fillColor: Colors.grey[200], // لون خلفية خفيف
                contentPadding: const EdgeInsets.all(10), // حشو داخلي لراحة الاستخدام
              ),
            ),            
            const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
              onPressed: () {
                String note = noteController.text;
                if (note.isNotEmpty) {
                  // إرجاع الملاحظة إلى الشاشة الأصلية
                  Navigator.pop(context, note);
                } else {
                  // إذا كانت الملاحظة فارغة، يمكن عرض رسالة خطأ
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('من فضلك أدخل ملاحظة')),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
