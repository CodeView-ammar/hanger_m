import 'dart:convert';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:melaq/models/review_model.dart';
import 'package:melaq/screens/product/views/components/reviev_widget.dart';
import 'package:melaq/services/review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/components/cart_button.dart';
import 'package:melaq/components/custom_messages.dart';
import 'package:melaq/components/custom_modal_bottom_sheet.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/screens/checkout/views/cart_screen.dart';
import 'package:melaq/screens/product/views/components/product_images.dart';
import 'package:melaq/screens/product/views/components/service_info.dart';
import 'package:melaq/screens/product/views/map_screen_laundry.dart';
import 'package:melaq/screens/product/views/product_buy_now_screen.dart';

// نموذج البيانات للخدمة
class ServiceModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final double urgentPrice;
  final String image;

  ServiceModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.urgentPrice,
    required this.image,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      name: utf8.decode(json['name'].codeUnits),
      description: json['description'],
      price: double.parse(json['price']),
      urgentPrice: double.parse(json['urgent_price']),
      image: json['image'] ?? '',
    );
  }
}

// نموذج البيانات للتصنيف
class CategoryModel {
  final int id;
  final String name;

  CategoryModel({required this.id, required this.name});
}

class ProductDetailsScreen extends StatefulWidget {
  final bool isAvailable;
  final int id;
  final String name;
  final String image;
  final String address;
  final double latitude;
  final double longitude;
  final double distance;
  final String duration;

  const ProductDetailsScreen({
    super.key,
    required this.id,
    required this.isAvailable,
    required this.name,
    required this.image,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.duration,
  });

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _CategoriesHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _CategoriesHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(_CategoriesHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  List<ServiceModel> _services = [];
  List<CategoryModel> _categories = [];
  double totalPrice = 0.0;
  int? selectedCategory;
  
  // حالات التحميل والأخطاء
  bool isLoadingServices = true;
  bool isLoadingCategories = true;
  bool hasServicesError = false;
  bool hasCategoriesError = false;
  String? servicesErrorMessage;
  String? categoriesErrorMessage;
  bool isLoadingReviews = true;
  LaundryReviewStats? reviewStats;

  bool _isFavorited = false; // حالة لتتبع المفضلة


  @override
  void initState() {
    super.initState();
    selectedCategory = 0;
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _loadCategories(),
      _loadServices(),
      fetchTotalPrice(widget.id),
    _loadReviews(),
// _checkIfFavorited(),
    ]);
  }

   Future<void> _checkIfFavorited() async {
    // تحقق من وجود المغسلة في المفضلة هنا
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');

    if (userId != null) {
      // قم بإجراء طلب للتحقق من المفضلة
      // (يمكنك تعديل هذا الجزء حسب الحاجة)
      // مثال: إذا كانت لديك قائمة مفضلة مخزنة
      List<String> favorites = prefs.getStringList('favorites') ?? [];
      setState(() {
        _isFavorited = favorites.contains(widget.id);
      });
    }
  }
  Future<void> _loadReviews() async {
    try {
      final reviews = await ReviewService.getLaundryReviews(widget.id);
      setState(() {
        reviewStats = reviews;
        isLoadingReviews = false;
      });
    } catch (e) {
      setState(() => isLoadingReviews = false);
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      isLoadingCategories = true;
      hasCategoriesError = false;
      categoriesErrorMessage = null;
    });

    try {
      final categories = await fetchCategories(widget.id);
      if (mounted) {
        setState(() {
          _categories = categories;
          isLoadingCategories = false;
          hasCategoriesError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingCategories = false;
          hasCategoriesError = true;
          categoriesErrorMessage = e.toString();
          _categories = [CategoryModel(id: 0, name: "الكل")]; // إضافة تصنيف افتراضي
        });
      }
    }
  }

  Future<void> _loadServices() async {
    setState(() {
      isLoadingServices = true;
      hasServicesError = false;
      servicesErrorMessage = null;
    });

    try {
      await fetchServices(widget.id, selectedCategory);
      if (mounted) {
        setState(() {
          isLoadingServices = false;
          hasServicesError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingServices = false;
          hasServicesError = true;
          servicesErrorMessage = e.toString();
        });
      }
    }
  }

  Future<void> fetchTotalPrice(int serverid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid');
      final response = await http.get(Uri.parse('${APIConfig.cartfilterEndpoint}?user=$userId&laundry=$serverid'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            totalPrice = (data['total_price'] is int) 
                ? (data['total_price'] as int).toDouble() 
                : (data['total_price'] ?? 0.0);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            totalPrice = 0.0;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          totalPrice = 0.0;
        });
      }
    }
  }

  Future<void> fetchServices(int id, int? category) async {
    String url = '${APIConfig.servicesEndpoint}?laundry_id=$id';
    if (category != null && category != 0) {
      url += '&category=$category';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          _services = data.map((item) => ServiceModel.fromJson(item['service'])).toList();
        });
      }
    } else {
      throw Exception('فشل في تحميل الخدمات - كود الخطأ: ${response.statusCode}');
    }
  }

  Future<void> saveLaundryData(String laundry) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userid');
    
    if (userId == null) {
      AppMessageService().showWarningMessage(
        context, 
        'يجب تسجيل الدخول أولاً لإضافة المغسلة إلى المفضلة',
        duration: const Duration(seconds: 4),
      );
      return;
    }

    final url = APIConfig.markerEndpoint;
    final body = json.encode({
      'user': userId,
      'laundry': int.parse(laundry),
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      if (context.mounted) Navigator.of(context).pop();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        AppMessageService().showSuccessMessage(
          context, 
          'تم إضافة المغسلة إلى المفضلة بنجاح'
        );
        _isFavorited = true; 
      } else if (response.statusCode == 400) {
        AppMessageService().showInfoMessage(
          context, 
          'هذه المغسلة موجودة بالفعل في المفضلة'
        );
      } else {
        AppMessageService().showErrorMessage(
          context, 
          'فشل في إضافة المغسلة إلى المفضلة. حاول مرة أخرى لاحقاً.',
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused')) {
        AppMessageService().showNoInternetMessage(context, onRetry: () {
          saveLaundryData(laundry);
        });
      } else {
        AppMessageService().showErrorMessage(
          context, 
          'حدث خطأ أثناء الاتصال بالخادم: ${e.toString().substring(0, Math.min(50, e.toString().length))}...'
        );
      }
    }
  }

  Future<List<CategoryModel>> fetchCategories(int id) async {
    try {
      final response = await http.get(Uri.parse('${APIConfig.categoriesEndpoint}?laundry_id=$id'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<CategoryModel> categories = List<CategoryModel>.from(
          data.map((item) => CategoryModel(
            id: item['id'],
            name: utf8.decode(item['name'].codeUnits),
          ))
        );

        categories.insert(0, CategoryModel(id: 0, name: "الكل"));
        return categories;
      } else {
        throw Exception('فشل في جلب التصنيفات - كود الخطأ: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: ${e.toString()}');
    }
  }

  void showCustomBottomSheet(BuildContext context, ServiceModel service, int quantity) async {
    await customModalBottomSheet(
      context,
      height: MediaQuery.of(context).size.height * 0.92,
      child: ProductBuyNowScreen(
        serviceId: service.id,
        serviceName: service.name,
        servicePrice: service.price * quantity,
        serveiceUrgentPrice: service.urgentPrice * quantity,
        serviceImage: service.image,
        quantity: quantity,
        laundry: widget.id,
        distance: widget.distance,
        duration: widget.duration,
      ),
    );

    await fetchTotalPrice(widget.id);
  }

  void filterServices(int categoryId) {
    setState(() {
      selectedCategory = categoryId;
    });
    _loadServices();
  }

  Widget _buildErrorRetryWidget({
    required String message,
    required VoidCallback onRetry,
    String? title,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 32,
          ),
          const SizedBox(height: 12),
          if (title != null) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            _getErrorMessage(message),
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(String error) {
    if (error.contains('SocketException') || 
        error.contains('Connection refused') ||
        error.contains('Network')) {
      return 'يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى';
    }
    
    if (error.contains('timeout')) {
      return 'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى';
    }
    
    if (error.contains('404')) {
      return 'الخدمة غير متوفرة حالياً';
    }
    
    if (error.contains('500')) {
      return 'خطأ في الخادم، يرجى المحاولة لاحقاً';
    }
    
    return 'حدث خطأ في تحميل البيانات';
  }
// 2. دالة لحساب الارتفاع الديناميكي
double _calculateCategoriesHeight() {
  if (isLoadingCategories || hasCategoriesError) {
    return 100.0; // ارتفاع ثابت للحالات الخاصة
  }
  return 110.0; // ارتفاع ثابت للعرض العادي
}
// 3. الويدجت المعدلة
Widget _buildCategoriesSection() {
  if (isLoadingCategories) {
    return _buildLoadingState();
  }

  if (hasCategoriesError) {
    return _buildErrorState();
  }

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // _buildSectionHeader(),
        const SizedBox(height: 8),
        _buildCategoriesList(),
      ],
    ),
  );
}

// 4. ويدجت حالة التحميل
Widget _buildLoadingState() {
  return Container(
    height: 100,
    padding: const EdgeInsets.all(16),
    child: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(height: 8),
          Text(
            'جاري تحميل التصنيفات...',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}

// 5. ويدجت حالة الخطأ
Widget _buildErrorState() {
  return Container(
    height: 100,
    padding: const EdgeInsets.all(16),
    child: _buildErrorRetryWidget(
      title: 'خطأ في تحميل التصنيفات',
      message: categoriesErrorMessage ?? 'حدث خطأ غير متوقع',
      onRetry: _loadCategories,
    ),
  );
}

// 6. ويدجت رأس القسم
Widget _buildSectionHeader() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.category,
            color: primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'اختر التصنيف',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (_categories.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_categories.length} تصنيف',
              style: TextStyle(
                fontSize: 12,
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    ),
  );
}

// 7. ويدجت قائمة التصنيفات
Widget _buildCategoriesList() {
  return SizedBox(
    height: 50, // ارتفاع مناسب لجميع الأجهزة
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isSelected = selectedCategory == category.id;
        
        return _buildCategoryItem(category, isSelected);
      },
    ),
  );
}

// 8. ويدجت عنصر التصنيف
Widget _buildCategoryItem(CategoryModel category, bool isSelected) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => filterServices(category.id),
      child: Container(
        constraints: const BoxConstraints(minWidth: 100),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon(
            //   _getCategoryIcon(category.name),
            //   color: isSelected ? Colors.white : primaryColor,
            //   size: 18,
            // ),
            // const SizedBox(width: 8),
            Flexible(
              child: Text(
                category.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
IconData _getCategoryIcon(String categoryName) {
    // أيقونات مخصصة حسب اسم التصنيف
    switch (categoryName.toLowerCase()) {
      case 'الكل':
        return Icons.apps;
      case 'غسيل':
      case 'غسيل ملابس':
        return Icons.local_laundry_service;
      case 'كي':
      case 'كوي':
        return Icons.iron;
      case 'تنظيف جاف':
        return Icons.dry_cleaning;
      case 'ملابس رسمية':
        return Icons.business_center;
      case 'ملابس رياضية':
        return Icons.sports;
      case 'أحذية':
        return Icons.shower;
      case 'ستائر':
        return Icons.curtains;
      case 'سجاد':
        return Icons.carpenter;
      case 'مفروشات':
        return Icons.bed;
      default:
        return Icons.category;
    }
  }

  Widget _buildServicesSection() {
    if (isLoadingServices) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              // SizedBox(height: 10),
              Text(
                'جاري تحميل الخدمات...',
                style: TextStyle(fontSize: 6),
              ),
            ],
          ),
        ),
      );
    }

    if (hasServicesError) {
      return SliverFillRemaining(
        child: Center(
          child: _buildErrorRetryWidget(
            title: 'خطأ في تحميل الخدمات',
            message: servicesErrorMessage ?? 'خطأ غير محدد',
            onRetry: _loadServices,
          ),
        ),
      );
    }

    if (_services.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد خدمات متاحة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لا توجد خدمات في هذا التصنيف حالياً',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => filterServices(0),
                  icon: const Icon(Icons.refresh),
                  label: const Text('عرض جميع الخدمات'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final service = _services[index];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => showCustomBottomSheet(context, service, 1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // صورة الخدمة
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            service.image.isEmpty 
                                ? '${APIConfig.static_baseUrl}/images/store.jpg' 
                                : service.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey.shade400,
                                  size: 30,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // تفاصيل الخدمة
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ر.س ${service.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                if (service.urgentPrice != service.price) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'ر.س${service.urgentPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // زر الإضافة
                      Container(
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => showCustomBottomSheet(context, service, 1),
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        childCount: _services.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
        final double averageRating = reviewStats?.averageRating ?? 0.0;
    final int totalReviews = reviewStats?.totalReviews ?? 0;

    return Scaffold(
      bottomNavigationBar: CartButton(
        price: totalPrice,
        press: () async {
          if (totalPrice == 0.0) {
            AppMessageService().showWarningMessage(
              context, 
              'لا يمكن الانتقال إلى السلة لأنك لم تضف أي خدمات بعد',
            );
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartScreen(),
                settings: RouteSettings(
                  arguments: {
                    'id': widget.id,
                    'distance': widget.distance,
                    'duration': widget.duration,
                  },
                ),
              ),
            );
            await fetchTotalPrice(widget.id);
          }
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _initializeData,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                floating: true,
                actions: [
                  IconButton(
            onPressed: () => saveLaundryData(widget.id.toString()),
            icon: SvgPicture.asset(
              _isFavorited 
                ? "assets/icons/bookmark_fill.svg"  // الأيقونة المملوءة
                : "assets/icons/Bookmark.svg",         // الأيقونة الفارغة
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapScreen(
                            id: widget.id,
                            latitude: widget.latitude,
                            longitude: widget.longitude,
                          ),
                        ),
                      );
                    },
                    icon: SvgPicture.asset(
                      "assets/icons/Location.svg",
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                ],
              ),
              ProductImages(
                images: [
                  widget.image.isEmpty 
                      ? '${APIConfig.static_baseUrl}/images/store.jpg' 
                      : widget.image,
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(defaultPadding),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    "${widget.distance} كم - ${widget.duration} دقيقة",
                    style: Theme.of(context).textTheme.titleSmall!,
                  ),
                ),
              ),
              
              // RevievWidget(averageRating:averageRating ,totalReviews:totalReviews),
              ServiceInfo(
                brand: widget.address,
                title: widget.name,
                isAvailable: widget.isAvailable,
                description: "لا يوجد وصف",
                rating: averageRating,
                numOfReviews: totalReviews,
                laundryId: widget.id,
                laundryData: {
                  'id': widget.id,
                  'name': widget.name,
                  'address': widget.address,
                  'phone': '',
                  'email': '',
                  'x_map': widget.longitude.toString(),
                  'y_map': widget.latitude.toString(),
                  'image': widget.image,
                  'average_rating': averageRating,
                  'total_reviews': totalReviews,
                },
              ),
              // SliverToBoxAdapter(
              //   child: _buildCategoriesSection(),
              // ),
              SliverPersistentHeader(
              pinned: true,
              floating: false,
              delegate: _CategoriesHeaderDelegate(
                height: 90, // ارتفاع ثابت
                child: Material(
                  elevation: 2,
                  color: Colors.white,
                  child: _buildCategoriesSection(),
                ),
              ),
            ),

              SliverPadding(
                padding: const EdgeInsets.all(defaultPadding),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    "خدماتنا",
                    style: Theme.of(context).textTheme.titleSmall!,
                  ),
                ),
              ),
              _buildServicesSection(),
            ],
          ),
        ),
      ),
    );
  }

}