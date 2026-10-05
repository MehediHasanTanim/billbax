import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_format.dart';
import '../../../bills/providers/bill_providers.dart';
import '../../data/models/payment_record.dart';
import '../../providers/payment_providers.dart';
import '../widgets/payment_tile.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(billByIdProvider(billId));
    final historyAsync = ref.watch(billPaymentHistoryProvider(billId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          account != null ? '${account.nickname} — ইতিহাস' : 'পেমেন্ট ইতিহাস',
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('কোনো পেমেন্ট রেকর্ড নেই'),
                ],
              ),
            );
          }

          final total = records.fold<double>(0, (s, r) => s + r.amount);

          return Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  title: const Text('মোট'),
                  trailing: Text(
                    CurrencyFormat.taka(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return PaymentTile(
                      record: record,
                      onDelete: () => _confirmDelete(context, ref, record),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PaymentRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('রেকর্ড মুছবেন?'),
        content: const Text('এই পেমেন্ট এন্ট্রি মুছে যাবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(paymentHistoryProvider.notifier).deleteRecord(record);
  }
}
