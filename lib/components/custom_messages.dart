import 'package:flutter/material.dart';
import 'package:melaq/constants.dart';

/// مكون مخصص للرسائل والإشعارات في التطبيق
/// يدعم أنواع مختلفة من الرسائل: نجاح، خطأ، تحذير، معلومات
class AppMessageService {
  // نمط Singleton للوصول إلى كائن واحد في كل التطبيق
  static final AppMessageService _instance = AppMessageService._internal();
  
  factory AppMessageService() {
    return _instance;
  }
  
  AppMessageService._internal();
  
  // عرض رسالة نجاح
  void showSuccessMessage(BuildContext context, String message, {Duration? duration}) {
    _showCustomMessage(
      context: context,
      message: message,
      messageType: MessageType.success,
      duration: duration,
    );
  }
  
  // عرض رسالة خطأ
  void showErrorMessage(BuildContext context, String message, {Duration? duration}) {
    _showCustomMessage(
      context: context,
      message: message,
      messageType: MessageType.error,
      duration: duration,
    );
  }
  
  // عرض رسالة تحذير
  void showWarningMessage(BuildContext context, String message, {Duration? duration}) {
    _showCustomMessage(
      context: context,
      message: message,
      messageType: MessageType.warning,
      duration: duration,
    );
  }
  
  // عرض رسالة معلومات
  void showInfoMessage(BuildContext context, String message, {Duration? duration}) {
    _showCustomMessage(
      context: context,
      message: message,
      messageType: MessageType.info,
      duration: duration,
    );
  }
  
  // عرض رسالة عدم اتصال بالإنترنت
  void showNoInternetMessage(BuildContext context, {Function? onRetry}) {
    _showNoInternetMessage(context, onRetry: onRetry);
  }
  
  // منطق عرض الرسائل المخصصة
  void _showCustomMessage({
    required BuildContext context,
    required String message,
    required MessageType messageType,
    Duration? duration,
  }) {
    final snackBar = SnackBar(
      content: AppMessage(
        message: message,
        messageType: messageType,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: duration ?? const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.zero,
    );
    
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
  
  // رسالة عدم اتصال بالإنترنت
  void _showNoInternetMessage(BuildContext context, {Function? onRetry}) {
    final snackBar = SnackBar(
      content: NoInternetMessage(onRetry: onRetry),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 10),
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.zero,
    );
    
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}

// أنواع الرسائل
enum MessageType {
  success,
  error,
  warning,
  info,
}

// مكون الرسالة المخصصة
class AppMessage extends StatelessWidget {
  final String message;
  final MessageType messageType;
  final VoidCallback? onAction;
  final String? actionLabel;
  
  const AppMessage({
    super.key,
    required this.message,
    required this.messageType,
    this.onAction,
    this.actionLabel,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getShadowColor(),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _getIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onAction != null && actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
  
  Color _getBackgroundColor() {
    switch (messageType) {
      case MessageType.success:
        return successColor;
      case MessageType.error:
        return errorColor;
      case MessageType.warning:
        return const Color(0xFFF9A825); // amber
      case MessageType.info:
        return primaryColor;
    }
  }
  
  Color _getShadowColor() {
    return _getBackgroundColor().withOpacity(0.3);
  }
  
  Widget _getIcon() {
    IconData iconData;
    
    switch (messageType) {
      case MessageType.success:
        iconData = Icons.check_circle;
        break;
      case MessageType.error:
        iconData = Icons.error;
        break;
      case MessageType.warning:
        iconData = Icons.warning;
        break;
      case MessageType.info:
        iconData = Icons.info;
        break;
    }
    
    return Icon(
      iconData,
      color: Colors.white,
      size: 24,
    );
  }
  
  String _getTitle() {
    switch (messageType) {
      case MessageType.success:
        return 'تم بنجاح';
      case MessageType.error:
        return 'حدث خطأ';
      case MessageType.warning:
        return 'تنبيه';
      case MessageType.info:
        return 'معلومات';
    }
  }
}

// مكون رسالة عدم اتصال بالإنترنت
class NoInternetMessage extends StatelessWidget {
  final Function? onRetry;
  
  const NoInternetMessage({
    super.key,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF424242), // رمادي داكن
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'لا يوجد اتصال بالإنترنت',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onRetry != null)
            ElevatedButton.icon(
              onPressed: () {
                onRetry!();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('إعادة المحاولة'),
            ),
        ],
      ),
    );
  }
}

// مثال على استخدام خدمة الرسائل
// AppMessageService().showSuccessMessage(context, 'تم حفظ المعلومات بنجاح');
// AppMessageService().showErrorMessage(context, 'فشل تحميل البيانات، يرجى المحاولة مرة أخرى');
// AppMessageService().showNoInternetMessage(context, onRetry: () => fetchData());