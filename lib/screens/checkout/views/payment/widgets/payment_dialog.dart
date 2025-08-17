import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../constants/payment_constants.dart';

/// نافذة الدفع المحسّنة
class PaymentDialog extends StatefulWidget {
  final String paymentUrl;
  final Function(bool success)? onPaymentComplete;
  final VoidCallback? onCancel;

  const PaymentDialog({
    Key? key,
    required this.paymentUrl,
    this.onPaymentComplete,
    this.onCancel,
  }) : super(key: key);

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  late DateTime _startTime;
  bool _paymentProcessed = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('PaymentApp/1.0 (Flutter)')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
            _checkPaymentResult(url);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _checkPaymentResult(url);
          },
          onWebResourceError: (error) {
            setState(() {
              _hasError = true;
              _errorMessage = 'خطأ في تحميل صفحة الدفع';
              _isLoading = false;
            });
          },
        ),
      );

    // Load the payment URL with error handling
    _loadPaymentUrl();
  }

  Future<void> _loadPaymentUrl() async {
    try {
      await _controller.loadRequest(Uri.parse(widget.paymentUrl));
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'فشل في تحميل صفحة الدفع: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _checkPaymentResult(String url) {
    // التحقق من انتهاء مهلة الدفع
    if (DateTime.now().difference(_startTime) > PaymentConstants.paymentTimeout) {
      _handleTimeout();
      return;
    }

    // التحقق من نتيجة الدفع من الرابط
    if (url.contains('success') || url.contains('approved')) {
      _handlePaymentResult(true);
    } else if (url.contains('fail') || url.contains('declined') || url.contains('error')) {
      _handlePaymentResult(false);
    } else if (url.contains('cancel') || url.contains('cancelled')) {
      _handleCancel();
    }
  }

  void _handlePaymentResult(bool success) {
    if (_paymentProcessed || !mounted) return;
    
    _paymentProcessed = true;
    widget.onPaymentComplete?.call(success);
    Navigator.of(context).pop(success); 
  }

  void _handleCancel() {
    if (_paymentProcessed || !mounted) return;
    
    _paymentProcessed = true;
    Navigator.of(context).pop();
    widget.onCancel?.call();
  }

  void _handleTimeout() {
    if (!mounted) return;
    
    setState(() {
      _hasError = true;
      _errorMessage = 'انتهت مهلة الدفع، يرجى المحاولة مرة أخرى';
      _isLoading = false;
    });
  }

  void _refresh() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _isLoading = true;
      _paymentProcessed = false;
    });
    _startTime = DateTime.now();
    _loadPaymentUrl();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بوابة الدفع'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          actions: [
            if (_hasError)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refresh,
                tooltip: 'إعادة تحميل',
              ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onCancel?.call();
              },
              tooltip: 'إغلاق',
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) _buildLoadingWidget(),
        _buildSecurityIndicator(),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'خطأ في تحميل صفحة الدفع',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'حدث خطأ غير متوقع',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onCancel?.call();
                  },
                  child: const Text('إلغاء'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.white.withOpacity(0.9),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'جاري تحميل صفحة الدفع...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'يرجى عدم إغلاق النافذة',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityIndicator() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.security,
              size: 16,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'اتصال آمن ومشفر',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}