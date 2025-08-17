import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class CheckConnection extends StatefulWidget {
  final Widget child;

  const CheckConnection({Key? key, required this.child}) : super(key: key);

  @override
  _CheckConnectionState createState() => _CheckConnectionState();
}

class _CheckConnectionState extends State<CheckConnection> {
  StreamSubscription? internetConnection;
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    internetConnection =
        Connectivity().onConnectivityChanged.listen((connectivityResult) {
      setState(() {
        isOffline = connectivityResult == ConnectivityResult.none;
      });
    });
  }

  @override
  void dispose() {
    internetConnection?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (isOffline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red,
              child: Row(
                children: const [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "لا يوجد اتصال بالإنترنت",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
