import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../providers/bill_providers.dart';
import '../widgets/bill_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billState = ref.watch(billAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/analytics'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: billState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error: $err', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(billAccountsProvider),
                  child: const Text('আবার চেষ্টা করুন'),
                ),
              ],
            ),
          ),
        ),
        data: (state) => _buildBody(context, state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-bill'),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addBill),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BillAccountsState state) {
    if (state.accounts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(AppStrings.noBills, style: TextStyle(color: Colors.grey)),
            Text('"বিল যোগ করুন" বাটনে ক্লিক করুন'),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        if (state.overdue.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: _SectionHeader(
              title: '⚠️ মেয়াদ পেরিয়েছে',
              color: Colors.red,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => BillCard(account: state.overdue[i]),
              childCount: state.overdue.length,
            ),
          ),
        ],
        if (state.dueSoon.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: _SectionHeader(
              title: '⏰ শীঘ্রই দেয়',
              color: Colors.orange,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => BillCard(account: state.dueSoon[i]),
              childCount: state.dueSoon.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(
          child: _SectionHeader(title: 'সব বিল', color: Colors.blue),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => BillCard(account: state.accounts[i]),
            childCount: state.accounts.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      );
}
