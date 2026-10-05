import 'package:flutter/material.dart';

/// Placeholder — implemented in Phase 3.
class PaymentRedirectScreen extends StatelessWidget {
  const PaymentRedirectScreen({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('পেমেন্ট')),
      body: Center(child: Text('Pay: $billId')),
    );
  }
}
