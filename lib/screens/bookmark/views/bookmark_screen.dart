import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/components/product/laundries_cart.dart';
import 'package:http/http.dart' as http;
import 'package:melaq/route/route_constants.dart';
import 'dart:convert';
import 'package:melaq/l10n/app_localizations.dart';

import '../../../constants.dart';

// تعريف نموذج الخدمة (LaundryModel) مع إضافة id
class LaundryModel {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String? image;
  final String email;

  LaundryModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.image,
    required this.email,
  });

  // دالة لتحويل JSON إلى LaundryModel
  factory LaundryModel.fromJson(Map<String, dynamic> json) {
    return LaundryModel(
      id: json['id'],
      name: utf8.decode(json['name'].codeUnits),
      address: utf8.decode(json['address'].codeUnits),
      phone: json['phone'] ?? 'غير متوفر',
      image: json['image'],
      email: json['email'] ?? 'غير متوفر',
    );
  }
}

class BookmarkScreen extends StatefulWidget {
 final bool showAppBar; // المتغير الجديد
  final bool showBackButton; // متغير زر التراجع

  const BookmarkScreen({super.key, this.showAppBar = true, this.showBackButton = true});

  @override
  _BookmarkScreenState createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  late Future<List<LaundryModel>> _futureLaundries;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _futureLaundries = fetchProducts(); // جلب البيانات عند بدء التطبيق
  }

  // دالة لجلب المنتجات أو الخدمات من API
  Future<List<LaundryModel>> fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid');

      if (userId == null) {
        throw Exception("User ID is not found.");
      }

      final response = await http.get(Uri.parse('${APIConfig.markEndpoint_get}$userId/'));

      if (response.statusCode == 200) {
        // Decode the JSON response
        List<dynamic> jsonResponse = json.decode(response.body);

        // Initialize an empty list to store LaundryModel objects
        List<LaundryModel> laundries = [];

        for (var item in jsonResponse) {
          try {
            // Assuming 'laundry' is a key in the response to fetch more details
            final laundryResponse = await http.get(Uri.parse('${APIConfig.launderiesEndpoint}${item['laundry'].toString()}'));

            if (laundryResponse.statusCode == 200) {
              // Decode the laundry response
              var jsonLaundryResponse = json.decode(laundryResponse.body);

              // If the response is a list, process each item
              if (jsonLaundryResponse is List) {
                for (var laundryItem in jsonLaundryResponse) {
                  if (laundryItem is Map<String, dynamic>) {
                    // Map the laundry item data to LaundryModel
                    LaundryModel laundry = LaundryModel.fromJson(laundryItem);
                    laundries.add(laundry);
                  }
                }
              } else if (jsonLaundryResponse is Map<String, dynamic>) {
                LaundryModel laundry = LaundryModel.fromJson(jsonLaundryResponse);
                laundries.add(laundry);
              }
            } else {
              print('Error fetching laundry data: ${laundryResponse.statusCode}');
            }
          } catch (e) {
            print('Error during data processing: $e');
          }
        }

        setState(() {
          _isLoading = false;
        });
        return laundries;
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل في تحميل البيانات: ${response.statusCode}';
        });
        throw Exception();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '';
      });
      throw Exception('Error: $e');
    }
  }

  // دالة لحذف خدمة من المحفوظات
  Future<void> removeLaundry(int id, int userId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // إرسال الطلب لحذف 
      final response = await http.delete(Uri.parse('${APIConfig.markEndpoint_delete}$userId/$id/'));
      
      // التحقق من حالة الاستجابة
      if (response.statusCode == 204) {
        // عرض تأكيد الحذف
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                 Icon(Icons.check_circle, color: Colors.white),
                 SizedBox(width: 8),
                 Text('تم حذف المغسلة من المفضلة بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // إذا تم الحذف بنجاح، أعد تحميل المنتجات
        _futureLaundries = fetchProducts();
      } else {
        setState(() {
          _isLoading = false;
        });
        
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('فشل في حذف المغسلة من المفضلة'),
        //     backgroundColor: Colors.red,
        //     behavior: SnackBarBehavior.floating,
        //   ),
        // );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // دالة لعرض مربع حوار تأكيد الحذف
  void _showDeleteConfirmationDialog(LaundryModel laundry) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم العثور على بيانات المستخدم'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${laundry.name}" من المفضلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              removeLaundry(laundry.id, int.parse(userId));
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
        ? AppBar(
            title:  Text(AppLocalizations.of(context)!.bookmarks),
            elevation: 0,
            leading: widget.showBackButton // استخدام المتغير الجديد
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.of(context).pop(); // العودة إلى الشاشة السابقة
                    },
                  )
                : null,
          )
        : null, // عدم عرض AppBar إذا كان showAppBar غير مفعل
      body: RefreshIndicator(
        onRefresh: () async {
          _futureLaundries = fetchProducts();
          await _futureLaundries;
        },
        child: FutureBuilder<List<LaundryModel>>(
          future: _futureLaundries,
          builder: (context, snapshot) {
            // حالة التحميل
            if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحميل المفضلة...'),
                  ],
                ),
              );
            } 
            // حالة الخطأ
            else if (snapshot.hasError || _errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    // Text(
                    //   _errorMessage ?? 'حدث خطأ: ${snapshot.error}',
                    //   textAlign: TextAlign.center,
                    //   style: const TextStyle(color: Colors.red),
                    // ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _futureLaundries = fetchProducts();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('تحديث'),
                    ),
                  ],
                ),
              );
            } 
            // لا توجد بيانات
            else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 72,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد مغاسل في المفضلة',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يمكنك إضافة المغاسل المفضلة لديك هنا',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, homeScreenRoute);
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('استعرض المغاسل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final laundries = snapshot.data!;

            return Column(
              children: [
                // عنوان صفحة المفضلة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'المغاسل المفضلة (${laundries.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const Spacer(),
                      if (laundries.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, 
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_sweep,
                                color: Colors.red[400],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'اسحب للحذف',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[400],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                // قائمة المغاسل المفضلة
                Expanded(
                  child: laundries.isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          itemCount: laundries.length,
                          itemBuilder: (context, index) {
                            final laundry = laundries[index];
                            
                            return Dismissible(
                              key: Key('laundry-${laundry.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red[400],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'حذف',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                _showDeleteConfirmationDialog(laundry);
                                return false; // لا نريد حذفه بالسحب مباشرة، بل بعد التأكيد
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      productDetailsScreenRoute,
                                      arguments: {
                                        "isAvailable": true,
                                        "id": laundry.id,
                                      },
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        // صورة المغسلة
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.grey[200],
                                          ),
                                          child: laundry.image != null && laundry.image!.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    laundry.image!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => 
                                                      const Icon(Icons.local_laundry_service, size: 40),
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.local_laundry_service,
                                                  size: 40,
                                                ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // معلومات المغسلة
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                laundry.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      laundry.address,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 14,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.phone,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    laundry.phone,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // // زر الحذف
                                        // IconButton(
                                        //   onPressed: () => _showDeleteConfirmationDialog(laundry),
                                        //   icon: Icon(
                                        //     Icons.delete_outline,
                                        //     color: Colors.red[400],
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(), // لن يظهر هذا لأننا نعالج الحالة الفارغة أعلاه
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
