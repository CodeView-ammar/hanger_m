import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../constants.dart';

class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    super.key,
    required this.balance,
    required this.onTabChargeBalance,
  });

  final double balance;
  final VoidCallback onTabChargeBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        borderRadius: BorderRadius.circular(defaultBorderRadious),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: defaultPadding,
              vertical: defaultPadding * 1.5,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  Color(0xFF1565C0), // لون أعمق للبطاقة
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(defaultBorderRadious),
                topRight: Radius.circular(defaultBorderRadious),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "رصيد المحفظة",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white.withOpacity(0.9),
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: defaultPadding),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ر.س",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      balance.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: defaultPadding / 2),
                Text(
                  "آخر تحديث: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Container(
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     borderRadius: BorderRadius.only(
          //       bottomLeft: Radius.circular(defaultBorderRadious),
          //       bottomRight: Radius.circular(defaultBorderRadious),
          //     ),
          //     boxShadow: [
          //       BoxShadow(
          //         color: primaryColor.withOpacity(0.1),
          //         blurRadius: 5,
          //         offset: const Offset(0, 3),
          //       ),
          //     ],
          //   ),
          //   child: Material(
          //     color: Colors.transparent,
          //     child: InkWell(
          //       onTap: () {
          //         // أضف تأثير الاهتزاز عند الضغط
          //         HapticFeedback.mediumImpact();
          //         onTabChargeBalance();
          //       },
          //       borderRadius: BorderRadius.only(
          //         bottomLeft: Radius.circular(defaultBorderRadious),
          //         bottomRight: Radius.circular(defaultBorderRadious),
          //       ),
          //       child: Container(
          //         padding: const EdgeInsets.symmetric(vertical: 14),
          //         alignment: Alignment.center,
          //         child:const Row(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: [
          //             Icon(
          //               Icons.add_circle_outline,
          //               color: primaryColor,
          //               size: 20,
          //             ),
          //             const SizedBox(width: 8),
          //             Text(
          //               "إضافة رصيد",
          //               style: TextStyle(
          //                 color: primaryColor,
          //                 fontWeight: FontWeight.bold,
          //                 fontSize: 16,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
