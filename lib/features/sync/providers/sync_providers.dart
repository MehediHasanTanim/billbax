import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/repository_providers.dart';
import '../../../providers/sync_service_provider.dart';
import '../../bills/data/models/bill_account.dart';
import '../../bills/providers/bill_providers.dart';
import '../../payments/providers/payment_providers.dart';
import '../services/firestore_sync_service.dart';

sealed class SyncState {
  const SyncState();
}

class SyncIdle extends SyncState {
  const SyncIdle();
}

class SyncInProgress extends SyncState {
  const SyncInProgress();
}

class SyncSuccess extends SyncState {
  const SyncSuccess(this.message);

  final String message;
}

class SyncError extends SyncState {
  const SyncError(this.message);

  final String message;
}

class SyncNotifier extends AsyncNotifier<SyncState> {
  @override
  Future<SyncState> build() async => const SyncIdle();

  FirestoreSyncService get _service => ref.read(firestoreSyncServiceProvider);

  Future<void> syncOnLogin() async {
    if (!_service.isAvailable || _service.currentUser == null) {
      debugPrint('syncOnLogin skipped');
      return;
    }

    state = const AsyncData(SyncInProgress());
    try {
      final count = await _service.syncOnLogin(
        ref.read(billRepositoryProvider),
        ref.read(paymentRepositoryProvider),
      );
      ref.invalidate(billAccountsProvider);
      ref.invalidate(paymentHistoryProvider);
      state = AsyncData(SyncSuccess('$countটি বিল সিঙ্ক হয়েছে'));
    } catch (e, st) {
      debugPrint('syncOnLogin failed: $e\n$st');
      state = AsyncData(SyncError(e.toString()));
    }
  }

  Future<void> pushBill(BillAccount account) async {
    try {
      await _service.pushBillAccount(account);
    } catch (e, st) {
      debugPrint('pushBill failed: $e\n$st');
    }
  }

  Future<void> pushPendingPayments() async {
    try {
      await _service.pushPendingPayments(ref.read(paymentRepositoryProvider));
    } catch (e, st) {
      debugPrint('pushPendingPayments failed: $e\n$st');
    }
  }

  Future<void> softDeleteRemoteBill(String id) async {
    try {
      await _service.softDeleteRemoteBill(id);
    } catch (e, st) {
      debugPrint('softDeleteRemoteBill failed: $e\n$st');
    }
  }
}

final syncNotifierProvider =
    AsyncNotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
