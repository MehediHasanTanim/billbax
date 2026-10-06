import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bilbax/core/constants/app_strings.dart';
import 'package:bilbax/features/bills/providers/bill_providers.dart';
import 'package:bilbax/features/bills/presentation/screens/home_screen.dart';

class _EmptyBillNotifier extends BillAccountsNotifier {
  @override
  Future<BillAccountsState> build() async =>
      BillAccountsState.fromAccounts(const []);
}

void main() {
  testWidgets('HomeScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billAccountsProvider.overrideWith(_EmptyBillNotifier.new),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noBills), findsOneWidget);
    expect(find.text(AppStrings.addBill), findsOneWidget);
  });
}
