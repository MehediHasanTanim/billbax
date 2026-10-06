import 'package:sqflite/sqflite.dart';

import '../models/payment_record.dart';

export '../models/payment_record.dart' show MonthlyTotal;

class PaymentRepository {
  PaymentRepository(this._db);

  final Database _db;

  Future<List<PaymentRecord>> getByBillAccount(String billAccountId) async {
    final maps = await _db.query(
      'payment_history',
      where: 'bill_account_id = ?',
      whereArgs: [billAccountId],
      orderBy: 'paid_at DESC',
    );
    return maps.map(PaymentRecord.fromMap).toList();
  }

  Future<List<PaymentRecord>> getByMonth(int year, int month) async {
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    final maps = await _db.query(
      'payment_history',
      where: 'paid_at >= ? AND paid_at < ?',
      whereArgs: [start, end],
      orderBy: 'paid_at DESC',
    );
    return maps.map(PaymentRecord.fromMap).toList();
  }

  Future<List<MonthlyTotal>> getMonthlyTotals(int year) async {
    final maps = await _db.rawQuery(
      '''
      SELECT
        strftime('%m', paid_at) AS month,
        SUM(amount) AS total
      FROM payment_history
      WHERE strftime('%Y', paid_at) = ?
      GROUP BY strftime('%m', paid_at)
      ORDER BY month
      ''',
      [year.toString()],
    );
    return maps
        .map(
          (m) => MonthlyTotal(
            month: int.parse(m['month'] as String),
            total: (m['total'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<void> insert(PaymentRecord record) async {
    await _db.insert(
      'payment_history',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markSynced(String id) async {
    await _db.update(
      'payment_history',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<PaymentRecord>> getUnsynced() async {
    final maps = await _db.query(
      'payment_history',
      where: 'is_synced = 0',
    );
    return maps.map(PaymentRecord.fromMap).toList();
  }

  Future<void> delete(String id) async {
    await _db.delete(
      'payment_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
