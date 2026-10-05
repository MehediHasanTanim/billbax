import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/bill_account.dart';

class BillCard extends ConsumerWidget {
  const BillCard({super.key, required this.account});

  final BillAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _colorForType(account.utilityType),
          child: Icon(
            _iconForType(account.utilityType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          account.nickname,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${account.utilityType.shortLabel} · ${account.accountNumber}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (account.typicalDueDay != null)
              Chip(
                label: Text('${account.typicalDueDay} তারিখ'),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () => context.push('/pay/${account.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('পে করুন'),
            ),
          ],
        ),
        onTap: () => context.push('/bill/${account.id}'),
      ),
    );
  }

  Color _colorForType(UtilityType type) => switch (type) {
        UtilityType.desco => Colors.yellow.shade700,
        UtilityType.dpdc => Colors.orange,
        UtilityType.wasa => Colors.blue,
        UtilityType.titas => Colors.deepOrange,
        UtilityType.internet => Colors.purple,
        UtilityType.btcl => Colors.teal,
      };

  IconData _iconForType(UtilityType type) => switch (type) {
        UtilityType.desco || UtilityType.dpdc => Icons.bolt,
        UtilityType.wasa => Icons.water_drop,
        UtilityType.titas => Icons.local_fire_department,
        UtilityType.internet => Icons.wifi,
        UtilityType.btcl => Icons.phone,
      };
}
