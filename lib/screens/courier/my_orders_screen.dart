import 'package:flutter/material.dart';
import 'package:melaq/constants.dart';
import '../../services/courier_service.dart';
import '../../components/custom_messages.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<Map<String, dynamic>> myOrders = [];
  bool isLoading = true;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadMyOrders();
  }

  Future<void> _loadMyOrders() async {
    try {
      setState(() => isLoading = true);
      final orders = await CourierService.getMyOrders();
      setState(() {
        myOrders = orders;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        AppMessageService().showErrorMessage(context, 'خطأ في جلب طلباتي: $e');
      }
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    if (isUpdating) return;
    
    try {
      setState(() => isUpdating = true);
      await CourierService.updateOrderStatus(orderId, newStatus);
      
      if (mounted) {
        AppMessageService().showSuccessMessage(context, 'تم تحديث حالة الطلب بنجاح');
        _loadMyOrders(); // إعادة تحميل القائمة
      }
    } catch (e) {
      if (mounted) {
        AppMessageService().showErrorMessage(context, 'خطأ في تحديث الحالة: $e');
      }
    } finally {
      setState(() => isUpdating = false);
    }
  }

  void _showStatusUpdateDialog(Map<String, dynamic> order) {
    final currentStatus = order['status'];
    final nextStatuses = CourierService.getNextStatuses(currentStatus);
    
    if (nextStatuses.isEmpty) {
      AppMessageService().showInfoMessage(context, 'لا توجد حالات متاحة للتحديث');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تحديث حالة الطلب #${order['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الحالة الحالية: ${CourierService.getStatusText(currentStatus)}'),
            const SizedBox(height: 16),
            const Text('اختر الحالة الجديدة:'),
            const SizedBox(height: 8),
            ...nextStatuses.map((status) => ListTile(
                  title: Text(CourierService.getStatusText(status)),
                  onTap: () {
                    Navigator.pop(context);
                    _updateOrderStatus(order['id'], status);
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyOrders,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyOrders,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : myOrders.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات مُسندة إليك',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: myOrders.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final order = myOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'];
    final totalAmount = double.tryParse(order['total_amount'].toString()) ?? 0.0;
    final orderDate = DateTime.parse(order['order_date']);
    final status = order['status'];
    final items = order['items'] as List<dynamic>? ?? [];
    final nextStatuses = CourierService.getNextStatuses(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب رقم #$orderId',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(CourierService.getStatusColor(status)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    CourierService.getStatusText(status),
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(CourierService.getStatusColor(status)),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Amount, Date, and Delivery Method
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.account_balance_wallet,
                    'المبلغ',
                    '${totalAmount.toStringAsFixed(2)} ر.س',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    Icons.access_time,
                    'التاريخ',
                    '${orderDate.day}/${orderDate.month}',
                    primaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(
                  order['delivery_method'] == 'delivery' 
                      ? Icons.delivery_dining 
                      : Icons.store,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  order['delivery_method'] == 'delivery' 
                      ? 'توصيل للمنزل' 
                      : 'استلام من المغسلة',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            if (items.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const Text(
                'تفاصيل الطلب:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الكمية: ${item['quantity']}'),
                        Text('${double.tryParse(item['price'].toString())?.toStringAsFixed(2)} ر.س'),
                      ],
                    ),
                  )),
              if (items.length > 2)
                Text(
                  'و ${items.length - 2} عنصر آخر...',
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
            
            if (order['delegate_note'] != null && order['delegate_note'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ملاحظة: ${order['delegate_note']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (nextStatuses.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUpdating ? null : () => _showStatusUpdateDialog(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'تحديث الحالة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}