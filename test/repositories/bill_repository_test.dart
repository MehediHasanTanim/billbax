import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bilbax/core/database/database_helper.dart';
import 'package:bilbax/features/bills/data/models/bill_account.dart';
import 'package:bilbax/features/bills/data/repositories/bill_repository.dart';

void main() {
  late Database db;
  late BillRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await DatabaseHelper(inMemory: true).database;
    repo = BillRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('insert and retrieve bill account', () async {
    final account = BillAccount.create(
      utilityType: UtilityType.desco,
      accountNumber: '1234567',
      nickname: 'Home',
    );
    await repo.insert(account);
    final accounts = await repo.getAll();
    expect(accounts.length, 1);
    expect(accounts.first.nickname, 'Home');
    expect(accounts.first.utilityType, UtilityType.desco);
    expect(accounts.first.accountNumber, '1234567');
  });

  test('getById returns matching account', () async {
    final account = BillAccount.create(
      utilityType: UtilityType.dpdc,
      accountNumber: '555',
      nickname: 'Office',
      area: 'Dhanmondi',
      typicalDueDay: 15,
    );
    await repo.insert(account);

    final found = await repo.getById(account.id);
    expect(found, isNotNull);
    expect(found!.nickname, 'Office');
    expect(found.area, 'Dhanmondi');
    expect(found.typicalDueDay, 15);
  });

  test('update changes nickname and due day', () async {
    final account = BillAccount.create(
      utilityType: UtilityType.titas,
      accountNumber: '777',
      nickname: 'Gas',
    );
    await repo.insert(account);

    await repo.update(account.copyWith(nickname: 'Home Gas', typicalDueDay: 10));
    final updated = await repo.getById(account.id);
    expect(updated!.nickname, 'Home Gas');
    expect(updated.typicalDueDay, 10);
  });

  test('soft delete does not remove from db', () async {
    final account = BillAccount.create(
      utilityType: UtilityType.wasa,
      accountNumber: '9999',
      nickname: 'Office',
    );
    await repo.insert(account);
    await repo.softDelete(account.id);

    final activeOnly = await repo.getAll(activeOnly: true);
    expect(activeOnly.isEmpty, true);

    final all = await repo.getAll(activeOnly: false);
    expect(all.length, 1);
    expect(all.first.isActive, false);
  });

  test('updateLastPaid sets last_paid_at', () async {
    final account = BillAccount.create(
      utilityType: UtilityType.btcl,
      accountNumber: '111',
      nickname: 'Landline',
    );
    await repo.insert(account);

    final paidAt = DateTime(2026, 10, 1, 9);
    await repo.updateLastPaid(account.id, paidAt);

    final updated = await repo.getById(account.id);
    expect(updated!.lastPaidAt, isNotNull);
    expect(updated.lastPaidAt!.toIso8601String(), paidAt.toIso8601String());
  });
}
