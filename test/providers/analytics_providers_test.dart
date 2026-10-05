import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bilbax/core/database/database_helper.dart';
import 'package:bilbax/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:bilbax/features/bills/data/models/bill_account.dart';
import 'package:bilbax/features/bills/data/repositories/bill_repository.dart';
import 'package:bilbax/features/payments/data/models/payment_record.dart';
import 'package:bilbax/features/payments/data/repositories/payment_repository.dart';
import 'package:bilbax/features/payments/providers/payment_providers.dart';
import 'package:bilbax/providers/core_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      accountNumber: '1',
      nickname: 'Home',
    );
    await BillRepository(db).insert(account);
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  tearDown(() async {
    await db.close();
  });

  test('monthlyTotalsProvider aggregates by month', () async {
    final payments = PaymentRepository(db);
    await payments.insert(
      PaymentRecord.create(
        billAccountId: account.id,
        amount: 100,
        paidAt: DateTime(2026, 1, 5),
      ),
    );
    await payments.insert(
      PaymentRecord.create(
        billAccountId: account.id,
        amount: 250,
        paidAt: DateTime(2026, 1, 20),
      ),
    );
    await payments.insert(
      PaymentRecord.create(
        billAccountId: account.id,
        amount: 80,
        paidAt: DateTime(2026, 3, 2),
      ),
    );

    final totals = await container.read(monthlyTotalsProvider(2026).future);
    expect(totals.length, 2);
    expect(totals.first.month, 1);
    expect(totals.first.total, 350);
    expect(totals.last.month, 3);
    expect(totals.last.total, 80);
  });

  test('billPaymentHistoryProvider returns records', () async {
    await PaymentRepository(db).insert(
      PaymentRecord.create(
        billAccountId: account.id,
        amount: 500,
        paidAt: DateTime(2026, 4, 1),
      ),
    );

    final history =
        await container.read(billPaymentHistoryProvider(account.id).future);
    expect(history.length, 1);
    expect(history.first.amount, 500);
  });

  testWidgets('AnalyticsScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedAnalyticsYearProvider.overrideWith((ref) => 2026),
          monthlyTotalsProvider.overrideWith((ref, year) async => []),
        ],
        child: const MaterialApp(home: AnalyticsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('বিল বিশ্লেষণ'), findsOneWidget);
    expect(find.text('এই বছরের কোনো পেমেন্ট নেই'), findsOneWidget);
  });

  testWidgets('AnalyticsScreen shows year total when data exists', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedAnalyticsYearProvider.overrideWith((ref) => 2026),
          monthlyTotalsProvider.overrideWith(
            (ref, year) async => [
              const MonthlyTotal(month: 2, total: 1200),
            ],
          ),
        ],
        child: const MaterialApp(home: AnalyticsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('2026 মোট খরচ'), findsOneWidget);
    expect(find.text('মাসিক খরচ'), findsOneWidget);
  });
}
