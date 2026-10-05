import 'package:sqflite/sqflite.dart';

import '../models/bill_account.dart';

/// Placeholder — implemented in Phase 1.
class BillRepository {
  BillRepository(this._db);

  // ignore: unused_field
  final Database _db;

  Future<List<BillAccount>> getAll({bool activeOnly = true}) async => [];
}
