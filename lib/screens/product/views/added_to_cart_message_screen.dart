import 'package:flutter/material.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/screens/checkout/views/cart_screen.dart';

class AddedToCartMessageScreen extends StatelessWidget {
  final int laundryId;  // تحديد النوع كـ final لضمان أنه لا يتغير بعد تمريره

  // التأكد من أن laundryId ليس null بإعطائه قيمة افتراضية
  const AddedToCartMessageScreen({super.key, required this.laundryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                Theme.of(context).brightness == Brightness.light
                    ? "assets/images/logo_white.png"
                    : "assets/images/logo_white.png",
                height: MediaQuery.of(context).size.height * 0.3,
              ),
              const Spacer(flex: 2),
              Text(
                "اضافة للسلة",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: defaultPadding / 2),
              const Text(
                "انقر على زر المواصلة لإكمال عملية الطلب.",
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: () {
                  // إغلاق شاشة AddedToCartMessageScreen و BottomSheet
                  Navigator.pop(context); // إغلاق الشاشة الحالية (AddedToCartMessageScreen)
                  Navigator.pop(context); // إغلاق الـ BottomSheet المفتوح
                },
                child: const Text("مواصلة"),
              ),
              const SizedBox(height: defaultPadding),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: () {
                  // منطق إنهاء الطلب
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(),
                      settings: RouteSettings(
                        arguments: {
                          'id': laundryId, // تمرير الـ id هنا
                          // إذا كان لديك متغيرات أخرى مثل distance و duration، تأكد من تعريفها في الكلاس
                        },
                      ),
                    ),
                  );
                },
                child: const Text("إنهاء الطلب"),
              ),
              const SizedBox(height: defaultPadding),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}