import 'package:flutter/material.dart';
import 'package:melaq/components/widgets/professional_order_tracker.dart';
import 'package:melaq/components/widgets/order_status_indicator.dart';
import 'package:melaq/components/widgets/compact_order_status.dart';
import 'package:melaq/constants.dart';

/// شاشة توضيحية لعرض جميع أنواع مؤشرات حالة الطلب
class OrderStatusExamplesScreen extends StatefulWidget {
  const OrderStatusExamplesScreen({super.key});

  @override
  State<OrderStatusExamplesScreen> createState() => _OrderStatusExamplesScreenState();
}

class _OrderStatusExamplesScreenState extends State<OrderStatusExamplesScreen> {
  OrderStatus _selectedStatus = OrderStatus.onTheWay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أمثلة شريط حالة الطلب'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // اختيار الحالة للاختبار
            _buildStatusSelector(),
            const SizedBox(height: 24),

            // المتتبع الاحترافي الكامل
            _buildSectionTitle('المتتبع الاحترافي الكامل'),
            ProfessionalOrderTracker(
              currentStatus: _selectedStatus,
              estimatedTime: 'خلال 2-3 ساعات',
              trackingNumber: 'ORD-12345',
              showProgressPercentage: true,
              showTimeEstimate: true,
              onStepTap: (status) {
                _showStatusInfo(status);
              },
            ),
            const SizedBox(height: 32),

            // النسخة المصغرة
            _buildSectionTitle('النسخة المصغرة'),
            ProfessionalOrderTracker(
              currentStatus: _selectedStatus,
              compactMode: true,
              showProgressPercentage: true,
            ),
            const SizedBox(height: 32),

            // مؤشرات الحالة المختلفة
            _buildSectionTitle('مؤشرات الحالة'),
            Row(
              children: [
                OrderStatusIndicator(
                  status: _selectedStatus,
                  size: OrderStatusIndicatorSize.small,
                ),
                const SizedBox(width: 12),
                OrderStatusIndicator(
                  status: _selectedStatus,
                  size: OrderStatusIndicatorSize.medium,
                ),
                const SizedBox(width: 12),
                OrderStatusIndicator(
                  status: _selectedStatus,
                  size: OrderStatusIndicatorSize.large,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // شريط التقدم السريع
            _buildSectionTitle('شريط التقدم السريع'),
            QuickProgressBar(
              currentStatus: _selectedStatus,
              height: 8,
              showLabels: true,
              animated: true,
            ),
            const SizedBox(height: 24),

            // الشريط المتدرج
            _buildSectionTitle('الشريط المتدرج'),
            GradientStatusBar(
              currentStatus: _selectedStatus,
              height: 10,
              showCurrentStep: true,
            ),
            const SizedBox(height: 24),

            // المكون المصغر
            _buildSectionTitle('المكون المصغر'),
            CompactOrderStatus(
              status: _selectedStatus,
              showProgressBar: true,
              showPercentage: true,
              onTap: () {
                _showStatusInfo(_selectedStatus);
              },
            ),
            const SizedBox(height: 24),

            // الخط الزمني المصغر
            _buildSectionTitle('الخط الزمني المصغر'),
            MiniTimeline(
              currentStatus: _selectedStatus,
              dotSize: 10,
              lineHeight: 3,
            ),
            const SizedBox(height: 24),

            // المؤشر المتحرك
            _buildSectionTitle('المؤشر المتحرك'),
            Row(
              children: [
                AnimatedStatusIndicator(
                  status: _selectedStatus,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Text(
                  _getStatusText(_selectedStatus),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // أمثلة على الاستخدام في البطاقات
            _buildSectionTitle('أمثلة على الاستخدام في البطاقات'),
            _buildOrderCardExample(),
            const SizedBox(height: 16),
            _buildNotificationExample(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر حالة الطلب:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: OrderStatus.values
                .where((status) => status != OrderStatus.error)
                .map((status) {
              return ChoiceChip(
                label: Text(_getStatusText(status)),
                selected: _selectedStatus == status,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  }
                },
                selectedColor: primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _selectedStatus == status ? primaryColor : null,
                  fontWeight: _selectedStatus == status ? FontWeight.bold : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildOrderCardExample() {
    return Card(
      elevation: 4,
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
                const Text(
                  'طلب #12345',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                OrderStatusIndicator(
                  status: _selectedStatus,
                  size: OrderStatusIndicatorSize.medium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('مغسلة الأناقة - شارع الملك فهد'),
            const SizedBox(height: 12),
            QuickProgressBar(
              currentStatus: _selectedStatus,
              height: 6,
              showLabels: false,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  '125.50 ر.س',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('التفاصيل'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationExample() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(_selectedStatus).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(_selectedStatus).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          AnimatedStatusIndicator(
            status: _selectedStatus,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تحديث حالة الطلب',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(_selectedStatus),
                  ),
                ),
                Text(
                  _getStatusDescription(_selectedStatus),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return 'يعالج';
      case OrderStatus.onTheWay:
        return 'بالطريق';
      case OrderStatus.pickup:
        return 'تم الاستلام';
      case OrderStatus.deliveredToLaundry:
        return 'بالمغسلة';
      case OrderStatus.completed:
        return 'مكتمل';
      case OrderStatus.canceled:
        return 'ملغي';
      case OrderStatus.error:
        return 'خطأ';
    }
  }

  String _getStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return 'جاري معالجة طلبك وسيتم الاتصال بك قريباً';
      case OrderStatus.onTheWay:
        return 'المندوب في الطريق إليك لاستلام الملابس';
      case OrderStatus.pickup:
        return 'تم استلام الملابس من منزلك بنجاح';
      case OrderStatus.deliveredToLaundry:
        return 'الملابس الآن في المغسلة وجاري معالجتها';
      case OrderStatus.completed:
        return 'تم إنجاز طلبك وتسليمه بنجاح';
      case OrderStatus.canceled:
        return 'تم إلغاء الطلب';
      case OrderStatus.error:
        return 'حدث خطأ في معالجة الطلب';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return primaryColor;
      case OrderStatus.onTheWay:
        return Colors.orange;
      case OrderStatus.pickup:
        return Colors.blue;
      case OrderStatus.deliveredToLaundry:
        return Colors.purple;
      case OrderStatus.completed:
        return successColor;
      case OrderStatus.canceled:
      case OrderStatus.error:
        return errorColor;
    }
  }

  void _showStatusInfo(OrderStatus status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getStatusText(status)),
        content: Text(_getStatusDescription(status)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}