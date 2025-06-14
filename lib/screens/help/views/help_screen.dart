import 'package:flutter/material.dart';
import 'package:melaq/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

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

              // زر إرسال المساعدة
              SizedBox(
                width: double.infinity,
                height: 50,
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
                    _isLoading ? "جاري الإرسال..." : "إرسال طلب المساعدة", 
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
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
                          "+966 xxx xxx xxxx",
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
                          "support@example.com",
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

  // دالة لإرسال طلب المساعدة
  void _sendHelpRequest(BuildContext context) {
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

    // تنفيذ عملية الإرسال مع مؤشر التحميل
    setState(() {
      _isLoading = true;
    });

    // محاكاة عملية إرسال البيانات
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });

      // إظهار رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('تم إرسال طلب المساعدة بنجاح، سنتواصل معك قريباً'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      // إعادة تعيين الحقول بعد الإرسال
      _messageController.clear();
      setState(() {
        isTechHelpSelected = false;
        isGeneralHelpSelected = false;
        isOrderIssueSelected = false;
      });
    });
  }
}
