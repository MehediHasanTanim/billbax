import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/repository_providers.dart';
import '../../../providers/sync_service_provider.dart';
import '../data/models/bill_account.dart';
import '../data/repositories/bill_repository.dart';

class BillAccountsState {
  final List<BillAccount> accounts;
  final List<BillAccount> dueSoon; // due within 5 days
  final List<BillAccount> overdue; // past due day, unpaid this month

  const BillAccountsState({
    required this.accounts,
    required this.dueSoon,
    required this.overdue,
  });

  static BillAccountsState fromAccounts(List<BillAccount> accounts) {
    final now = DateTime.now();
    final today = now.day;

    final dueSoon = accounts.where((a) {
      if (a.typicalDueDay == null) return false;
      final daysUntilDue = a.typicalDueDay! - today;
      return daysUntilDue >= 0 && daysUntilDue <= 5;
    }).toList();

    final overdue = accounts.where((a) {
      if (a.typicalDueDay == null) return false;
      return a.typicalDueDay! < today &&
          (a.lastPaidAt == null ||
              a.lastPaidAt!.year != now.year ||
              a.lastPaidAt!.month != now.month);
    }).toList();

    return BillAccountsState(
      accounts: accounts,
      dueSoon: dueSoon,
      overdue: overdue,
    );
  }
}

class BillAccountsNotifier extends AsyncNotifier<BillAccountsState> {
  BillRepository get _repo => ref.read(billRepositoryProvider);

  @override
  Future<BillAccountsState> build() async {
    final accounts = await _repo.getAll();
    return BillAccountsState.fromAccounts(accounts);
  }

  Future<void> addAccount(BillAccount account) async {
    state = const AsyncLoading();
    await _repo.insert(account);
    state = await AsyncValue.guard(_reload);
    // ignore: unawaited_futures
    ref.read(firestoreSyncServiceProvider).pushBillAccount(account);
  }

  Future<void> updateAccount(BillAccount account) async {
    await _repo.update(account);
    state = await AsyncValue.guard(_reload);
    // ignore: unawaited_futures
    ref.read(firestoreSyncServiceProvider).pushBillAccount(account);
  }

  Future<void> deleteAccount(String id) async {
    await _repo.softDelete(id);
    state = await AsyncValue.guard(_reload);
    // ignore: unawaited_futures
    ref.read(firestoreSyncServiceProvider).softDeleteRemoteBill(id);
  }

  Future<void> markPaid(String id) async {
    await _repo.updateLastPaid(id, DateTime.now());
    state = await AsyncValue.guard(_reload);
  }

  Future<BillAccountsState> _reload() async {
    final accounts = await _repo.getAll();
    return BillAccountsState.fromAccounts(accounts);
  }
}

final billAccountsProvider =
    AsyncNotifierProvider<BillAccountsNotifier, BillAccountsState>(
  BillAccountsNotifier.new,
);

/// Looks up a single active/inactive account from current list state.
final billByIdProvider = Provider.family<BillAccount?, String>((ref, id) {
  final state = ref.watch(billAccountsProvider).valueOrNull;
  if (state == null) return null;
  for (final account in state.accounts) {
    if (account.id == id) return account;
  }
  return null;
});
