import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/bill_account.dart';
import '../../providers/bill_providers.dart';
import '../widgets/bill_type_icon.dart';

class BillDetailScreen extends ConsumerWidget {
  const BillDetailScreen({super.key, required this.billId});

  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBills = ref.watch(billAccountsProvider);
    final account = ref.watch(billByIdProvider(billId));

    return Scaffold(
      appBar: AppBar(
        title: Text(account?.nickname ?? 'বিল বিস্তারিত'),
        actions: [
          if (account != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/add-bill', extra: account),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref, account),
            ),
          ],
        ],
      ),
      body: asyncBills.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) {
          if (account == null) {
            return const Center(child: Text('বিল পাওয়া যায়নি'));
          }
          return _BillDetailBody(account: account);
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BillAccount account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('বিল মুছবেন?'),
        content: Text('"${account.nickname}" মুছে ফেলা হবে।'),
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

    if (confirmed != true || !context.mounted) return;

    await ref.read(billAccountsProvider.notifier).deleteAccount(account.id);
    if (context.mounted) context.pop();
  }
}

class _BillDetailBody extends StatelessWidget {
  const _BillDetailBody({required this.account});

  final BillAccount account;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: BillTypeIcon(type: account.utilityType),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.nickname,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(account.utilityType.displayNameBn),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.tag),
          title: const Text('অ্যাকাউন্ট নম্বর'),
          subtitle: Text(account.accountNumber),
        ),
        if (account.area != null)
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: const Text('এলাকা'),
            subtitle: Text(account.area!),
          ),
        ListTile(
          leading: const Icon(Icons.event),
          title: const Text('বকেয়া তারিখ'),
          subtitle: Text(
            account.typicalDueDay != null
                ? 'প্রতি মাসের ${account.typicalDueDay} তারিখ'
                : 'নির্ধারিত নেই',
          ),
        ),
        if (account.lastPaidAt != null)
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('শেষ পেমেন্ট'),
            subtitle: Text(
              '${account.lastPaidAt!.day}/${account.lastPaidAt!.month}/${account.lastPaidAt!.year}',
            ),
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.push('/pay/${account.id}'),
          icon: const Icon(Icons.payment),
          label: const Text('পে করুন'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/history/${account.id}'),
          icon: const Icon(Icons.history),
          label: const Text('পেমেন্ট ইতিহাস'),
        ),
      ],
    );
  }
}
