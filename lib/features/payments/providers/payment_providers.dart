import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/utility_types.dart';
import '../../../firebase_options.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/sync_service_provider.dart';
import '../../bills/providers/bill_providers.dart';
import '../data/models/payment_record.dart';
import '../data/repositories/payment_repository.dart';

export '../data/models/payment_record.dart' show MonthlyTotal;

/// Payment portal URLs — Remote Config when Firebase is ready, else local defaults.
final remoteConfigProvider = FutureProvider<Map<String, String>>((ref) async {
  if (!DefaultFirebaseOptions.isConfigured || Firebase.apps.isEmpty) {
    return Map<String, String>.from(kDefaultPaymentUrls);
  }

  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 6),
      ),
    );
    await remoteConfig.setDefaults(
      kDefaultPaymentUrls.map((k, v) => MapEntry('payment_url_$k', v)),
    );
    await remoteConfig.fetchAndActivate();

    return {
      for (final type in UtilityType.values)
        type.name: remoteConfig.getString('payment_url_${type.name}').isNotEmpty
            ? remoteConfig.getString('payment_url_${type.name}')
            : (kDefaultPaymentUrls[type.name] ?? ''),
    };
  } catch (e, st) {
    debugPrint('Remote Config unavailable, using defaults: $e\n$st');
    return Map<String, String>.from(kDefaultPaymentUrls);
  }
});

class PaymentHistoryNotifier extends AsyncNotifier<List<PaymentRecord>> {
  PaymentRepository get _repo => ref.read(paymentRepositoryProvider);
  String? _currentBillId;

  void setBillId(String billId) {
    _currentBillId = billId;
    ref.invalidateSelf();
  }

  @override
  Future<List<PaymentRecord>> build() async {
    if (_currentBillId == null) return [];
    return _repo.getByBillAccount(_currentBillId!);
  }

  Future<void> addRecord(PaymentRecord record) async {
    await _repo.insert(record);
    await ref.read(billRepositoryProvider).updateLastPaid(
          record.billAccountId,
          record.paidAt,
        );
    ref.invalidate(billAccountsProvider);
    ref.invalidate(billPaymentHistoryProvider(record.billAccountId));
    ref.invalidate(monthlyTotalsProvider(record.paidAt.year));
    // Keep list scoped to the bill that was just paid when possible.
    _currentBillId ??= record.billAccountId;
    ref.invalidateSelf();
    // ignore: unawaited_futures
    ref.read(firestoreSyncServiceProvider).pushPendingPayments(
          ref.read(paymentRepositoryProvider),
        );
  }

  Future<void> deleteRecord(PaymentRecord record) async {
    await _repo.delete(record.id);
    ref.invalidate(billPaymentHistoryProvider(record.billAccountId));
    ref.invalidate(monthlyTotalsProvider(record.paidAt.year));
    ref.invalidateSelf();
  }
}

final paymentHistoryProvider =
    AsyncNotifierProvider<PaymentHistoryNotifier, List<PaymentRecord>>(
  PaymentHistoryNotifier.new,
);

/// Per-bill payment history (preferred for history screen).
final billPaymentHistoryProvider =
    FutureProvider.family<List<PaymentRecord>, String>((ref, billId) async {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getByBillAccount(billId);
});

/// Analytics year selector.
final selectedAnalyticsYearProvider = StateProvider<int>((ref) {
  return DateTime.now().year;
});

/// Monthly spend totals for a calendar year.
final monthlyTotalsProvider =
    FutureProvider.family<List<MonthlyTotal>, int>((ref, year) async {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getMonthlyTotals(year);
});
