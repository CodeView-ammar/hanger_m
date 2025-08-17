import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:melaq/constants.dart';
import 'package:melaq/screens/support/views/support_chat_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<Map<String, dynamic>> supportTickets = [];
  bool isLoading = true;
  String userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userid') ?? '';
    });
    if (userId.isNotEmpty) {
      await _fetchSupportTickets();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSupportTickets() async {
    try {
      final response = await http.get(
        Uri.parse('${APIConfig.supportTicketsEndpoint}?user=$userId')
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          supportTickets = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدعم الفني'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showFAQScreen(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with options
                Container(
                  padding: const EdgeInsets.all(16),
                  color: primaryColor.withOpacity(0.1),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateTicketDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('إنشاء تذكرة جديدة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showFAQScreen(context),
                        icon: const Icon(Icons.quiz),
                        label: const Text('الأسئلة الشائعة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tickets list
                Expanded(
                  child: supportTickets.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.support_agent,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'لا توجد تذاكر دعم فني',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'انقر على "إنشاء تذكرة جديدة" للحصول على المساعدة',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchSupportTickets,
                          child: ListView.builder(
                            itemCount: supportTickets.length,
                            itemBuilder: (context, index) {
                              final ticket = supportTickets[index];
                              return _buildTicketCard(ticket);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['status'] ?? 'open';
    final category = ticket['category'] ?? 'general';
    final priority = ticket['priority'] ?? 'medium';
    final unreadCount = ticket['unread_messages_count'] ?? 0;

    Color statusColor = _getStatusColor(status);
    IconData categoryIcon = _getCategoryIcon(category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(categoryIcon, color: statusColor),
        ),
        title: Text(
          ticket['title'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الحالة: ${_getStatusText(status)}'),
            Text('الأولوية: ${_getPriorityText(priority)}'),
            Text(_formatDate(ticket['created_at'] ?? '')),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () => _openTicketChat(ticket),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return Colors.blue;
      case 'in_progress': return Colors.orange;
      case 'resolved': return Colors.green;
      case 'closed': return Colors.grey;
      default: return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'technical': return Icons.computer;
      case 'billing': return Icons.payment;
      case 'order': return Icons.shopping_bag;
      case 'complaint': return Icons.report_problem;
      case 'suggestion': return Icons.lightbulb;
      default: return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'open': return 'مفتوح';
      case 'in_progress': return 'قيد المعالجة';
      case 'resolved': return 'محلول';
      case 'closed': return 'مغلق';
      default: return status;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'low': return 'منخفض';
      case 'medium': return 'متوسط';
      case 'high': return 'عالي';
      case 'urgent': return 'عاجل';
      default: return priority;
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showCreateTicketDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateTicketDialog(
        onTicketCreated: () {
          _fetchSupportTickets();
        },
      ),
    );
  }

  void _showFAQScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FAQScreen(),
      ),
    );
  }

  void _openTicketChat(Map<String, dynamic> ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupportChatScreen(
          ticketId: ticket['id'],
          ticketTitle: ticket['title'] ?? '',
        ),
      ),
    ).then((_) => _fetchSupportTickets());
  }
}

// Dialog for creating new ticket
class CreateTicketDialog extends StatefulWidget {
  final VoidCallback onTicketCreated;

  const CreateTicketDialog({Key? key, required this.onTicketCreated}) : super(key: key);

  @override
  State<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<CreateTicketDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'general';
  String _selectedPriority = 'medium';
  bool _isLoading = false;

  final List<Map<String, String>> categories = [
    {'value': 'general', 'text': 'استفسار عام'},
    {'value': 'technical', 'text': 'مشكلة تقنية'},
    {'value': 'billing', 'text': 'مشكلة فواتير'},
    {'value': 'order', 'text': 'مشكلة طلب'},
    {'value': 'complaint', 'text': 'شكوى'},
    {'value': 'suggestion', 'text': 'اقتراح'},
  ];

  final List<Map<String, String>> priorities = [
    {'value': 'low', 'text': 'منخفض'},
    {'value': 'medium', 'text': 'متوسط'},
    {'value': 'high', 'text': 'عالي'},
    {'value': 'urgent', 'text': 'عاجل'},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إنشاء تذكرة دعم فني'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان المشكلة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'نوع المشكلة',
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category['value'],
                  child: Text(category['text']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'الأولوية',
                border: OutlineInputBorder(),
              ),
              items: priorities.map((priority) {
                return DropdownMenuItem(
                  value: priority['value'],
                  child: Text(priority['text']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'وصف المشكلة',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createTicket,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('إنشاء'),
        ),
      ],
    );
  }

  Future<void> _createTicket() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid') ?? '';

      final response = await http.post(
        Uri.parse(APIConfig.supportTicketsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user': int.parse(userId),
          'title': _titleController.text.trim(),
          'category': _selectedCategory,
          'priority': _selectedPriority,
          'initial_message': _messageController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context);
        widget.onTicketCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء التذكرة بنجاح')),
        );
      } else {
        throw Exception('فشل في إنشاء التذكرة');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// FAQ Screen placeholder
class FAQScreen extends StatelessWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأسئلة الشائعة'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('سيتم إضافة الأسئلة الشائعة قريباً'),
      ),
    );
  }
}

// Support Chat Screen placeholder
class SupportChatScreen extends StatelessWidget {
  final int ticketId;
  final String ticketTitle;

  const SupportChatScreen({
    Key? key,
    required this.ticketId,
    required this.ticketTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ticketTitle),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('شاشة المحادثة قيد التطوير'),
      ),
    );
  }
}