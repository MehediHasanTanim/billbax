import 'package:sqflite/sqflite.dart';

import '../models/bill_account.dart';

class BillRepository {
  BillRepository(this._db);

  final Database _db;

  Future<List<BillAccount>> getAll({bool activeOnly = true}) async {
    final where = activeOnly ? 'WHERE is_active = 1' : '';
    final maps = await _db.rawQuery(
      'SELECT * FROM bill_accounts $where ORDER BY created_at DESC',
    );
    return maps.map(BillAccount.fromMap).toList();
  }

  Future<BillAccount?> getById(String id) async {
    final maps = await _db.query(
      'bill_accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : BillAccount.fromMap(maps.first);
  }

  Future<void> insert(BillAccount account) async {
    await _db.insert(
      'bill_accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(BillAccount account) async {
    await _db.update(
      'bill_accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> softDelete(String id) async {
    await _db.update(
      'bill_accounts',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateLastPaid(String id, DateTime paidAt) async {
    await _db.update(
      'bill_accounts',
      {'last_paid_at': paidAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
