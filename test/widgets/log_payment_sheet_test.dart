import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bilbax/core/database/database_helper.dart';
import 'package:bilbax/features/bills/data/models/bill_account.dart';
import 'package:bilbax/features/payments/presentation/widgets/log_payment_sheet.dart';
import 'package:bilbax/providers/core_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
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
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('LogPaymentSheet rejects invalid amount', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: LogPaymentSheet(billAccount: account),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.tap(find.text('সংরক্ষণ করুন'));
    await tester.pump();

    expect(find.text('সঠিক পরিমাণ দিন'), findsOneWidget);
  });

  testWidgets('LogPaymentSheet shows bill nickname', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: LogPaymentSheet(billAccount: account),
          ),
        ),
      ),
    );

    expect(find.text('Home — পেমেন্ট রেকর্ড'), findsOneWidget);
    expect(find.text('সংরক্ষণ করুন'), findsOneWidget);
  });
}
