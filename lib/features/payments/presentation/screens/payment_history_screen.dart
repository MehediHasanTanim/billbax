import 'package:flutter/material.dart';

/// Placeholder — implemented in Phase 4.
class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ইতিহাস')),
      body: Center(child: Text('History: $billId')),
    );
  }
}
