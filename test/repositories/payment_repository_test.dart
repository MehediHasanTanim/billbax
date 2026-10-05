import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bilbax/core/database/database_helper.dart';
import 'package:bilbax/features/bills/data/models/bill_account.dart';
import 'package:bilbax/features/bills/data/repositories/bill_repository.dart';
import 'package:bilbax/features/payments/data/models/payment_record.dart';
import 'package:bilbax/features/payments/data/repositories/payment_repository.dart';

void main() {
  late Database db;
  late BillRepository billRepo;
  late PaymentRepository paymentRepo;
  late BillAccount account;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await DatabaseHelper(inMemory: true).database;
    billRepo = BillRepository(db);
    paymentRepo = PaymentRepository(db);

    account = BillAccount.create(
      utilityType: UtilityType.desco,
      accountNumber: '1234567',
      nickname: 'Home',
    );
    await billRepo.insert(account);
  });

  tearDown(() async {
    await db.close();
  });

  test('insert and retrieve payment by bill account', () async {
    final record = PaymentRecord.create(
      billAccountId: account.id,
      amount: 1240,
      notes: 'September',
      paidAt: DateTime(2026, 9, 15),
    );
    await paymentRepo.insert(record);

    final history = await paymentRepo.getByBillAccount(account.id);
    expect(history.length, 1);
    expect(history.first.amount, 1240);
    expect(history.first.notes, 'September');
    expect(history.first.isSynced, false);
  });

  test('getByMonth filters correctly', () async {
    await paymentRepo.insert(
      PaymentRecord.create(
        billAccountId: account.id,
        amount: 1000,
        paidAt: DateTime(2026, 3, 5),
      ),
    );
    await paymentRepo.insert(
      PaymentRecord.create(
        billAccountId: account.id,
        amount: 2000,
        paidAt: DateTime(2026, 4, 5),
      ),
    );

    final march = await paymentRepo.getByMonth(2026, 3);
    expect(march.length, 1);
    expect(march.first.amount, 1000);
  });

  test('getMonthlyTotals aggregates by month', () async {
    await paymentRepo.insert(
      PaymentRecord.create(
        billAccountId: account.id,
        amount: 500,
        paidAt: DateTime(2026, 1, 10),
      ),
    );
    await paymentRepo.insert(
      PaymentRecord.create(
        billAccountId: account.id,
        amount: 700,
        paidAt: DateTime(2026, 1, 20),
      ),
    );
    await paymentRepo.insert(
      PaymentRecord.create(
        billAccountId: account.id,
        amount: 300,
        paidAt: DateTime(2026, 2, 8),
      ),
    );

    final totals = await paymentRepo.getMonthlyTotals(2026);
    expect(totals.length, 2);
    expect(totals.first.month, 1);
    expect(totals.first.total, 1200);
    expect(totals.last.month, 2);
    expect(totals.last.total, 300);
  });

  test('markSynced and getUnsynced', () async {
    final record = PaymentRecord.create(
      billAccountId: account.id,
      amount: 800,
      paidAt: DateTime(2026, 5, 1),
    );
    await paymentRepo.insert(record);

    expect((await paymentRepo.getUnsynced()).length, 1);

    await paymentRepo.markSynced(record.id);
    expect((await paymentRepo.getUnsynced()).isEmpty, true);
  });

  test('delete removes payment record', () async {
    final record = PaymentRecord.create(
      billAccountId: account.id,
      amount: 100,
      paidAt: DateTime(2026, 6, 1),
    );
    await paymentRepo.insert(record);
    await paymentRepo.delete(record.id);

    final history = await paymentRepo.getByBillAccount(account.id);
    expect(history.isEmpty, true);
  });
}
