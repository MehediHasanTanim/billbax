import 'package:flutter/material.dart';

/// Placeholder — implemented in Phase 5.
class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP')),
      body: Center(child: Text('OTP for $phone')),
    );
  }
}
