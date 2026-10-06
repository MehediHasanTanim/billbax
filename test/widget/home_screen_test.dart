import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

  testWidgets('shows overdue and all-bills sections', (tester) async {
    final today = DateTime.now().day;
    if (today <= 1) return;

    final overdue = BillAccount(
      id: '1',
      utilityType: UtilityType.desco,
      accountNumber: '111',
      nickname: 'Overdue Home',
      typicalDueDay: today - 1,
      createdAt: DateTime(2026, 1, 1),
    );
    final upcoming = BillAccount(
      id: '2',
      utilityType: UtilityType.wasa,
      accountNumber: '222',
      nickname: 'Upcoming Water',
      typicalDueDay: (today + 10).clamp(1, 28),
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billAccountsProvider.overrideWith(
            () => _FixedBillsNotifier(
              BillAccountsState.fromAccounts([overdue, upcoming]),
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
              GoRoute(
                path: '/pay/:billId',
                builder: (_, __) => const Scaffold(body: Text('pay')),
              ),
              GoRoute(
                path: '/bill/:id',
                builder: (_, __) => const Scaffold(body: Text('detail')),
              ),
              GoRoute(
                path: '/analytics',
                builder: (_, __) => const Scaffold(body: Text('analytics')),
              ),
              GoRoute(
                path: '/settings',
                builder: (_, __) => const Scaffold(body: Text('settings')),
              ),
              GoRoute(
                path: '/add-bill',
                builder: (_, __) => const Scaffold(body: Text('add')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('মেয়াদ পেরিয়েছে'), findsOneWidget);
    expect(find.text('সব বিল'), findsOneWidget);
    expect(find.text('Overdue Home'), findsWidgets);
    expect(find.text('Upcoming Water'), findsOneWidget);
  });
}
