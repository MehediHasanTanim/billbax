import 'package:flutter/material.dart';

import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/models/payment_record.dart';

class PaymentTile extends StatelessWidget {
  const PaymentTile({
    super.key,
    required this.record,
    this.onDelete,
    this.onTap,
  });

  final PaymentRecord record;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade50,
        child: const Icon(Icons.payments_outlined, color: Colors.green),
      ),
      title: Text(
        CurrencyFormat.takaWithDecimals(record.amount),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          AppDateUtils.formatShort(record.paidAt),
          if (record.notes != null && record.notes!.isNotEmpty) record.notes!,
        ].join(' · '),
      ),
      trailing: onDelete == null
          ? null
          : IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'মুছুন',
              onPressed: onDelete,
            ),
      onTap: onTap,
    );
  }
}
