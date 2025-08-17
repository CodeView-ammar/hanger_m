import 'package:flutter/material.dart';
import '../../services/courier_service.dart';
import '../../components/custom_messages.dart';

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  List<Map<String, dynamic>> availableOrders = [];
  bool isLoading = true;
  bool isAccepting = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableOrders();
  }

  Future<void> _loadAvailableOrders() async {
    try {
      setState(() => isLoading = true);
      final orders = await CourierService.getAvailableOrders();
      setState(() {
        availableOrders = orders;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        AppMessageService().showErrorMessage(context, 'خطأ في جلب الطلبات: $e');
      }
    }
  }

  Future<void> _acceptOrder(int orderId) async {
    if (isAccepting) return;
    
    try {
      setState(() => isAccepting = true);
      await CourierService.acceptOrder(orderId);
      
      if (mounted) {
        AppMessageService().showSuccessMessage(context, 'تم قبول الطلب بنجاح');
        _loadAvailableOrders(); // إعادة تحميل القائمة
      }
    } catch (e) {
      if (mounted) {
        AppMessageService().showErrorMessage(context, 'خطأ في قبول الطلب: $e');
      }
    } finally {
      setState(() => isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات المتاحة'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableOrders,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAvailableOrders,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : availableOrders.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات متاحة حالياً',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: availableOrders.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final order = availableOrders[index];
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
    final items = order['items'] as List<dynamic>? ?? [];

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
                    color: Colors.blue,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    CourierService.getStatusText(order['status']),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Amount and Date
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
                    '${orderDate.hour}:${orderDate.minute.toString().padLeft(2, '0')}',
                    Colors.blue,
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
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الكمية: ${item['quantity']}'),
                        Text('${double.tryParse(item['price'].toString())?.toStringAsFixed(2)} ر.س'),
                      ],
                    ),
                  )),
            ],
            
            const SizedBox(height: 16),
            
            // Accept Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isAccepting ? null : () => _acceptOrder(orderId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isAccepting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'قبول الطلب',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
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