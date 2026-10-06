import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bilbax/core/database/database_helper.dart';
import 'package:bilbax/features/bills/data/models/bill_account.dart';
import 'package:bilbax/features/bills/data/repositories/bill_repository.dart';
import 'package:bilbax/features/payments/data/models/payment_record.dart';
import 'package:bilbax/features/payments/data/repositories/payment_repository.dart';

void main() {
  late Database db;
  late BillRepository bills;
  late PaymentRepository payments;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await DatabaseHelper(inMemory: true).database;
    bills = BillRepository(db);
    payments = PaymentRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('soft delete keeps payment history readable', () async {
    final account = BillAccount.create(
      utilityType: UtilityType.desco,
      accountNumber: '123',
      nickname: 'Home',
    );
    await bills.insert(account);
    await payments.insert(
      PaymentRecord.create(
        billAccountId: account.id,
        amount: 900,
        paidAt: DateTime(2026, 5, 1),
      ),
    );

    await bills.softDelete(account.id);

    final active = await bills.getAll(activeOnly: true);
    expect(active, isEmpty);

    final history = await payments.getByBillAccount(account.id);
    expect(history.length, 1);
    expect(history.first.amount, 900);

    final archived = await bills.getAll(activeOnly: false);
    expect(archived.length, 1);
    expect(archived.first.isActive, isFalse);
  });
}
