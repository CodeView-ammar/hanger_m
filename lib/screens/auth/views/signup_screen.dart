// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:melaq/screens/auth/views/components/sign_up_form.dart';
// import 'package:melaq/route/route_constants.dart';

// import '../../../constants.dart';

// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({super.key});

//   @override
//   State<SignUpScreen> createState() => _SignUpScreenState();
// }

// class _SignUpScreenState extends State<SignUpScreen> {
//   final _formKey = GlobalKey<FormState>();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Image.asset(
//               "assets/images/signUp_dark.png",
//               height: MediaQuery.of(context).size.height * 0.35,
//               width: double.infinity,
//               fit: BoxFit.cover,
//             ),
//             Padding(
//               padding: const EdgeInsets.all(defaultPadding),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "لنبدأ!",
//                     style: Theme.of(context).textTheme.headlineSmall,
//                   ),
//                   const SizedBox(height: defaultPadding / 2),
//                   const Text(
//                     "الرجاء إدخال البيانات الصحيحة الخاصة بك من أجل إنشاء حساب.",
//                   ),
//                   const SizedBox(height: defaultPadding),
//                   SignUpForm(formKey: _formKey),
//                   const SizedBox(height: defaultPadding),
//                   Row(
//                     children: [
//                       Checkbox(
//                         onChanged: (value) {},
//                         value: false,
//                       ),
//                       Expanded(
//                         child: Text.rich(
//                           TextSpan(
//                             text: "وأنا أتفق مع",
//                             children: [
//                               TextSpan(
//                                 recognizer: TapGestureRecognizer()
//                                   ..onTap = () {
//                                     Navigator.pushNamed(
//                                         context, termsOfServicesScreenRoute);
//                                   },
//                                 text: " شروط الخدمة ",
//                                 style: const TextStyle(
//                                   color: primaryColor,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               const TextSpan(
//                                 text: "& سياسة الخصوصية.",
//                               ),
//                             ],
//                           ),
//                         ),
//                       )
//                     ],
//                   ),
//                   const SizedBox(height: defaultPadding * 2),
//                   ElevatedButton(
//                     onPressed: () {
//                       // There is 2 more screens while user complete their profile
//                       // afre sign up, it's available on the pro version get it now
//                       // 🔗 https://theflutterway.gumroad.com/l/fluttershop
//                       Navigator.pushNamed(context, entryPointScreenRoute);
//                     },
//                     child: const Text("يكمل"),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Text("هل لديك حساب؟"),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pushNamed(context, logInScreenRoute);
//                         },
//                         child: const Text("تسجيل الدخول"),
//                       )
//                     ],
//                   ),
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
