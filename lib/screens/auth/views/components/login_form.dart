import 'package:flutter/material.dart';
import 'package:melaq/l10n/app_localizations.dart';
import '../../../../constants.dart';

class LogInForm extends StatelessWidget {

  const LogInForm({
    super.key,
    required this.formKey,
    required this.onPhoneSaved, // دالة لحفظ الرقم
  });

  final GlobalKey<FormState> formKey;
  final Function(String) onPhoneSaved; // دالة لتحفظ الرقم المدخل

  @override
  Widget build(BuildContext context) {

    return Form(
      key: formKey,
      child: Column(
        children: [
          Row(
            children: [
              // مفتاح الدولة
              
              Expanded(
                child: TextFormField(
                    onSaved: (phone) {
                        if (phone != null) {
                          // التحقق إذا كان الرقم يبدأ بـ "05"
                          if (phone.startsWith("05")) {
                            // إزالة الصفر الأول
                            phone = phone.substring(1);
                            
                          }
                          // دمج مفتاح الدولة مع الرقم المدخل
                          onPhoneSaved("+966$phone"); // حفظ الرقم كاملاً
                        }
                      },

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال رقم الجوال';
                    }
                    if (value.length != 9 && value.length != 10) {
                      return 'يجب أن يكون الرقم مكوناً من 9 أرقام';
                    }
                    return null;
                  },
                  
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  decoration:  InputDecoration(
                    hintText: AppLocalizations.of(context)!.numberphone,
                  ),
                ),
              ),
            
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: DropdownButton<String>(
                  value: '966+', // مثال: مفتاح الدولة للمملكة العربية السعودية
                  items: <String>['966+'] 
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    // يمكنك إضافة منطق لتخزين مفتاح الدولة المحدد
                  },
                  underline: const SizedBox(), // لإخفاء الخط السفلي
                ),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
        ],
      ),
    );
  }
}
