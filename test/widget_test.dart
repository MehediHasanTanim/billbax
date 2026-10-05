import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bilbax/core/constants/app_strings.dart';
import 'package:bilbax/features/bills/data/models/bill_account.dart';
import 'package:bilbax/features/bills/presentation/screens/home_screen.dart';
import 'package:bilbax/features/bills/providers/bill_providers.dart';

class _FixedBillsNotifier extends BillAccountsNotifier {
  _FixedBillsNotifier(this._state);

  final BillAccountsState _state;

  @override
  Future<BillAccountsState> build() async => _state;
}

void main() {
  testWidgets('shows empty state when no bills', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billAccountsProvider.overrideWith(
            () => _FixedBillsNotifier(BillAccountsState.fromAccounts(const [])),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noBills), findsOneWidget);
    expect(find.text(AppStrings.addBill), findsOneWidget);
  });

  testWidgets('shows bill cards when accounts exist', (tester) async {
    final account = BillAccount.create(
      utilityType: UtilityType.desco,
      accountNumber: '1234567',
      nickname: 'Home',
      typicalDueDay: 15,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billAccountsProvider.overrideWith(
            () => _FixedBillsNotifier(
              BillAccountsState.fromAccounts([account]),
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('সব বিল'), findsOneWidget);
    expect(find.text('পে করুন'), findsOneWidget);
  });
}
