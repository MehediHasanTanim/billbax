import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bilbax/core/database/database_helper.dart';
import 'package:bilbax/features/bills/data/models/bill_account.dart';
import 'package:bilbax/features/bills/data/repositories/bill_repository.dart';
import 'package:bilbax/features/payments/data/models/payment_record.dart';
import 'package:bilbax/features/payments/data/repositories/payment_repository.dart';
import 'package:bilbax/features/payments/providers/payment_providers.dart';
import 'package:bilbax/providers/core_providers.dart';

void main() {
  late Database db;
  late ProviderContainer container;
  late BillAccount account;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await DatabaseHelper(inMemory: true).database;
    account = BillAccount.create(
      utilityType: UtilityType.desco,
      accountNumber: '123',
      nickname: 'Home',
    );
    await BillRepository(db).insert(account);

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('remoteConfigProvider falls back to defaults without Firebase', () async {
    final urls = await container.read(remoteConfigProvider.future);

    expect(urls['desco'], kDefaultPaymentUrls['desco']);
    expect(urls['dpdc'], kDefaultPaymentUrls['dpdc']);
    expect(urls.containsKey('btcl'), isTrue);
  });

  test('addRecord inserts payment and updates lastPaidAt', () async {
    await container.read(paymentHistoryProvider.future);

    await container.read(paymentHistoryProvider.notifier).addRecord(
          PaymentRecord.create(
            billAccountId: account.id,
            amount: 1500.5,
            notes: 'test',
          ),
        );

    final payments = await PaymentRepository(db).getByBillAccount(account.id);
    expect(payments.length, 1);
    expect(payments.first.amount, 1500.5);
    expect(payments.first.notes, 'test');

    final updated = await BillRepository(db).getById(account.id);
    expect(updated?.lastPaidAt, isNotNull);
  });
}
