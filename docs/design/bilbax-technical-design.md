# বিলবাক্স (BilBax) — Full Technical Design

**Version:** 1.0  
**Platform:** Flutter (Android-first, iOS-compatible)  
**Architecture:** Offline-first · Local SQLite · Firebase sync · url_launcher redirects  
**State Management:** Riverpod (flutter_riverpod + riverpod_annotation)  
**Last Updated:** October 2026

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Flutter Project Structure](#flutter-project-structure)
3. [State Management — Riverpod](#state-management--riverpod)
4. [Data Layer — SQLite with sqflite](#data-layer--sqlite-with-sqflite)
5. [Firestore Sync Strategy](#firestore-sync-strategy)
6. [Payment Redirect System](#payment-redirect-system)
7. [Firebase Remote Config](#firebase-remote-config)
8. [Push Notifications — FCM + Local Notifications](#push-notifications--fcm--local-notifications)
9. [Navigation Architecture](#navigation-architecture)
10. [Flutter Package Dependencies](#flutter-package-dependencies)
11. [Environment Configuration](#environment-configuration)
12. [Testing Strategy](#testing-strategy)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter UI Layer                     │
│   Screens → ConsumerWidget → ref.watch(provider)        │
└───────────────────────┬─────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────┐
│               Riverpod Provider Layer                    │
│   billsProvider · paymentProvider · analyticsProvider   │
│   authProvider · syncProvider · remoteConfigProvider    │
└──────┬────────────────┬──────────────────────────────────┘
       │                │
┌──────▼──────┐  ┌──────▼──────────────────────────────────┐
│  Repository │  │         Repository Layer                  │
│  Providers  │  │  billRepositoryProvider                  │
│             │  │  paymentRepositoryProvider               │
│             │  │  authRepositoryProvider                  │
└──────┬──────┘  └──────┬──────────────────────────────────┘
       │                │
┌──────▼──────┐  ┌──────▼──────────────────────────────────┐
│  Local Data │  │         Remote Data Sources              │
│  ─────────  │  │  ──────────────────────────────────────  │
│  sqflite    │  │  Firebase Auth (phone OTP)               │
│  (SQLite)   │  │  Firestore (cloud sync)                  │
│  shared_    │  │  FCM (push notifications)                │
│  prefs      │  │  Remote Config (payment URLs)            │
└─────────────┘  └──────────────────────────────────────────┘
                        │
              ┌─────────▼──────────┐
              │  External Services  │
              │  ─────────────────  │
              │  url_launcher →     │
              │  bKash / DESCO /    │
              │  DPDC / WASA /      │
              │  Titas portals      │
              └────────────────────┘
```

### Key architectural decisions

| Decision | Choice | Reason |
|---|---|---|
| No custom backend | Firebase + local SQLite only | App never touches payments; no API key risk |
| Offline-first | SQLite as source of truth | Bangladeshi users face patchy connectivity |
| State management | Riverpod | Less boilerplate than BLoC; compile-safe providers; easy async with `AsyncNotifier` |
| Sync strategy | Pull-on-login + push-on-write | Simple; avoids real-time listener cost |
| Payment flow | url_launcher → external app/browser | Zero liability; always up-to-date on operator side |

---

## 2. Flutter Project Structure

```
lib/
├── main.dart                    # App entry point, ProviderScope
├── app.dart                     # MaterialApp.router, theme, go_router
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart     # All UI strings (Bangla + English)
│   │   ├── utility_types.dart   # Enum: desco, dpdc, wasa, titas, internet, btcl
│   │   └── route_names.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── dark_theme.dart
│   ├── utils/
│   │   ├── date_formatter.dart
│   │   ├── currency_formatter.dart
│   │   └── validators.dart
│   └── errors/
│       ├── failures.dart        # Sealed class: LocalFailure, NetworkFailure
│       └── exceptions.dart
│
├── data/
│   ├── local/
│   │   ├── database_helper.dart # sqflite singleton + migrations
│   │   ├── dao/
│   │   │   ├── bill_account_dao.dart
│   │   │   ├── payment_history_dao.dart
│   │   │   └── property_group_dao.dart
│   │   └── models/
│   │       ├── bill_account_model.dart
│   │       ├── payment_history_model.dart
│   │       └── property_group_model.dart
│   ├── remote/
│   │   ├── firestore_service.dart
│   │   ├── auth_service.dart
│   │   ├── fcm_service.dart
│   │   └── remote_config_service.dart
│   └── repositories/
│       ├── bill_repository_impl.dart
│       ├── payment_repository_impl.dart
│       └── auth_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── bill_account.dart
│   │   ├── payment_record.dart
│   │   └── property_group.dart
│   └── repositories/
│       ├── bill_repository.dart   # Abstract interfaces
│       ├── payment_repository.dart
│       └── auth_repository.dart
│
├── providers/                   # All Riverpod providers
│   ├── core_providers.dart      # DB, DAOs, services
│   ├── repository_providers.dart
│   ├── bill_providers.dart
│   ├── payment_providers.dart
│   ├── analytics_providers.dart
│   ├── auth_providers.dart
│   └── sync_providers.dart
│
└── presentation/
    └── screens/
        ├── home/
        │   ├── home_screen.dart
        │   └── widgets/
        │       ├── bill_card.dart
        │       ├── due_badge.dart
        │       └── quick_pay_button.dart
        ├── add_bill/
        │   ├── add_bill_screen.dart
        │   └── widgets/
        │       └── utility_type_picker.dart
        ├── payment_redirect/
        │   ├── payment_redirect_screen.dart
        │   └── log_payment_sheet.dart
        ├── history/
        │   ├── history_screen.dart
        │   └── widgets/
        │       └── payment_list_tile.dart
        ├── analytics/
        │   ├── analytics_screen.dart
        │   └── widgets/
        │       ├── monthly_bar_chart.dart
        │       └── category_pie_chart.dart
        ├── settings/
        │   └── settings_screen.dart
        └── auth/
            ├── phone_entry_screen.dart
            └── otp_screen.dart
```

---

## 3. State Management — Riverpod

### 3.1 Provider Setup (main.dart)

```dart
// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
  runApp(
    const ProviderScope(   // Wraps entire app — required by Riverpod
      child: BilBaxApp(),
    ),
  );
}
```

### 3.2 Core Infrastructure Providers

```dart
// providers/core_providers.dart

// Database singleton
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

// DAOs
final billAccountDaoProvider = Provider<BillAccountDao>((ref) {
  return BillAccountDao(ref.watch(databaseHelperProvider));
});

final paymentHistoryDaoProvider = Provider<PaymentHistoryDao>((ref) {
  return PaymentHistoryDao(ref.watch(databaseHelperProvider));
});

// Remote services
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService(FirebaseRemoteConfig.instance);
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService(FlutterLocalNotificationsPlugin());
});

final paymentUrlResolverProvider = Provider<PaymentUrlResolver>((ref) {
  return PaymentUrlResolver(ref.watch(remoteConfigServiceProvider));
});
```

### 3.3 Repository Providers

```dart
// providers/repository_providers.dart

final billRepositoryProvider = Provider<BillRepository>((ref) {
  return BillRepositoryImpl(
    billDao: ref.watch(billAccountDaoProvider),
    paymentDao: ref.watch(paymentHistoryDaoProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(
    paymentDao: ref.watch(paymentHistoryDaoProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    FirebaseAuth.instance,
    ref.watch(firestoreServiceProvider),
  );
});
```

### 3.4 Bill Accounts — AsyncNotifier

`AsyncNotifier` is the Riverpod way to manage async state that can be mutated. It replaces the BLoC load/add/update/delete pattern cleanly.

```dart
// providers/bill_providers.dart

// The main bills state notifier
class BillAccountsNotifier extends AsyncNotifier<BillAccountsState> {
  @override
  Future<BillAccountsState> build() async {
    return _loadAccounts();
  }

  Future<BillAccountsState> _loadAccounts() async {
    final repo = ref.read(billRepositoryProvider);
    final accounts = await repo.getAllAccounts();
    final now = DateTime.now();

    final dueSoon = accounts.where((a) {
      if (a.typicalDueDay == null) return false;
      final dueDate = DateTime(now.year, now.month, a.typicalDueDay!);
      final diff = dueDate.difference(now).inDays;
      return diff >= 0 && diff <= 7;
    }).toList();

    final overdue = accounts.where((a) {
      if (a.typicalDueDay == null) return false;
      final dueDate = DateTime(now.year, now.month, a.typicalDueDay!);
      return dueDate.isBefore(now) &&
        (a.lastPaidAt == null ||
         a.lastPaidAt!.isBefore(DateTime(now.year, now.month, 1)));
    }).toList();

    return BillAccountsState(
      accounts: accounts,
      dueSoon: dueSoon,
      overdue: overdue,
    );
  }

  Future<void> addAccount(BillAccount account) async {
    final repo = ref.read(billRepositoryProvider);
    final reminderService = ref.read(reminderServiceProvider);

    state = const AsyncLoading();
    final id = await repo.insertAccount(account);

    if (account.typicalDueDay != null) {
      await reminderService.scheduleMonthlyReminder(
        billId: id,
        dueDay: account.typicalDueDay!,
        billName: account.nickname,
      );
    }

    state = await AsyncValue.guard(_loadAccounts);
  }

  Future<void> updateAccount(BillAccount account) async {
    await ref.read(billRepositoryProvider).updateAccount(account);
    state = await AsyncValue.guard(_loadAccounts);
  }

  Future<void> deleteAccount(int id) async {
    await ref.read(billRepositoryProvider).softDelete(id);
    await ref.read(reminderServiceProvider).cancelReminder(id);
    state = await AsyncValue.guard(_loadAccounts);
  }

  Future<void> markPaid({
    required int billId,
    required double amount,
    String? note,
  }) async {
    final repo = ref.read(billRepositoryProvider);
    final reminderService = ref.read(reminderServiceProvider);

    await repo.markPaid(billId: billId, amount: amount, note: note);

    // Reschedule reminder for next month
    final currentState = state.valueOrNull;
    if (currentState != null) {
      final bill = currentState.accounts.firstWhere((b) => b.id == billId);
      if (bill.typicalDueDay != null) {
        await reminderService.scheduleMonthlyReminder(
          billId: billId,
          dueDay: bill.typicalDueDay!,
          billName: bill.nickname,
        );
      }
    }

    state = await AsyncValue.guard(_loadAccounts);
  }
}

// The provider — used throughout the app
final billAccountsProvider =
  AsyncNotifierProvider<BillAccountsNotifier, BillAccountsState>(
    BillAccountsNotifier.new,
  );

// Derived computed providers — no extra notifier needed
final dueSoonBillsProvider = Provider<List<BillAccount>>((ref) {
  return ref.watch(billAccountsProvider).valueOrNull?.dueSoon ?? [];
});

final overdueBillsProvider = Provider<List<BillAccount>>((ref) {
  return ref.watch(billAccountsProvider).valueOrNull?.overdue ?? [];
});
```

```dart
// domain/entities — state class (plain Dart)
class BillAccountsState {
  final List<BillAccount> accounts;
  final List<BillAccount> dueSoon;
  final List<BillAccount> overdue;

  const BillAccountsState({
    required this.accounts,
    required this.dueSoon,
    required this.overdue,
  });
}
```

### 3.5 Payment History — AsyncNotifier

```dart
// providers/payment_providers.dart

// Notifier for the full payment log
class PaymentHistoryNotifier extends AsyncNotifier<List<PaymentRecord>> {
  @override
  Future<List<PaymentRecord>> build() async {
    final repo = ref.read(paymentRepositoryProvider);
    return repo.getAll();
  }

  Future<void> addRecord({
    required int billId,
    required double amount,
    String? note,
    DateTime? paidAt,
  }) async {
    final repo = ref.read(paymentRepositoryProvider);
    await repo.insert(PaymentRecord(
      billAccountId: billId,
      amount: amount,
      note: note,
      paidAt: paidAt ?? DateTime.now(),
    ));

    // Refresh bill accounts list (last_paid_at changed)
    ref.invalidate(billAccountsProvider);

    // Refresh payment list
    ref.invalidateSelf();
  }

  Future<void> deleteRecord(int id) async {
    await ref.read(paymentRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

final paymentHistoryProvider =
  AsyncNotifierProvider<PaymentHistoryNotifier, List<PaymentRecord>>(
    PaymentHistoryNotifier.new,
  );

// Per-bill payment history — family provider
final billPaymentHistoryProvider =
  FutureProvider.family<List<PaymentRecord>, int>((ref, billId) async {
    final repo = ref.read(paymentRepositoryProvider);
    return repo.getForBill(billId);
  });

// Monthly total — computed
final monthlyTotalProvider = FutureProvider.family<double, ({int year, int month})>(
  (ref, args) async {
    final repo = ref.read(paymentRepositoryProvider);
    return repo.getTotalForMonth(args.year, args.month);
  },
);
```

### 3.6 Analytics — FutureProvider

No mutable state needed — pure read from SQLite.

```dart
// providers/analytics_providers.dart

// All monthly totals for a given year
final monthlyTotalsProvider = FutureProvider.family<List<MonthlyTotal>, int>(
  (ref, year) async {
    final dao = ref.read(paymentHistoryDaoProvider);
    final rows = await dao.getMonthlyTotals(year);
    return rows.map((r) => MonthlyTotal(
      month: r['month'] as int,
      total: (r['total'] as num).toDouble(),
    )).toList();
  },
);

// Totals by utility category for a given year
final categoryTotalsProvider =
  FutureProvider.family<Map<UtilityType, double>, int>((ref, year) async {
    final dao = ref.read(paymentHistoryDaoProvider);
    final rows = await dao.getTotalsByCategory(year);
    return {
      for (final r in rows)
        UtilityType.values.byName(r['utility_type'] as String):
          (r['total'] as num).toDouble(),
    };
  });

// Selected analytics year — StateProvider (simple mutable value)
final selectedAnalyticsYearProvider = StateProvider<int>((ref) {
  return DateTime.now().year;
});
```

### 3.7 Auth — StateNotifier

```dart
// providers/auth_providers.dart

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? AuthState.authenticated(user.uid) : const AuthState.unauthenticated();
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).sendOtp(phoneNumber);
      state = const AsyncData(AuthState.otpSent());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> verifyOtp(String verificationId, String smsCode) async {
    state = const AsyncLoading();
    try {
      final uid = await ref.read(authRepositoryProvider)
        .verifyOtp(verificationId, smsCode);
      state = AsyncData(AuthState.authenticated(uid));

      // Trigger Firestore pull after login
      await ref.read(syncNotifierProvider.notifier).pullFromFirestore();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    state = const AsyncData(AuthState.unauthenticated());
  }
}

final authProvider =
  AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Convenience boolean provider
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).valueOrNull?.isAuthenticated ?? false;
});
```

```dart
// Sealed auth state
sealed class AuthState {
  const AuthState();
  const factory AuthState.unauthenticated() = Unauthenticated;
  const factory AuthState.otpSent() = OtpSent;
  const factory AuthState.authenticated(String uid) = Authenticated;

  bool get isAuthenticated => this is Authenticated;
}
class Unauthenticated extends AuthState { const Unauthenticated(); }
class OtpSent extends AuthState { const OtpSent(); }
class Authenticated extends AuthState {
  final String uid;
  const Authenticated(this.uid);
}
```

### 3.8 Sync — AsyncNotifier

```dart
// providers/sync_providers.dart

sealed class SyncState {
  const SyncState();
}
class SyncIdle extends SyncState { const SyncIdle(); }
class SyncInProgress extends SyncState { const SyncInProgress(); }
class SyncSuccess extends SyncState {
  final int count;
  const SyncSuccess(this.count);
}
class SyncError extends SyncState {
  final String message;
  const SyncError(this.message);
}

class SyncNotifier extends AsyncNotifier<SyncState> {
  @override
  Future<SyncState> build() async => const SyncIdle();

  Future<void> pushUnsynced() async {
    if (!ref.read(isLoggedInProvider)) return;

    state = const AsyncData(SyncInProgress());
    try {
      final dao = ref.read(billAccountDaoProvider);
      final firestore = ref.read(firestoreServiceProvider);
      final db = ref.read(databaseHelperProvider);

      final unsynced = await dao.getUnsynced();
      for (final model in unsynced) {
        final fsId = await firestore.uploadBillAccount(model);
        final database = await db.database;
        await database.update(
          'bill_accounts',
          {
            'firestore_id': fsId,
            'synced_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [model.id],
        );
      }
      state = AsyncData(SyncSuccess(unsynced.length));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> pullFromFirestore() async {
    if (!ref.read(isLoggedInProvider)) return;

    state = const AsyncData(SyncInProgress());
    try {
      final firestore = ref.read(firestoreServiceProvider);
      final db = ref.read(databaseHelperProvider);

      final remote = await firestore.fetchAllBillAccounts();
      final database = await db.database;

      for (final item in remote) {
        final existing = await database.query(
          'bill_accounts',
          where: 'firestore_id = ?',
          whereArgs: [item['id']],
        );
        final data = _mapFirestoreToLocal(item);
        if (existing.isEmpty) {
          await database.insert('bill_accounts', data);
        } else {
          await database.update(
            'bill_accounts',
            data,
            where: 'firestore_id = ?',
            whereArgs: [item['id']],
          );
        }
      }

      // Refresh bill list after pull
      ref.invalidate(billAccountsProvider);

      state = AsyncData(SyncSuccess(remote.length));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Map<String, dynamic> _mapFirestoreToLocal(Map<String, dynamic> item) => {
    'utility_type': item['utilityType'],
    'account_number': item['accountNumber'],
    'nickname': item['nickname'],
    'area': item['area'],
    'typical_due_day': item['typicalDueDay'],
    'is_active': item['isActive'] == true ? 1 : 0,
    'last_paid_at':
      (item['lastPaidAt'] as Timestamp?)?.toDate().toIso8601String(),
    'firestore_id': item['id'],
    'synced_at': DateTime.now().toIso8601String(),
    'created_at': DateTime.now().toIso8601String(),
  };
}

final syncNotifierProvider =
  AsyncNotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
```

### 3.9 Using Providers in UI — ConsumerWidget

```dart
// presentation/screens/home/home_screen.dart
class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billAccountsProvider);

    return billsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (state) => CustomScrollView(
        slivers: [
          // Due soon / overdue alerts
          if (state.overdue.isNotEmpty)
            SliverToBoxAdapter(
              child: OverdueWarningBanner(bills: state.overdue),
            ),
          if (state.dueSoon.isNotEmpty)
            SliverToBoxAdapter(
              child: DueSoonBanner(bills: state.dueSoon),
            ),
          // All bill cards
          SliverList.builder(
            itemCount: state.accounts.length,
            itemBuilder: (_, i) => BillCard(
              bill: state.accounts[i],
              onPayTap: () => context.push('/pay/${state.accounts[i].id}'),
            ),
          ),
        ],
      ),
    );
  }
}
```

```dart
// Add bill screen — ConsumerStatefulWidget for form state
class AddBillScreen extends ConsumerStatefulWidget {
  const AddBillScreen({super.key});

  @override
  ConsumerState<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends ConsumerState<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  UtilityType? _selectedType;
  final _accountController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _areaController = TextEditingController();
  int? _dueDay;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) return;

    await ref.read(billAccountsProvider.notifier).addAccount(
      BillAccount(
        utilityType: _selectedType!,
        accountNumber: _accountController.text.trim(),
        nickname: _nicknameController.text.trim(),
        area: _areaController.text.trim().isEmpty ? null : _areaController.text.trim(),
        typicalDueDay: _dueDay,
        createdAt: DateTime.now(),
      ),
    );

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the bills state to show loading indicator on submit
    final isLoading = ref.watch(billAccountsProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('নতুন বিল যোগ করুন')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            UtilityTypePicker(
              selected: _selectedType,
              onSelected: (t) => setState(() => _selectedType = t),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountController,
              decoration: const InputDecoration(
                labelText: 'অ্যাকাউন্ট/কনজিউমার নম্বর',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'নম্বর দিন' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'নাম (যেমন: বাসা, অফিস)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'নাম দিন' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'এলাকা (ঐচ্ছিক)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DueDayPicker(
              value: _dueDay,
              onChanged: (d) => setState(() => _dueDay = d),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('সেভ করুন', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3.10 Analytics Screen — watching family providers

```dart
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedYear = ref.watch(selectedAnalyticsYearProvider);
    final monthlyAsync = ref.watch(monthlyTotalsProvider(selectedYear));
    final categoryAsync = ref.watch(categoryTotalsProvider(selectedYear));

    return Scaffold(
      appBar: AppBar(
        title: const Text('ব্যয় বিশ্লেষণ'),
        actions: [
          YearPicker(
            year: selectedYear,
            onChanged: (y) =>
              ref.read(selectedAnalyticsYearProvider.notifier).state = y,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          monthlyAsync.when(
            loading: () => const ShimmerChart(),
            error: (e, _) => Text('Error: $e'),
            data: (totals) => MonthlyBarChart(totals: totals, year: selectedYear),
          ),
          const SizedBox(height: 24),
          categoryAsync.when(
            loading: () => const ShimmerPie(),
            error: (e, _) => Text('Error: $e'),
            data: (byCategory) => CategoryPieChart(data: byCategory),
          ),
        ],
      ),
    );
  }
}
```

---

## 4. Data Layer — SQLite with sqflite

### 4.1 DatabaseHelper — Singleton with Migrations

```dart
// data/local/database_helper.dart
class DatabaseHelper {
  static const _dbName = 'bilbax.db';
  static const _dbVersion = 1;
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance ??= DatabaseHelper._internal();

  Future<Database> get database async =>
    _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bill_accounts (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        utility_type    TEXT NOT NULL,
        account_number  TEXT NOT NULL,
        nickname        TEXT NOT NULL,
        area            TEXT,
        typical_due_day INTEGER,
        is_active       INTEGER NOT NULL DEFAULT 1,
        property_group_id INTEGER,
        created_at      TEXT NOT NULL,
        last_paid_at    TEXT,
        firestore_id    TEXT,
        synced_at       TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_history (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_account_id INTEGER NOT NULL,
        amount          REAL NOT NULL,
        paid_at         TEXT NOT NULL,
        note            TEXT,
        firestore_id    TEXT,
        synced_at       TEXT,
        FOREIGN KEY (bill_account_id) REFERENCES bill_accounts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE property_groups (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT NOT NULL,
        description TEXT,
        created_at  TEXT NOT NULL
      )
    ''');

    // Indexes for common queries
    await db.execute(
      'CREATE INDEX idx_payment_history_bill_id ON payment_history(bill_account_id)');
    await db.execute(
      'CREATE INDEX idx_payment_history_paid_at ON payment_history(paid_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
  }
}
```

### 4.2 BillAccountDao

```dart
// data/local/dao/bill_account_dao.dart
class BillAccountDao {
  final DatabaseHelper _dbHelper;
  BillAccountDao(this._dbHelper);

  Future<List<BillAccountModel>> getAllActive() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'bill_accounts',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'typical_due_day ASC, nickname ASC',
    );
    return maps.map(BillAccountModel.fromMap).toList();
  }

  Future<int> insert(BillAccountModel model) async {
    final db = await _dbHelper.database;
    return db.insert('bill_accounts', model.toMap());
  }

  Future<void> update(BillAccountModel model) async {
    final db = await _dbHelper.database;
    await db.update(
      'bill_accounts',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> markPaid(int id, DateTime paidAt) async {
    final db = await _dbHelper.database;
    await db.update(
      'bill_accounts',
      {'last_paid_at': paidAt.toIso8601String(), 'synced_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> softDelete(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      'bill_accounts',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<BillAccountModel>> getUnsynced() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'bill_accounts',
      where: 'synced_at IS NULL OR last_paid_at > synced_at',
    );
    return maps.map(BillAccountModel.fromMap).toList();
  }
}
```

### 4.3 BillAccountModel

```dart
// data/local/models/bill_account_model.dart
class BillAccountModel {
  final int? id;
  final String utilityType;
  final String accountNumber;
  final String nickname;
  final String? area;
  final int? typicalDueDay;
  final bool isActive;
  final int? propertyGroupId;
  final DateTime createdAt;
  final DateTime? lastPaidAt;
  final String? firestoreId;
  final DateTime? syncedAt;

  const BillAccountModel({
    this.id,
    required this.utilityType,
    required this.accountNumber,
    required this.nickname,
    this.area,
    this.typicalDueDay,
    this.isActive = true,
    this.propertyGroupId,
    required this.createdAt,
    this.lastPaidAt,
    this.firestoreId,
    this.syncedAt,
  });

  factory BillAccountModel.fromMap(Map<String, dynamic> map) =>
    BillAccountModel(
      id: map['id'] as int?,
      utilityType: map['utility_type'] as String,
      accountNumber: map['account_number'] as String,
      nickname: map['nickname'] as String,
      area: map['area'] as String?,
      typicalDueDay: map['typical_due_day'] as int?,
      isActive: (map['is_active'] as int) == 1,
      propertyGroupId: map['property_group_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastPaidAt: map['last_paid_at'] != null
        ? DateTime.parse(map['last_paid_at'] as String) : null,
      firestoreId: map['firestore_id'] as String?,
      syncedAt: map['synced_at'] != null
        ? DateTime.parse(map['synced_at'] as String) : null,
    );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'utility_type': utilityType,
    'account_number': accountNumber,
    'nickname': nickname,
    'area': area,
    'typical_due_day': typicalDueDay,
    'is_active': isActive ? 1 : 0,
    'property_group_id': propertyGroupId,
    'created_at': createdAt.toIso8601String(),
    'last_paid_at': lastPaidAt?.toIso8601String(),
    'firestore_id': firestoreId,
    'synced_at': syncedAt?.toIso8601String(),
  };

  BillAccount toEntity() => BillAccount(
    id: id,
    utilityType: UtilityType.values.byName(utilityType),
    accountNumber: accountNumber,
    nickname: nickname,
    area: area,
    typicalDueDay: typicalDueDay,
    isActive: isActive,
    lastPaidAt: lastPaidAt,
    createdAt: createdAt,
  );

  factory BillAccountModel.fromEntity(BillAccount e) => BillAccountModel(
    id: e.id,
    utilityType: e.utilityType.name,
    accountNumber: e.accountNumber,
    nickname: e.nickname,
    area: e.area,
    typicalDueDay: e.typicalDueDay,
    isActive: e.isActive,
    createdAt: e.createdAt,
    lastPaidAt: e.lastPaidAt,
  );
}
```

### 4.4 PaymentHistoryDao

```dart
class PaymentHistoryDao {
  final DatabaseHelper _dbHelper;
  PaymentHistoryDao(this._dbHelper);

  Future<List<PaymentHistoryModel>> getAll({int limit = 100}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payment_history',
      orderBy: 'paid_at DESC',
      limit: limit,
    );
    return maps.map(PaymentHistoryModel.fromMap).toList();
  }

  Future<List<PaymentHistoryModel>> getForBill(int billId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payment_history',
      where: 'bill_account_id = ?',
      whereArgs: [billId],
      orderBy: 'paid_at DESC',
    );
    return maps.map(PaymentHistoryModel.fromMap).toList();
  }

  Future<int> insert(PaymentHistoryModel model) async {
    final db = await _dbHelper.database;
    return db.insert('payment_history', model.toMap());
  }

  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    await db.delete('payment_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalForMonth(int year, int month) async {
    final db = await _dbHelper.database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM payment_history WHERE paid_at >= ? AND paid_at < ?',
      [start, end],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getMonthlyTotals(int year) async {
    final db = await _dbHelper.database;
    return db.rawQuery('''
      SELECT
        CAST(strftime('%m', paid_at) AS INTEGER) as month,
        SUM(amount) as total
      FROM payment_history
      WHERE strftime('%Y', paid_at) = ?
      GROUP BY strftime('%m', paid_at)
      ORDER BY month
    ''', [year.toString()]);
  }

  Future<List<Map<String, dynamic>>> getTotalsByCategory(int year) async {
    final db = await _dbHelper.database;
    return db.rawQuery('''
      SELECT
        ba.utility_type,
        SUM(ph.amount) as total
      FROM payment_history ph
      JOIN bill_accounts ba ON ph.bill_account_id = ba.id
      WHERE strftime('%Y', ph.paid_at) = ?
      GROUP BY ba.utility_type
    ''', [year.toString()]);
  }
}
```

---

## 5. Firestore Sync Strategy

### 5.1 Firestore Document Structure

```
Firestore
└── users/
    └── {uid}/
        ├── bill_accounts/
        │   └── {docId}/
        │       ├── utilityType: "desco"
        │       ├── accountNumber: "12345678"
        │       ├── nickname: "বাসা"
        │       ├── area: "Dhanmondi"
        │       ├── typicalDueDay: 15
        │       ├── isActive: true
        │       ├── lastPaidAt: Timestamp | null
        │       └── updatedAt: Timestamp
        └── payment_history/
            └── {docId}/
                ├── billAccountFirestoreId: "..."
                ├── amount: 1250.0
                ├── paidAt: Timestamp
                └── note: "সেপ্টেম্বর ২০২৬"
```

### 5.2 Sync Rules

```
Not logged in → SQLite only, full features, zero sync overhead
Logged in     → pull on login + push after every write

Conflict resolution: latest updatedAt / paidAt wins
New device: full pull on first login rebuilds local SQLite
```

### 5.3 FirestoreService

```dart
// data/remote/firestore_service.dart
class FirestoreService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FirestoreService(this._db, this._auth);

  String get _uid => _auth.currentUser!.uid;
  CollectionReference get _bills =>
    _db.collection('users').doc(_uid).collection('bill_accounts');

  Future<String> uploadBillAccount(BillAccountModel model) async {
    final data = {
      'utilityType': model.utilityType,
      'accountNumber': model.accountNumber,
      'nickname': model.nickname,
      'area': model.area,
      'typicalDueDay': model.typicalDueDay,
      'isActive': model.isActive,
      'lastPaidAt': model.lastPaidAt != null
        ? Timestamp.fromDate(model.lastPaidAt!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (model.firestoreId != null) {
      await _bills.doc(model.firestoreId).set(data, SetOptions(merge: true));
      return model.firestoreId!;
    } else {
      final ref = await _bills.add(data);
      return ref.id;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllBillAccounts() async {
    final snap = await _bills.where('isActive', isEqualTo: true).get();
    return snap.docs.map((d) =>
      {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
  }
}
```

### 5.4 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

---

## 6. Payment Redirect System

### 6.1 Flow

```
User taps "Pay Now"
  → PaymentRedirectScreen loads bill details
  → PaymentUrlResolver.resolve(utilityType, accountNumber)
      reads Remote Config template → substitutes account number
  → url_launcher.launchUrl
      tries bKash/Nagad deep link first
      falls back to Chrome Custom Tab (official web portal)
  → WidgetsBindingObserver detects app resume
  → LogPaymentSheet appears automatically
  → User logs amount → SQLite write → reminder reschedules
```

### 6.2 PaymentUrlResolver

```dart
// core/utils/payment_url_resolver.dart
class PaymentUrlResolver {
  static const Map<String, String> _defaults = {
    'desco':      'bkash://pay?service=desco&account={acc}',
    'dpdc':       'bkash://pay?service=dpdc&account={acc}',
    'wasa':       'bkash://pay?service=wasa&account={acc}',
    'titas':      'bkash://pay?service=titas&account={acc}',
    'desco_web':  'https://selfservice.desco.org.bd/bill-pay?acc={acc}',
    'dpdc_web':   'https://dpdc.org.bd/payment?consumer={acc}',
    'wasa_web':   'https://wasa.gov.bd/payment?acc={acc}',
    'titas_web':  'https://titasgas.org.bd/online-payment?acc={acc}',
    'btcl_web':   'https://www.btcl.gov.bd/payment?acc={acc}',
  };

  final RemoteConfigService _remoteConfig;
  PaymentUrlResolver(this._remoteConfig);

  Future<PaymentUrl> resolve(UtilityType type, String accountNumber) async {
    String _fill(String template) =>
      template.replaceAll('{acc}', accountNumber);

    final deepLinkTemplate = _remoteConfig.getString(type.name).isNotEmpty
      ? _remoteConfig.getString(type.name)
      : _defaults[type.name] ?? '';

    final webTemplate =
      _remoteConfig.getString('${type.name}_web').isNotEmpty
        ? _remoteConfig.getString('${type.name}_web')
        : _defaults['${type.name}_web'] ?? '';

    return PaymentUrl(
      deepLink: _fill(deepLinkTemplate),
      webFallback: _fill(webTemplate),
    );
  }
}

class PaymentUrl {
  final String deepLink;
  final String webFallback;
  const PaymentUrl({required this.deepLink, required this.webFallback});
}
```

### 6.3 Payment Redirect Screen

```dart
class PaymentRedirectScreen extends ConsumerStatefulWidget {
  final int billId;
  const PaymentRedirectScreen({required this.billId, super.key});

  @override
  ConsumerState<PaymentRedirectScreen> createState() =>
    _PaymentRedirectScreenState();
}

class _PaymentRedirectScreenState
    extends ConsumerState<PaymentRedirectScreen>
    with WidgetsBindingObserver {

  bool _didLaunch = false;
  bool _returned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _didLaunch) {
      setState(() => _returned = true);
      _showLogSheet();
    }
  }

  BillAccount _getBill() {
    final state = ref.read(billAccountsProvider).valueOrNull;
    return state!.accounts.firstWhere((b) => b.id == widget.billId);
  }

  Future<void> _launch() async {
    final bill = _getBill();
    final resolver = ref.read(paymentUrlResolverProvider);
    final url = await resolver.resolve(bill.utilityType, bill.accountNumber);

    final deepLink = Uri.parse(url.deepLink);
    final webLink = Uri.parse(url.webFallback);

    bool launched = false;
    if (url.deepLink.isNotEmpty && await canLaunchUrl(deepLink)) {
      launched = await launchUrl(deepLink, mode: LaunchMode.externalApplication);
    }
    if (!launched && url.webFallback.isNotEmpty) {
      launched = await launchUrl(webLink, mode: LaunchMode.externalApplication);
    }
    if (!launched) {
      _showCannotOpenDialog();
      return;
    }
    setState(() => _didLaunch = true);
  }

  void _showLogSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LogPaymentSheet(bill: _getBill()),
    );
  }

  void _showCannotOpenDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('অ্যাপ খোলা যায়নি'),
        content: const Text(
          'বিকাশ বা নগদ অ্যাপ থেকে সরাসরি বিল পরিশোধ করুন।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bill = _getBill();
    return Scaffold(
      appBar: AppBar(title: Text(bill.nickname)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            BillDetailCard(bill: bill),
            const Spacer(),
            if (!_returned)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _launch,
                  icon: const Icon(Icons.open_in_new),
                  label: Text('${bill.utilityType.displayName} পেমেন্ট করুন'),
                ),
              ),
            if (_returned) ...[
              const Text('পেমেন্ট সফল হলে লগ করুন'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('পরে লগ করব'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showLogSheet,
                      child: const Text('পেমেন্ট লগ করুন'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
```

### 6.4 LogPaymentSheet

```dart
class LogPaymentSheet extends ConsumerStatefulWidget {
  final BillAccount bill;
  const LogPaymentSheet({required this.bill, super.key});

  @override
  ConsumerState<LogPaymentSheet> createState() => _LogPaymentSheetState();
}

class _LogPaymentSheetState extends ConsumerState<LogPaymentSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    await ref.read(paymentHistoryProvider.notifier).addRecord(
      billId: widget.bill.id!,
      amount: amount,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('পেমেন্ট লগ হয়েছে ✓')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('পেমেন্ট লগ করুন',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'পরিমাণ (টাকা)',
              prefixText: '৳ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'নোট (ঐচ্ছিক)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('সেভ করুন'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
```

---

## 7. Firebase Remote Config

### 7.1 Parameters

| Key | Default | Purpose |
|---|---|---|
| `desco` | `bkash://pay?service=desco&account={acc}` | DESCO bKash deep link |
| `dpdc` | `bkash://pay?service=dpdc&account={acc}` | DPDC bKash deep link |
| `wasa` | `bkash://pay?service=wasa&account={acc}` | WASA bKash deep link |
| `titas` | `bkash://pay?service=titas&account={acc}` | Titas bKash deep link |
| `desco_web` | DESCO self-service portal URL | Browser fallback |
| `dpdc_web` | DPDC portal URL | Browser fallback |
| `wasa_web` | WASA portal URL | Browser fallback |
| `titas_web` | Titas portal URL | Browser fallback |
| `btcl_web` | BTCL portal URL | Browser fallback |
| `maintenance_mode` | `false` | Show banner if true |
| `force_update_version` | `1.0.0` | Minimum supported version |

### 7.2 RemoteConfigService

```dart
// data/remote/remote_config_service.dart
class RemoteConfigService {
  final FirebaseRemoteConfig _rc;
  RemoteConfigService(this._rc);

  Future<void> initialize() async {
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 6),
    ));
    await _rc.setDefaults({
      'desco':      'bkash://pay?service=desco&account={acc}',
      'dpdc':       'bkash://pay?service=dpdc&account={acc}',
      'wasa':       'bkash://pay?service=wasa&account={acc}',
      'titas':      'bkash://pay?service=titas&account={acc}',
      'btcl':       '',
      'desco_web':  'https://selfservice.desco.org.bd/bill-pay?acc={acc}',
      'dpdc_web':   'https://dpdc.org.bd/payment?consumer={acc}',
      'wasa_web':   'https://wasa.gov.bd/payment?acc={acc}',
      'titas_web':  'https://titasgas.org.bd/online-payment?acc={acc}',
      'btcl_web':   'https://www.btcl.gov.bd/payment?acc={acc}',
      'maintenance_mode': false,
      'force_update_version': '1.0.0',
    });
    try {
      await _rc.fetchAndActivate();
    } catch (_) {
      // Use cached/default values — never crash on Remote Config failure
    }
  }

  String getString(String key) => _rc.getString(key);
  bool getBool(String key) => _rc.getBool(key);
  bool get isMaintenanceMode => getBool('maintenance_mode');
}
```

> **Why Remote Config matters:** If bKash changes a deep link scheme (it has happened), push the new URL to Remote Config — all installed app versions pick it up within 6 hours without a Play Store release.

---

## 8. Push Notifications — FCM + Local Notifications

### 8.1 ReminderService — Monthly Due Date Reminders

```dart
// data/local/reminder_service.dart
class ReminderService {
  final FlutterLocalNotificationsPlugin _plugin;
  ReminderService(this._plugin);

  Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings);
    await _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestExactAlarmsPermission();
  }

  Future<void> scheduleMonthlyReminder({
    required int billId,
    required int dueDay,
    required String billName,
  }) async {
    await cancelReminder(billId);

    final now = DateTime.now();
    var nextDue = DateTime(now.year, now.month, dueDay, 9, 0);
    if (nextDue.isBefore(now)) {
      nextDue = DateTime(now.year, now.month + 1, dueDay, 9, 0);
    }

    await _plugin.zonedSchedule(
      billId,
      '💡 বিল পরিশোধের সময়',
      '$billName বিল এখন পরিশোধ করুন',
      tz.TZDateTime.from(nextDue, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'bill_reminders',
          'বিল রিমাইন্ডার',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      payload: 'bill_id:$billId',
    );
  }

  Future<void> cancelReminder(int billId) => _plugin.cancel(billId);
  Future<void> cancelAll() => _plugin.cancelAll();
}
```

---

## 9. Navigation Architecture

```dart
// app.dart — go_router
final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/add-bill', builder: (_, __) => const AddBillScreen()),
    GoRoute(
      path: '/edit-bill/:id',
      builder: (_, s) => EditBillScreen(billId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/pay/:billId',
      builder: (_, s) => PaymentRedirectScreen(
        billId: int.parse(s.pathParameters['billId']!),
      ),
    ),
    GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
    GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(
      path: '/auth/phone',
      builder: (_, __) => const PhoneEntryScreen(),
    ),
    GoRoute(
      path: '/auth/otp',
      builder: (_, s) => OtpScreen(phone: s.extra as String),
    ),
  ],
);
```

**Bottom navigation tabs:** Home (dashboard) · History · Analytics · Settings

---

## 10. Flutter Package Dependencies

```yaml
# pubspec.yaml
name: bilbax
description: বিলবাক্স — Utility bill manager for Bangladesh
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5   # Optional codegen (can skip for MVP)

  # Local storage
  sqflite: ^2.3.3+1
  path: ^1.9.0
  shared_preferences: ^2.3.2

  # Firebase
  firebase_core: ^3.4.0
  firebase_auth: ^5.2.1
  cloud_firestore: ^5.4.0
  firebase_messaging: ^15.1.0
  firebase_remote_config: ^5.1.0

  # Notifications
  flutter_local_notifications: ^18.0.1
  timezone: ^0.9.4

  # Navigation
  go_router: ^14.2.0

  # Payment redirects
  url_launcher: ^6.3.0

  # UI
  intl: ^0.19.0
  fl_chart: ^0.69.0
  shimmer: ^3.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.11          # For riverpod_generator codegen
  riverpod_generator: ^2.4.3
  riverpod_lint: ^2.3.13
  custom_lint: ^0.6.4
  sqflite_common_ffi: ^2.3.3    # In-memory SQLite for tests
  mocktail: ^1.0.4
```

---

## 11. Environment Configuration

### 11.1 Firebase Setup

```
android/app/google-services.json        ← gitignored
ios/Runner/GoogleService-Info.plist     ← gitignored
```

### 11.2 main.dart — Full Initialization

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

  // Remote Config fetch runs non-blocking — defaults are always ready
  unawaited(RemoteConfigService(FirebaseRemoteConfig.instance).initialize());

  runApp(
    const ProviderScope(
      child: BilBaxApp(),
    ),
  );
}
```

No `get_it` needed — Riverpod's `ProviderScope` is the DI container.

---

## 12. Testing Strategy

### 12.1 Provider Tests

Riverpod providers are testable with `ProviderContainer` — no widget needed.

```dart
// test/providers/bill_accounts_test.dart
void main() {
  test('BillAccountsNotifier loads accounts', () async {
    final mockRepo = MockBillRepository();
    when(() => mockRepo.getAllAccounts()).thenAnswer((_) async => [
      BillAccount(
        id: 1,
        utilityType: UtilityType.desco,
        accountNumber: '12345678',
        nickname: 'Home',
        createdAt: DateTime.now(),
      ),
    ]);

    final container = ProviderContainer(
      overrides: [
        billRepositoryProvider.overrideWithValue(mockRepo),
        reminderServiceProvider.overrideWithValue(MockReminderService()),
      ],
    );
    addTearDown(container.dispose);

    // Wait for the AsyncNotifier to build
    final state = await container.read(billAccountsProvider.future);

    expect(state.accounts.length, 1);
    expect(state.accounts.first.nickname, 'Home');
  });
}
```

### 12.2 DAO Tests — In-Memory SQLite

```dart
// test/data/bill_account_dao_test.dart
void main() {
  late DatabaseHelper dbHelper;
  late BillAccountDao dao;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dbHelper = DatabaseHelper();
    dao = BillAccountDao(dbHelper);
  });

  tearDown(() async {
    final db = await dbHelper.database;
    await db.delete('bill_accounts');
  });

  test('insert and retrieve', () async {
    final model = BillAccountModel(
      utilityType: 'desco',
      accountNumber: '12345678',
      nickname: 'বাসা',
      isActive: true,
      createdAt: DateTime.now(),
    );

    final id = await dao.insert(model);
    expect(id, greaterThan(0));

    final all = await dao.getAllActive();
    expect(all.length, 1);
    expect(all.first.accountNumber, '12345678');
  });
}
```

### 12.3 Widget Tests

```dart
testWidgets('BillCard shows nickname and utility label', (tester) async {
  final bill = BillAccount(
    id: 1,
    utilityType: UtilityType.desco,
    accountNumber: '12345678',
    nickname: 'বাসার বিদ্যুৎ',
    createdAt: DateTime.now(),
  );

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: BillCard(bill: bill, onPayTap: () {})),
      ),
    ),
  );

  expect(find.text('বাসার বিদ্যুৎ'), findsOneWidget);
  expect(find.text('DESCO (বিদ্যুৎ)'), findsOneWidget);
});
```

### 12.4 Coverage Targets

| Layer | Target | Priority |
|---|---|---|
| Riverpod notifiers | 80% | High |
| DAO (SQLite) | 90% | High |
| PaymentUrlResolver | 100% | High |
| Repository impls | 70% | Medium |
| Widget tests | 40% | Low |

---

## Appendix: Key Data Flow

```
ADD BILL:
  AddBillScreen form submit
    → ref.read(billAccountsProvider.notifier).addAccount(account)
      → BillRepository.insertAccount → BillAccountDao.insert (SQLite)
      → ReminderService.scheduleMonthlyReminder
      → ref.invalidate → UI rebuilds with new list
      → SyncNotifier.pushUnsynced (if logged in) → Firestore

PAY NOW:
  BillCard "Pay" tap → go_router /pay/:billId
    → PaymentRedirectScreen
      → PaymentUrlResolver.resolve (Remote Config + defaults)
        → url_launcher.launchUrl (deep link → Chrome Custom Tab)
          → User pays externally
          → WidgetsBindingObserver.resumed
          → LogPaymentSheet
            → ref.read(paymentHistoryProvider.notifier).addRecord
              → PaymentHistoryDao.insert (SQLite)
              → ref.invalidate(billAccountsProvider) → home refreshes
              → ReminderService reschedule
              → SyncNotifier.pushUnsynced

ANALYTICS:
  AnalyticsScreen mounts
    → ref.watch(monthlyTotalsProvider(year))
      → PaymentHistoryDao.getMonthlyTotals (raw SQL GROUP BY month)
    → ref.watch(categoryTotalsProvider(year))
      → PaymentHistoryDao.getTotalsByCategory (JOIN + GROUP BY type)
    → fl_chart renders automatically on AsyncData
```
