import 'package:sqflite/sqflite.dart';

import '../models/payment_record.dart';

/// Placeholder — implemented in Phase 1.
class PaymentRepository {
  PaymentRepository(this._db);

  // ignore: unused_field
  final Database _db;

  Future<List<PaymentRecord>> getByBillAccount(String billAccountId) async =>
      [];
}
