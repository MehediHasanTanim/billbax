import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bilbax/core/database/database_helper.dart';
import 'package:bilbax/features/bills/data/models/bill_account.dart';
import 'package:bilbax/features/bills/providers/bill_providers.dart';
import 'package:bilbax/features/notifications/services/reminder_service.dart';
import 'package:bilbax/providers/core_providers.dart';

class FakeReminderService extends ReminderService {
  final List<String> scheduledBillIds = [];
  final List<String> cancelledBillIds = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleMonthlyReminder({
    required int notificationId,
    required String billNickname,
    required int dayOfMonth,
    required String billId,
  }) async {
    scheduledBillIds.add(billId);
  }

  @override
  Future<void> cancelForBill(String billId) async {
    cancelledBillIds.add(billId);
  }

  @override
  Future<void> rescheduleAll(List<BillAccount> accounts) async {
    for (final account in accounts) {
      if (account.typicalDueDay != null) {
        scheduledBillIds.add(account.id);
      }
    }
  }
}

void main() {
  late Database db;
  late FakeReminderService fakeReminders;
  late ProviderContainer container;

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

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await DatabaseHelper(inMemory: true).database;
    fakeReminders = FakeReminderService();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        reminderServiceProvider.overrideWithValue(fakeReminders),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  tearDown(() async {
    await db.close();
  });

  test('fromAccounts marks due soon within 5 days', () {
    final today = DateTime.now().day;
    final dueDay = (today + 3).clamp(1, 28);
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
    if (today <= 1) return;

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

  test('addAccount loads new account into state and schedules reminder', () async {
    await container.read(billAccountsProvider.future);

    await container.read(billAccountsProvider.notifier).addAccount(
          BillAccount.create(
            utilityType: UtilityType.desco,
            accountNumber: '111222',
            nickname: 'Test',
            typicalDueDay: 15,
          ),
        );

    final state = await container.read(billAccountsProvider.future);
    expect(state.accounts.length, 1);
    expect(state.accounts.first.nickname, 'Test');
    expect(fakeReminders.scheduledBillIds, hasLength(1));
  });

  test('deleteAccount soft-deletes and cancels reminder', () async {
    await container.read(billAccountsProvider.future);
    final created = BillAccount.create(
      utilityType: UtilityType.wasa,
      accountNumber: '999',
      nickname: 'Water',
      typicalDueDay: 10,
    );
    await container.read(billAccountsProvider.notifier).addAccount(created);

    await container.read(billAccountsProvider.notifier).deleteAccount(created.id);

    final active = await container.read(billAccountsProvider.future);
    expect(active.accounts, isEmpty);
    expect(fakeReminders.cancelledBillIds, contains(created.id));
  });
}
