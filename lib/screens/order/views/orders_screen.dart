import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/components/custom_messages.dart';
import 'package:melaq/components/order_process.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/l10n/app_localizations.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  List<OrderModel> _orders = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchOrders();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid');
      
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'يرجى تسجيل الدخول لعرض طلباتك';
        });
        return;
      }
      
      final response = await http.get(
        Uri.parse('${APIConfig.orderlaundryUrl}?user=$userId'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<OrderModel> orders = data.map((item) => OrderModel.fromJson(item)).toList();
        
        // ترتيب الطلبات من الأحدث إلى الأقدم
        orders.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
        
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل في جلب الطلبات: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.orders ?? 'طلباتي'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: Theme.of(context).textTheme.bodyLarge!.color,
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'الجارية'),
            Tab(text: 'المكتملة'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحميل الطلبات...'),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchOrders,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : _orders.isEmpty
                    ? _buildEmptyState(context)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // كل الطلبات
                          _buildOrdersList(_orders),
                          
                          // الطلبات الجارية
                          _buildOrdersList(_orders.where((order) => 
                              order.status != 'delivered' && 
                              order.status != 'canceled').toList()),
                          
                          // الطلبات المكتملة
                          _buildOrdersList(_orders.where((order) => 
                              order.status == 'delivered').toList()),
                        ],
                      ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد طلبات حالية',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر هنا طلباتك بمجرد إنشائها',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('تصفح المغاسل'),
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
  
  Widget _buildOrdersList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          'لا توجد طلبات في هذه القائمة',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(
          order: order,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailsScreen(orderId: order.id),
              ),
            ).then((_) => _fetchOrders());
          },
        );
      },
    );
  }
}

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  
  const OrderCard({
    Key? key,
    required this.order,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final statusText = _getStatusText(order.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // رقم الطلب
                  Text(
                    'طلب #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  // تاريخ الطلب
                  Text(
                    _formatDate(order.dateCreated),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // اسم المغسلة
              Row(
                children: [
                  const Icon(Icons.store, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.laundryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // عدد العناصر والسعر
              Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${order.items.length} عناصر',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    '${order.totalPrice.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // حالة الطلب وزر التفاصيل
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(order.status),
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('عرض التفاصيل'),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return primaryColor;
      case 'delivering':
        return primaryColor;
      case 'delivered':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'قيد المعالجة';
      case 'delivering':
        return 'قيد التوصيل';
      case 'delivered':
        return 'تم التسليم';
      case 'canceled':
        return 'ملغي';
      default:
        return 'غير معروف';
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'processing':
        return Icons.wash;
      case 'delivering':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}

// شاشة تفاصيل الطلب
class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  
  const OrderDetailsScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);
  
  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  OrderModel? _order;
  
  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }
  
  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final response = await http.get(
        Uri.parse('${APIConfig.orderdetilsUrl}${widget.orderId}/'),
      );
      
      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        
        setState(() {
          _order = OrderModel.fromJson(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل في جلب تفاصيل الطلب: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل الطلب #${widget.orderId}'),
        elevation: 0,
        actions: [
          if (_order != null && _order!.status == 'pending')
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'إلغاء الطلب',
              onPressed: () {
                _showCancelOrderDialog();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchOrderDetails,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _order == null
                  ? const Center(
                      child: Text('لا توجد معلومات لهذا الطلب'),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchOrderDetails,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // شريط حالة الطلب
                            _buildOrderStatusBar(),
                            
                            const SizedBox(height: 24),
                            
                            // معلومات الطلب
                            _buildOrderInfoCard(),
                            
                            const SizedBox(height: 16),
                            
                            // العناصر المطلوبة
                            _buildOrderItemsCard(),
                            
                            const SizedBox(height: 16),
                            
                            // معلومات التوصيل
                            _buildDeliveryInfoCard(),
                            
                            const SizedBox(height: 16),
                            
                            // ملخص المبلغ
                            _buildPriceSummaryCard(),
                            
                            // معلومات المستلم (في حالة التسليم)
                            if (_order!.status == 'delivered')
                              Column(
                                children: [
                                  const SizedBox(height: 16),
                                  _buildDeliveryConfirmationCard(),
                                ],
                              ),
                            
                            const SizedBox(height: 24),
                            
                            // زر طلب الدعم
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // التنقل إلى صفحة الدعم مع معلومات الطلب
                                  AppMessageService().showInfoMessage(
                                    context, 
                                    'تم إرسال طلب المساعدة المتعلق بالطلب #${widget.orderId}. سنتواصل معك قريباً.',
                                  );
                                },
                                icon: const Icon(Icons.support_agent),
                                label: const Text('طلب المساعدة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
  
  Widget _buildOrderStatusBar() {
    // تحويل حالة الطلب إلى حالات مكون OrderProgress
    final bool isCanceled = _order!.status == 'canceled';
    final DateTime now = DateTime.now();
    
    // تحديد الحالات بناءً على حالة الطلب
    OrderProcessStatus orderStatus = OrderProcessStatus.done;
    OrderProcessStatus processingStatus = OrderProcessStatus.notDoneYeat;
    OrderProcessStatus packedStatus = OrderProcessStatus.notDoneYeat;
    OrderProcessStatus shippedStatus = OrderProcessStatus.notDoneYeat;
    OrderProcessStatus deliveredStatus = OrderProcessStatus.notDoneYeat;
    
    switch (_order!.status) {
      case 'pending':
        processingStatus = OrderProcessStatus.processing;
        break;
      case 'processing':
        processingStatus = OrderProcessStatus.done;
        packedStatus = OrderProcessStatus.processing;
        break;
      case 'delivering':
        processingStatus = OrderProcessStatus.done;
        packedStatus = OrderProcessStatus.done;
        shippedStatus = OrderProcessStatus.processing;
        break;
      case 'delivered':
        processingStatus = OrderProcessStatus.done;
        packedStatus = OrderProcessStatus.done;
        shippedStatus = OrderProcessStatus.done;
        deliveredStatus = OrderProcessStatus.done;
        break;
      case 'canceled':
        break;
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: EnhancedOrderProgress(
          orderStatus: orderStatus,
          processingStatus: processingStatus,
          packedStatus: packedStatus,
          shippedStatus: shippedStatus,
          deliveredStatus: deliveredStatus,
          isCanceled: isCanceled,
          estimatedDeliveryTime: _getEstimatedDeliveryTime(),
          onStepTap: (index) {
            AppMessageService().showInfoMessage(
              context, 
              _getStepInfo(index),
            );
          },
        ),
      ),
    );
  }
  
  String _getEstimatedDeliveryTime() {
    if (_order!.status == 'delivered') {
      return 'تم التوصيل بنجاح';
    } else if (_order!.status == 'canceled') {
      return 'تم إلغاء الطلب';
    }
    
    // أمثلة افتراضية للتوقيت المتوقع (في التطبيق الحقيقي ستأتي من API)
    if (_order!.status == 'delivering') {
      return 'خلال 30 دقيقة';
    } else if (_order!.status == 'processing') {
      return 'اليوم في حوالي الساعة 3:00 مساءً';
    } else {
      return 'غداً في حوالي الساعة 10:00 صباحاً';
    }
  }
  
  String _getStepInfo(int index) {
    switch (index) {
      case 0:
        return 'تم استلام طلبك في ${_formatDate(_order!.dateCreated)}';
      case 1:
        if (_order!.status == 'pending') {
          return 'جاري معالجة طلبك من قبل المغسلة...';
        }
        return 'تمت معالجة طلبك بواسطة ${_order!.laundryName}';
      case 2:
        if (_order!.status == 'processing') {
          return 'جاري تغليف وتجهيز طلبك...';
        } else if (['delivering', 'delivered'].contains(_order!.status)) {
          return 'تم تغليف وتجهيز طلبك';
        }
        return 'سيتم تغليف وتجهيز طلبك قريباً';
      case 3:
        if (_order!.status == 'delivering') {
          return 'الطلب في طريقه إليك الآن!';
        } else if (_order!.status == 'delivered') {
          return 'تم تسليم طلبك بنجاح';
        }
        return 'سيتم تسليم طلبك حالما يكون جاهزاً';
      case 4:
        if (_order!.status == 'delivered') {
          return 'تم تسليم طلبك في ${_formatDateWithTime(_order!.dateDelivered ?? DateTime.now())}';
        } else if (_order!.status == 'canceled') {
          return 'تم إلغاء الطلب في ${_formatDateWithTime(_order!.dateUpdated)}';
        }
        return 'سيتم تسليم طلبك حالما يصبح جاهزاً للتوصيل';
      default:
        return 'معلومات الطلب';
    }
  }
  
  Widget _buildOrderInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'معلومات الطلب',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_order!.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(_order!.status),
                    style: TextStyle(
                      color: _getStatusColor(_order!.status),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'رقم الطلب:',
              '#${_order!.id}',
              Icons.confirmation_number,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'تاريخ الطلب:',
              _formatDateWithTime(_order!.dateCreated),
              Icons.date_range,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'المغسلة:',
              _order!.laundryName,
              Icons.store,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'طريقة الدفع:',
              _order!.paymentMethod,
              Icons.payment,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderItemsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'العناصر المطلوبة (${_order!.items.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ..._order!.items.map((item) => _buildOrderItemRow(item)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderItemRow(OrderItemModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${item.quantity}×',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.notes,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${item.price.toStringAsFixed(2)} ر.س',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDeliveryInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'معلومات التوصيل',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'عنوان التوصيل:',
              _order!.deliveryAddress,
              Icons.location_on,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'رقم الهاتف:',
              _order!.phoneNumber,
              Icons.phone,
            ),
            if (_order!.deliveryNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'ملاحظات التوصيل:',
                _order!.deliveryNotes,
                Icons.note,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriceSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'ملخص المبلغ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المجموع الفرعي:'),
                Text('${_order!.subtotalPrice.toStringAsFixed(2)} ر.س'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('رسوم التوصيل:'),
                Text('${_order!.deliveryFee.toStringAsFixed(2)} ر.س'),
              ],
            ),
            if (_order!.discount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الخصم:'),
                  Text(
                    '-${_order!.discount.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ],
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المجموع الكلي:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${_order!.totalPrice.toStringAsFixed(2)} ر.س',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeliveryConfirmationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'تم التسليم',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'تاريخ التسليم:',
              _formatDateWithTime(_order!.dateDelivered ?? DateTime.now()),
              Icons.access_time,
              textColor: Colors.green.shade700,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'استلمه:',
              _order!.receiverName ?? 'العميل',
              Icons.person,
              textColor: Colors.green.shade700,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon, {Color? textColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: textColor ?? Colors.grey[600],
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: textColor ?? Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  String _formatDateWithTime(DateTime date) {
    return DateFormat('dd/MM/yyyy - hh:mm a').format(date);
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return primaryColor;
      case 'delivering':
        return primaryColor;
      case 'delivered':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'قيد المعالجة';
      case 'delivering':
        return 'قيد التوصيل';
      case 'delivered':
        return 'تم التسليم';
      case 'canceled':
        return 'ملغي';
      default:
        return 'غير معروف';
    }
  }
  
  void _showCancelOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الطلب'),
        content: const Text('هل أنت متأكد من أنك تريد إلغاء هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelOrder();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _cancelOrder() async {
    try {
      // عرض مؤشر تحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final response = await http.post(
        Uri.parse('${APIConfig.orderlaundryUrl}${widget.orderId}/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'reason': 'تم الإلغاء بواسطة العميل',
        }),
      );
      
      // إغلاق مؤشر التحميل
      if (context.mounted) Navigator.of(context).pop();
      
      if (response.statusCode == 200) {
        // تم إلغاء الطلب بنجاح
        AppMessageService().showSuccessMessage(
          context, 
          'تم إلغاء الطلب بنجاح',
        );
        
        // إعادة تحميل تفاصيل الطلب لتحديث الحالة
        await _fetchOrderDetails();
      } else {
        // فشل في إلغاء الطلب
        AppMessageService().showErrorMessage(
          context, 
          'فشل في إلغاء الطلب. يرجى المحاولة مرة أخرى.',
        );
      }
    } catch (e) {
      // إغلاق مؤشر التحميل إذا حدث خطأ
      if (context.mounted) Navigator.of(context).pop();
      
      AppMessageService().showErrorMessage(
        context, 
        'حدث خطأ أثناء إلغاء الطلب: $e',
      );
    }
  }
}

// نموذج الطلب
class OrderModel {
  final int id;
  final String status;
  final String laundryName;
  final double subtotalPrice;
  final double deliveryFee;
  final double discount;
  final double totalPrice;
  final String deliveryAddress;
  final String phoneNumber;
  final String deliveryNotes;
  final String paymentMethod;
  final DateTime dateCreated;
  final DateTime dateUpdated;
  final DateTime? dateDelivered;
  final String? receiverName;
  final List<OrderItemModel> items;
  
  OrderModel({
    required this.id,
    required this.status,
    required this.laundryName,
    required this.subtotalPrice,
    required this.deliveryFee,
    required this.discount,
    required this.totalPrice,
    required this.deliveryAddress,
    required this.phoneNumber,
    required this.deliveryNotes,
    required this.paymentMethod,
    required this.dateCreated,
    required this.dateUpdated,
    this.dateDelivered,
    this.receiverName,
    required this.items,
  });
  
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      status: json['status'],
      laundryName: json['laundry_name'] ?? 'مغسلة',
      subtotalPrice: (json['subtotal_price'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      discount: (json['discount'] as num? ?? 0).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      deliveryAddress: json['delivery_address'] ?? 'العنوان غير متوفر',
      phoneNumber: json['phone_number'] ?? 'رقم الهاتف غير متوفر',
      deliveryNotes: json['delivery_notes'] ?? '',
      paymentMethod: json['payment_method'] ?? 'الدفع عند الاستلام',
      dateCreated: DateTime.parse(json['date_created']),
      dateUpdated: DateTime.parse(json['date_updated']),
      dateDelivered: json['date_delivered'] != null 
          ? DateTime.parse(json['date_delivered']) 
          : null,
      receiverName: json['receiver_name'],
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItemModel.fromJson(item))
          .toList(),
    );
  }
}

// نموذج عنصر الطلب
class OrderItemModel {
  final int id;
  final String name;
  final int quantity;
  final double price;
  final String notes;
  
  OrderItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.notes,
  });
  
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      name: utf8.decode((json['name'] ?? 'خدمة').codeUnits),
      quantity: json['quantity'] ?? 1,
      price: (json['price'] as num).toDouble(),
      notes: json['notes'] ?? '',
    );
  }
}
