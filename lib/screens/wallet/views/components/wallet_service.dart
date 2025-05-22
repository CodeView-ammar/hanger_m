import 'dart:convert';
import 'package:http/http.dart' as http;

class WalletService {
  static Future<WalletData> getWalletData(int userId) async {
    final response = await http.get(Uri.parse('https://hangerapp.com.sa/api/wallet/?user_id=$userId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return WalletData.fromJson(data);
    } else {
      throw Exception('Failed to fetch wallet data');
    }
  }
}
class WalletData {
  final double balance;
  final List<WalletTransaction> transactions;

  WalletData({required this.balance, required this.transactions});

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      balance: json['balance'].toDouble(),
      transactions: (json['transactions'] as List)
          .map((t) => WalletTransaction.fromJson(t))
          .toList(),
    );
  }
}
class WalletTransaction {
  final int id;
  final int user;
  final String date;
  final String dateJust;
  final String transactionType;
  final double amount;
  final double debit;
  final double credit;
  final String description;

  WalletTransaction({
    required this.id,
    required this.user,
    required this.date,
    required this.dateJust,
    required this.transactionType,
    required this.amount,
    required this.debit,
    required this.credit,
    required this.description,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    
    String description = json['description'];
  try {
    description = const Utf8Decoder(allowMalformed: true).convert(description.codeUnits);
  } catch (e) {
    // Handle the decoding error gracefully
    description = 'Error decoding description';
  }

    return WalletTransaction(
      id: json['id'],
      user: json['user'],
      date: json['date'],
      dateJust: json['date_jsut'],
      transactionType: json['transaction_type'],
      amount: double.parse(json['amount']),
      debit: double.parse(json['debit']),
      credit: double.parse(json['credit']),
      description: description,
    );
  }
}