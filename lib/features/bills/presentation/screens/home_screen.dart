import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';

/// Phase 0 shell — bill list arrives in Phase 2.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => context.push('/analytics'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              AppStrings.appName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Phase 0 bootstrap ✓',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-bill'),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addBill),
      ),
    );
  }
}
