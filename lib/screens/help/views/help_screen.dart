import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:melaq/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/screens/support/views/support_screen.dart';

class HelpScreen extends StatefulWidget {
    final bool showAppBar; // المتغير الجديد
  final bool showBackButton; // متغير زر التراجع
  const HelpScreen({super.key,this.showAppBar=true,this.showBackButton=true});

  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  bool isTechHelpSelected = false;
  bool isGeneralHelpSelected = false;
  bool isOrderIssueSelected = false;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _userPhoneNumber;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userPhoneNumber = prefs.getString('userPhone');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("احصل على المساعدة"),
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // نص الترحيب مع تصميم محسن
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.support_agent, size: 36, color: primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'كيف يمكننا مساعدتك؟',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'فريق الدعم الخاص بنا متاح للمساعدة في حل جميع استفساراتك',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // عنوان لخيارات المساعدة
              Text(
                'نوع المساعدة التي تحتاجها:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // خيارات المساعدة في تصميم بطاقات
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: CheckboxListTile(
                  title: Row(
                    children: [
                      Icon(Icons.computer, color: primaryColor),
                      const SizedBox(width: 8),
                      const Text("المساعدة التقنية"),
                    ],
                  ),
                  subtitle: const Text("مشاكل في استخدام التطبيق أو مشاكل تقنية أخرى"),
                  value: isTechHelpSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      isTechHelpSelected = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: primaryColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: CheckboxListTile(
                  title: Row(
                    children: [
                      Icon(Icons.support, color: primaryColor),
                      const SizedBox(width: 8),
                      const Text("الدعم العام"),
                    ],
                  ),
                  subtitle: const Text("استفسارات عامة حول الخدمات والعمليات"),
                  value: isGeneralHelpSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      isGeneralHelpSelected = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: primaryColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: CheckboxListTile(
                  title: Row(
                    children: [
                      Icon(Icons.shopping_bag, color: primaryColor),
                      const SizedBox(width: 8),
                      const Text("مشكلة في الطلب"),
                    ],
                  ),
                  subtitle: const Text("مشكلة متعلقة بطلب سابق أو حالي"),
                  value: isOrderIssueSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      isOrderIssueSelected = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: primaryColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              
              const SizedBox(height: 20),

              // معلومات الاتصال
              _userPhoneNumber != null 
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("سنتواصل معك على:", style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(_userPhoneNumber!, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات الاتصال:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          labelText: 'الاسم',
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: const Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

              // رسالة المستخدم
              Text(
                'تفاصيل المشكلة أو الاستفسار:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              // حقل إدخال الرسالة المحسن
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'اشرح مشكلتك أو استفسارك بالتفصيل...',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 24),

              // أزرار المساعدة
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _sendHelpRequest(context),
                      icon: _isLoading 
                        ? Container(
                            width: 24, 
                            height: 24, 
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ) 
                        : const Icon(Icons.send),
                      label: Text(
                        _isLoading ? "جاري الإرسال..." : "إرسال طلب", 
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Expanded(
                  //   child: ElevatedButton.icon(
                  //     onPressed: () => _openSupportSystem(context),
                  //     icon: const Icon(Icons.support_agent),
                  //     label: const Text(
                  //       'الدعم الفني', 
                  //       style: TextStyle(fontSize: 14),
                  //     ),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.green,
                  //       foregroundColor: Colors.white,
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(12),
                  //       ),
                  //       elevation: 3,
                  //       padding: const EdgeInsets.symmetric(vertical: 12),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // طرق اتصال بديلة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اتصل بنا مباشرة:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.phone, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "+966 54 124 2726",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.email, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "support@melaq.sa",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لإرسال طلب المساعدة عبر النظام الجديد
  Future<void> _sendHelpRequest(BuildContext context) async {
    // التحقق من المحتوى
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة رسالتك قبل الإرسال'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // إذا لم يتم تحديد أي نوع مساعدة
    if (!isTechHelpSelected && !isGeneralHelpSelected && !isOrderIssueSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد نوع المساعدة المطلوبة'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // تحديد نوع التذكرة والأولوية
      String category = 'general';
      String priority = 'medium';
      String title = 'طلب مساعدة';

      if (isTechHelpSelected) {
        category = 'technical';
        title = 'مساعدة تقنية';
        priority = 'high';
      } else if (isOrderIssueSelected) {
        category = 'order';
        title = 'مشكلة في الطلب';
        priority = 'high';
      }

      // الحصول على معرف المستخدم
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid') ?? '';

      if (userId.isEmpty) {
        throw Exception('يرجى تسجيل الدخول أولاً');
      }

      // إنشاء تذكرة دعم فني جديدة
      final response = await http.post(
        Uri.parse(APIConfig.supportTicketsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user': int.parse(userId),
          'title': title,
          'category': category,
          'priority': priority,
          'initial_message': _messageController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        // تم إنشاء التذكرة بنجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('تم إنشاء تذكرة دعم فني بنجاح'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'عرض',
              textColor: Colors.white,
              onPressed: () => _openSupportSystem(context),
            ),
          ),
        );

        // إعادة تعيين الحقول
        _messageController.clear();
        setState(() {
          isTechHelpSelected = false;
          isGeneralHelpSelected = false;
          isOrderIssueSelected = false;
        });
      } else {
        throw Exception('فشل في إنشاء التذكرة');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // دالة لفتح نظام الدعم الفني
  void _openSupportSystem(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SupportScreen(),
      ),
    );
  }
}
