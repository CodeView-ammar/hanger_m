import 'package:flutter/material.dart';
import 'package:melaq/l10n/app_localizations.dart';

class TimeIndicator extends StatelessWidget {
  final String time;

  const TimeIndicator({super.key, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.timer),
        SizedBox(width: 5),
        Text(AppLocalizations.of(context)!.expecteddeliverytime),
        SizedBox(width: 30),
        Text(time,
        style: const TextStyle(
          fontSize: 15,
           color: Color.fromRGBO( 0, 0, 0,1), 
          fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 10),
        Text(AppLocalizations.of(context)!.minute,   
          style: const TextStyle(
          fontSize: 15,
           color: Color.fromRGBO( 0, 0, 0,1),
          fontWeight: FontWeight.bold,
          ),
),
      ],
    );
  }
}