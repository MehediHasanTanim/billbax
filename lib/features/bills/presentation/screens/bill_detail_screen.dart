import 'package:flutter/material.dart';

/// Placeholder — implemented in Phase 2.
class BillDetailScreen extends StatelessWidget {
  const BillDetailScreen({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('বিল বিস্তারিত')),
      body: Center(child: Text('Bill: $billId')),
    );
  }
}
