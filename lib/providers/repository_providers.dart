import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/bills/data/repositories/bill_repository.dart';
import '../features/payments/data/repositories/payment_repository.dart';
import 'core_providers.dart';

final billRepositoryProvider = Provider<BillRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BillRepository(db);
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PaymentRepository(db);
});
