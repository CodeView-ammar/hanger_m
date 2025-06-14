import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:melaq/components/api_extintion/url_api.dart';
import 'package:http/http.dart' as http;
Future<void> addTransaction(
    String debitorcredit,
    String transactionType,
    double amount,
    String description,
    BuildContext context) async {
  final url = Uri.parse(APIConfig.addTransactionEndpoint);
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userid');

  // إعداد القيم
  double debit = debitorcredit == 'debit' ? amount : 0;
  double credit = debitorcredit == 'credit' ? amount : 0;

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'user': userId,
      'transaction_type': transactionType,  // تأكد من أن نوع المعاملة يتم تحديده بناءً على المدخلات
      'amount': amount.toString(),
      'debit': debit.toString(),
      'credit': credit.toString(),
      'description': description,
    }),
  );

  if (response.statusCode == 201 || response.statusCode == 200) {
    print('تم إضافة المعاملة بنجاح');
    Navigator.pop(context);
  } else {
    print('حدث خطأ: ${response.body}');
  }
}
