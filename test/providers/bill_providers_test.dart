import 'package:flutter_test/flutter_test.dart';

import 'package:bilbax/features/bills/data/models/bill_account.dart';
import 'package:bilbax/features/bills/providers/bill_providers.dart';

void main() {
  BillAccount account({
    required int? dueDay,
    DateTime? lastPaidAt,
    String nickname = 'A',
  }) {
    return BillAccount(
      id: nickname,
      utilityType: UtilityType.desco,
      accountNumber: '1',
      nickname: nickname,
      typicalDueDay: dueDay,
      createdAt: DateTime(2026, 1, 1),
      lastPaidAt: lastPaidAt,
    );
  }

  test('fromAccounts marks due soon within 5 days', () {
    final today = DateTime.now().day;
    final dueDay = (today + 3).clamp(1, 28);

    // Skip if clamp can't express "within 5 days" near month end.
    if (dueDay < today) return;

    final state = BillAccountsState.fromAccounts([
      account(dueDay: dueDay, nickname: 'Soon'),
      account(dueDay: null, nickname: 'NoDue'),
    ]);

    expect(state.dueSoon.map((a) => a.nickname), contains('Soon'));
    expect(state.dueSoon.map((a) => a.nickname), isNot(contains('NoDue')));
  });

  test('fromAccounts marks overdue when unpaid this month', () {
    final today = DateTime.now().day;
    if (today <= 1) return; // can't be overdue on day 1

    final state = BillAccountsState.fromAccounts([
      account(dueDay: today - 1, nickname: 'Overdue', lastPaidAt: null),
      account(
        dueDay: today - 1,
        nickname: 'Paid',
        lastPaidAt: DateTime.now(),
      ),
    ]);

    expect(state.overdue.map((a) => a.nickname), contains('Overdue'));
    expect(state.overdue.map((a) => a.nickname), isNot(contains('Paid')));
  });
}
