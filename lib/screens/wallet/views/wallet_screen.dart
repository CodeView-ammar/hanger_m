import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/wallet/views/components/wallet_service.dart';
import 'components/wallet_balance_card.dart';
import 'components/wallet_history_card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _walletBalance = 0.0;
  List<WalletTransaction> _walletTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userid');

      if (userId != null) {
        final walletData = await WalletService.getWalletData(int.parse(userId));
        setState(() {
          _walletBalance = walletData.balance;
          _walletTransactions = walletData.transactions;
          _isLoading = false;
        });
      } else {
        print('No user ID found in shared preferences');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching wallet data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("محفظة"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                      sliver: SliverToBoxAdapter(
                        child: WalletBalanceCard(
                          balance: _walletBalance,
                          onTabChargeBalance: () {},
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.only(top: defaultPadding / 2),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          "تاريخ المحفظة",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(top: defaultPadding),
                          child: WalletHistoryCard(
                            isReturn: _walletTransactions[index].credit > 0,
                            date: _walletTransactions[index].dateJust,
                            amount: _walletTransactions[index].amount,
                            description: _walletTransactions[index].description,
                          ),
                        ),
                        childCount: _walletTransactions.length,
                      ),
                    )
                  ],
                ),
        ),
      ),
    );
  }
}
