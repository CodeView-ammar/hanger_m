import 'package:flutter/material.dart';

class InstructionsScreen extends StatelessWidget {
  
  final bool showAppBar; // المتغير الجديد
  final bool showBackButton; // متغير زر التراجع
  const InstructionsScreen({super.key,this.showAppBar=true,this.showBackButton=true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تعليمات نظام معلق"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان الرئيسي
            const Text(
              'كيفية استخدام تطبيق معلق',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // المقدمة
            const Text(
              'نظام معلق هو تطبيق يتيح لك توصيل الطلبات بناءً على المغسلة الأقرب إليك. اتبع الخطوات التالية لإتمام طلبك:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            // الخطوة 1: اختيار المغسلة
            _buildInstructionStep(
              'الخطوة 1: اختيار المغسلة',
              'في البداية، اختر المغسلة الأقرب إليك من القائمة المعروضة. التطبيق سيعرض لك المغاسل القريبة بناءً على موقعك الحالي.',
              Icons.location_on,
            ),
            const SizedBox(height: 20),

            // الخطوة 2: اختيار الخدمات
            _buildInstructionStep(
              'الخطوة 2: اختيار الخدمات',
              'بعد اختيار المغسلة، حدد الخدمات التي ترغب في الحصول عليها. تشمل الخيارات مثل التنظيف الجاف، الغسيل العادي، كي الملابس، وغيرها.',
              Icons.settings,
            ),
            const SizedBox(height: 20),

            // الخطوة 3: اختيار طريقة الدفع
            _buildInstructionStep(
              'الخطوة 3: اختيار طريقة الدفع',
              'بعد تحديد الخدمات، اختر طريقة الدفع المفضلة لديك. يمكن الدفع عبر البطاقة الائتمانية أو وسائل الدفع الرقمية المتاحة.',
              Icons.payment,
            ),
            const SizedBox(height: 20),

            // الخطوة 4: إتمام عملية الدفع
            _buildInstructionStep(
              'الخطوة 4: إتمام عملية الدفع',
              'بعد اختيار طريقة الدفع، قم بتأكيد الطلب وقم بإتمام عملية الدفع. بمجرد الدفع، سيتم إرسال طلبك للمغسلة المختارة.',
              Icons.check_circle,
            ),
            const SizedBox(height: 20),

            // الختام
            const Text(
              'بمجرد إتمام جميع الخطوات، سيتم توصيل طلبك إلى المغسلة وسيتم إعلامك بحالة الطلب. نتمنى لك تجربة رائعة مع تطبيق معلق!',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // دالة لبناء خطوة التعليمات
  Widget _buildInstructionStep(String stepTitle, String stepDescription, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // أيقونة الخطوة
        Icon(icon, size: 40, color: Colors.blue),
        const SizedBox(width: 10),

        // عنوان النص والوصف
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stepTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                stepDescription,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
