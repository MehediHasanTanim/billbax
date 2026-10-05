# বিলবাক্স (BilBax) — Phase-wise Technical Implementation Plan

**Version:** 1.0  
**Platform:** Flutter (Android-first, iOS-compatible)  
**State Management:** Riverpod  
**Target:** Working MVP in 10 days  
**Last Updated:** October 2026

---

## Overview

| Phase | Days | Focus | Deliverable |
|---|---|---|---|
| 0 | Day 0 | Project bootstrap & Firebase | Running shell app on device |
| 1 | Day 1–2 | Data layer (SQLite + models) | All tables, DAOs, seed data |
| 2 | Day 3–4 | Bill management UI | Add/Edit/Delete bills, home dashboard |
| 3 | Day 5 | Payment redirect system | Pay Now flow with url_launcher |
| 4 | Day 6 | Payment history & analytics | Log payments, charts |
| 5 | Day 7 | Firebase Auth + Firestore sync | Phone OTP login, cloud backup |
| 6 | Day 8 | Notifications & Remote Config | Due date reminders, FCM, live URLs |
| 7 | Day 9 | Polish, testing, release | APK, Play Store draft |

---

## Phase 0 — Project Bootstrap (Day 0)

### Goal
Flutter project created, Firebase connected, Riverpod wired, app runs on device.

### Task 0.1 — Create Flutter Project

```bash
flutter create bilbax \
  --org com.yourname \
  --platforms android,ios \
  --project-name bilbax

cd bilbax

# Verify
flutter doctor
flutter run
```

### Task 0.2 — Establish Folder Structure

Create the full directory tree before writing any code:

```
lib/
├── core/
│   ├── constants/
│   │   ├── utility_types.dart      # DESCO, DPDC, WASA, Titas enum
│   │   ├── app_colors.dart
│   │   └── app_strings.dart
│   ├── database/
│   │   ├── database_helper.dart    # SQLite init & migration
│   │   └── migrations/
│   │       └── v1_initial.dart
│   ├── router/
│   │   └── app_router.dart         # go_router config
│   └── utils/
│       ├── date_utils.dart
│       └── currency_format.dart
├── features/
│   ├── bills/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── bill_account.dart
│   │   │   └── repositories/
│   │   │       └── bill_repository.dart
│   │   ├── providers/
│   │   │   └── bill_providers.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── home_screen.dart
│   │       │   ├── add_bill_screen.dart
│   │       │   └── bill_detail_screen.dart
│   │       └── widgets/
│   │           ├── bill_card.dart
│   │           └── bill_type_icon.dart
│   ├── payments/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── payment_record.dart
│   │   │   └── repositories/
│   │   │       └── payment_repository.dart
│   │   ├── providers/
│   │   │   └── payment_providers.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── payment_redirect_screen.dart
│   │       │   └── payment_history_screen.dart
│   │       └── widgets/
│   │           ├── log_payment_sheet.dart
│   │           └── payment_tile.dart
│   ├── analytics/
│   │   ├── providers/
│   │   │   └── analytics_providers.dart
│   │   └── presentation/
│   │       └── screens/
│   │           └── analytics_screen.dart
│   ├── auth/
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   ├── providers/
│   │   │   └── auth_providers.dart
│   │   └── presentation/
│   │       └── screens/
│   │           ├── login_screen.dart
│   │           └── otp_screen.dart
│   ├── sync/
│   │   ├── providers/
│   │   │   └── sync_providers.dart
│   │   └── services/
│   │       └── firestore_sync_service.dart
│   ├── notifications/
│   │   └── services/
│   │       └── reminder_service.dart
│   └── settings/
│       └── presentation/
│           └── screens/
│               └── settings_screen.dart
├── providers/                      # Cross-cutting providers
│   ├── core_providers.dart         # db, sharedPrefs
│   └── repository_providers.dart
└── main.dart
```

```bash
# Create all dirs
find lib -type d | sort | xargs mkdir -p
# Or use the tree above and mkdir manually
```

### Task 0.3 — Add Dependencies

```yaml
# pubspec.yaml
name: bilbax
description: Utility bill tracker for Bangladesh

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Local database
  sqflite: ^2.3.3+1
  path: ^1.9.0

  # Firebase
  firebase_core: ^3.3.0
  firebase_auth: ^5.1.4
  cloud_firestore: ^5.2.1
  firebase_messaging: ^15.0.4
  firebase_remote_config: ^5.1.2

  # Navigation
  go_router: ^14.2.7

  # UI utilities
  flutter_local_notifications: ^17.2.2
  url_launcher: ^6.3.0
  fl_chart: ^0.68.0
  intl: ^0.19.0
  shared_preferences: ^2.3.2
  uuid: ^4.4.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.3
  riverpod_lint: ^2.3.13
  custom_lint: ^0.6.4
  mockito: ^5.4.4
  sqflite_common_ffi: ^2.3.3
```

```bash
flutter pub get
```

### Task 0.4 — Firebase Setup

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login
firebase login

# Configure (run from project root)
flutterfire configure \
  --project=bilbax-app \
  --platforms=android,ios
```

This generates `lib/firebase_options.dart` automatically.

**Enable in Firebase Console:**
- Authentication → Phone
- Firestore Database (test mode initially)
- Remote Config
- Cloud Messaging

### Task 0.5 — main.dart Bootstrap

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: BilBaxApp()));
}

class BilBaxApp extends ConsumerWidget {
  const BilBaxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'বিলবাক্স',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
```

**Checkpoint:** `flutter run` shows a blank Material 3 screen. Firebase initializes without crash.

---

## Phase 1 — Data Layer (Day 1–2)

### Goal
All SQLite tables created. Models defined. Repository classes working. Unit tests pass.

### Task 1.1 — Define Models

```dart
// lib/features/bills/data/models/bill_account.dart
import 'package:uuid/uuid.dart';

enum UtilityType {
  desco,
  dpdc,
  wasa,
  titas,
  internet,
  btcl,
}

class BillAccount {
  final String id;
  final UtilityType utilityType;
  final String accountNumber;
  final String nickname;
  final String? area;
  final int? typicalDueDay;       // 1–31
  final String? paymentUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastPaidAt;

  const BillAccount({
    required this.id,
    required this.utilityType,
    required this.accountNumber,
    required this.nickname,
    this.area,
    this.typicalDueDay,
    this.paymentUrl,
    this.isActive = true,
    required this.createdAt,
    this.lastPaidAt,
  });

  factory BillAccount.create({
    required UtilityType utilityType,
    required String accountNumber,
    required String nickname,
    String? area,
    int? typicalDueDay,
    String? paymentUrl,
  }) {
    return BillAccount(
      id: const Uuid().v4(),
      utilityType: utilityType,
      accountNumber: accountNumber,
      nickname: nickname,
      area: area,
      typicalDueDay: typicalDueDay,
      paymentUrl: paymentUrl,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'utility_type': utilityType.name,
    'account_number': accountNumber,
    'nickname': nickname,
    'area': area,
    'typical_due_day': typicalDueDay,
    'payment_url': paymentUrl,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'last_paid_at': lastPaidAt?.toIso8601String(),
  };

  factory BillAccount.fromMap(Map<String, dynamic> map) => BillAccount(
    id: map['id'] as String,
    utilityType: UtilityType.values.byName(map['utility_type'] as String),
    accountNumber: map['account_number'] as String,
    nickname: map['nickname'] as String,
    area: map['area'] as String?,
    typicalDueDay: map['typical_due_day'] as int?,
    paymentUrl: map['payment_url'] as String?,
    isActive: (map['is_active'] as int) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    lastPaidAt: map['last_paid_at'] != null
        ? DateTime.parse(map['last_paid_at'] as String)
        : null,
  );

  BillAccount copyWith({
    String? nickname,
    String? area,
    int? typicalDueDay,
    String? paymentUrl,
    bool? isActive,
    DateTime? lastPaidAt,
  }) => BillAccount(
    id: id,
    utilityType: utilityType,
    accountNumber: accountNumber,
    nickname: nickname ?? this.nickname,
    area: area ?? this.area,
    typicalDueDay: typicalDueDay ?? this.typicalDueDay,
    paymentUrl: paymentUrl ?? this.paymentUrl,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
    lastPaidAt: lastPaidAt ?? this.lastPaidAt,
  );
}
```

```dart
// lib/features/payments/data/models/payment_record.dart
class PaymentRecord {
  final String id;
  final String billAccountId;
  final double amount;
  final DateTime paidAt;
  final String? notes;
  final String? receiptImagePath;
  final bool isSynced;

  const PaymentRecord({
    required this.id,
    required this.billAccountId,
    required this.amount,
    required this.paidAt,
    this.notes,
    this.receiptImagePath,
    this.isSynced = false,
  });

  factory PaymentRecord.create({
    required String billAccountId,
    required double amount,
    String? notes,
    String? receiptImagePath,
  }) => PaymentRecord(
    id: const Uuid().v4(),
    billAccountId: billAccountId,
    amount: amount,
    paidAt: DateTime.now(),
    notes: notes,
    receiptImagePath: receiptImagePath,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'bill_account_id': billAccountId,
    'amount': amount,
    'paid_at': paidAt.toIso8601String(),
    'notes': notes,
    'receipt_image_path': receiptImagePath,
    'is_synced': isSynced ? 1 : 0,
  };

  factory PaymentRecord.fromMap(Map<String, dynamic> map) => PaymentRecord(
    id: map['id'] as String,
    billAccountId: map['bill_account_id'] as String,
    amount: (map['amount'] as num).toDouble(),
    paidAt: DateTime.parse(map['paid_at'] as String),
    notes: map['notes'] as String?,
    receiptImagePath: map['receipt_image_path'] as String?,
    isSynced: (map['is_synced'] as int) == 1,
  );
}
```

### Task 1.2 — Database Helper

```dart
// lib/core/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _dbName = 'bilbax.db';
  static const _dbVersion = 1;

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
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
        id TEXT PRIMARY KEY,
        utility_type TEXT NOT NULL,
        account_number TEXT NOT NULL,
        nickname TEXT NOT NULL,
        area TEXT,
        typical_due_day INTEGER,
        payment_url TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        last_paid_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_history (
        id TEXT PRIMARY KEY,
        bill_account_id TEXT NOT NULL,
        amount REAL NOT NULL,
        paid_at TEXT NOT NULL,
        notes TEXT,
        receipt_image_path TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (bill_account_id) REFERENCES bill_accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE property_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bill_group_members (
        bill_account_id TEXT NOT NULL,
        group_id TEXT NOT NULL,
        PRIMARY KEY (bill_account_id, group_id),
        FOREIGN KEY (bill_account_id) REFERENCES bill_accounts(id),
        FOREIGN KEY (group_id) REFERENCES property_groups(id)
      )
    ''');

    // Indexes
    await db.execute(
      'CREATE INDEX idx_payment_history_bill ON payment_history(bill_account_id)');
    await db.execute(
      'CREATE INDEX idx_payment_history_paid ON payment_history(paid_at DESC)');
    await db.execute(
      'CREATE INDEX idx_bills_active ON bill_accounts(is_active)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
    // if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
  }
}
```

### Task 1.3 — Repositories

```dart
// lib/features/bills/data/repositories/bill_repository.dart
import 'package:sqflite/sqflite.dart';
import '../models/bill_account.dart';

class BillRepository {
  BillRepository(this._db);
  final Database _db;

  Future<List<BillAccount>> getAll({bool activeOnly = true}) async {
    final where = activeOnly ? 'WHERE is_active = 1' : '';
    final maps = await _db.rawQuery(
      'SELECT * FROM bill_accounts $where ORDER BY created_at DESC',
    );
    return maps.map(BillAccount.fromMap).toList();
  }

  Future<BillAccount?> getById(String id) async {
    final maps = await _db.query(
      'bill_accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : BillAccount.fromMap(maps.first);
  }

  Future<void> insert(BillAccount account) async {
    await _db.insert(
      'bill_accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(BillAccount account) async {
    await _db.update(
      'bill_accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> softDelete(String id) async {
    await _db.update(
      'bill_accounts',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateLastPaid(String id, DateTime paidAt) async {
    await _db.update(
      'bill_accounts',
      {'last_paid_at': paidAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

```dart
// lib/features/payments/data/repositories/payment_repository.dart
class PaymentRepository {
  PaymentRepository(this._db);
  final Database _db;

  Future<List<PaymentRecord>> getByBillAccount(String billAccountId) async {
    final maps = await _db.query(
      'payment_history',
      where: 'bill_account_id = ?',
      whereArgs: [billAccountId],
      orderBy: 'paid_at DESC',
    );
    return maps.map(PaymentRecord.fromMap).toList();
  }

  Future<List<PaymentRecord>> getByMonth(int year, int month) async {
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    final maps = await _db.query(
      'payment_history',
      where: 'paid_at >= ? AND paid_at < ?',
      whereArgs: [start, end],
      orderBy: 'paid_at DESC',
    );
    return maps.map(PaymentRecord.fromMap).toList();
  }

  Future<List<MonthlyTotal>> getMonthlyTotals(int year) async {
    final maps = await _db.rawQuery('''
      SELECT
        strftime('%m', paid_at) AS month,
        SUM(amount) AS total
      FROM payment_history
      WHERE strftime('%Y', paid_at) = ?
      GROUP BY strftime('%m', paid_at)
      ORDER BY month
    ''', [year.toString()]);
    return maps.map((m) => MonthlyTotal(
      month: int.parse(m['month'] as String),
      total: (m['total'] as num).toDouble(),
    )).toList();
  }

  Future<void> insert(PaymentRecord record) async {
    await _db.insert('payment_history', record.toMap());
  }

  Future<void> markSynced(String id) async {
    await _db.update(
      'payment_history',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<PaymentRecord>> getUnsynced() async {
    final maps = await _db.query(
      'payment_history',
      where: 'is_synced = 0',
    );
    return maps.map(PaymentRecord.fromMap).toList();
  }
}

class MonthlyTotal {
  final int month;
  final double total;
  const MonthlyTotal({required this.month, required this.total});
}
```

### Task 1.4 — Core Providers

```dart
// lib/providers/core_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main.dart');
});

final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError('Override in main.dart');
});
```

```dart
// lib/providers/repository_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/bills/data/repositories/bill_repository.dart';
import '../features/payments/data/repositories/payment_repository.dart';
import 'core_providers.dart';

final billRepositoryProvider = Provider<BillRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BillRepository(db);
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PaymentRepository(db);
});
```

**Update main.dart** to initialize and override providers:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final dbHelper = DatabaseHelper();
  final db = await dbHelper.database;
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BilBaxApp(),
    ),
  );
}
```

### Task 1.5 — Unit Tests for Repositories

```dart
// test/repositories/bill_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bilbax/core/database/database_helper.dart';
import 'package:bilbax/features/bills/data/models/bill_account.dart';
import 'package:bilbax/features/bills/data/repositories/bill_repository.dart';

void main() {
  late Database db;
  late BillRepository repo;

  setUpAll(() => sqfliteFfiInit());

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    final helper = DatabaseHelper();
    db = await helper.database;
    repo = BillRepository(db);
  });

  tearDown(() async => db.close());

  test('insert and retrieve bill account', () async {
    final account = BillAccount.create(
      utilityType: UtilityType.desco,
      accountNumber: '1234567',
      nickname: 'Home',
    );
    await repo.insert(account);
    final accounts = await repo.getAll();
    expect(accounts.length, 1);
    expect(accounts.first.nickname, 'Home');
  });

  test('soft delete does not remove from db', () async {
    final account = BillAccount.create(
      utilityType: UtilityType.wasa,
      accountNumber: '9999',
      nickname: 'Office',
    );
    await repo.insert(account);
    await repo.softDelete(account.id);
    final activeOnly = await repo.getAll(activeOnly: true);
    expect(activeOnly.isEmpty, true);
    final all = await repo.getAll(activeOnly: false);
    expect(all.length, 1);
  });
}
```

```bash
flutter test test/repositories/
```

**Checkpoint:** All repository tests pass. DB creates cleanly on first run.

---

## Phase 2 — Bill Management UI (Day 3–4)

### Goal
Home screen shows all bills. User can add, edit, delete bills. All state managed via Riverpod.

### Task 2.1 — Bill Providers

```dart
// lib/features/bills/providers/bill_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/bill_account.dart';
import '../data/repositories/bill_repository.dart';
import '../../../providers/repository_providers.dart';

class BillAccountsState {
  final List<BillAccount> accounts;
  final List<BillAccount> dueSoon;   // due within 5 days
  final List<BillAccount> overdue;   // past due day

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
          (a.lastPaidAt == null || a.lastPaidAt!.month != now.month);
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
  }

  Future<void> updateAccount(BillAccount account) async {
    await _repo.update(account);
    state = await AsyncValue.guard(_reload);
  }

  Future<void> deleteAccount(String id) async {
    await _repo.softDelete(id);
    state = await AsyncValue.guard(_reload);
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
```

### Task 2.2 — Router Setup

```dart
// lib/core/router/app_router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/bills/presentation/screens/home_screen.dart';
import '../../features/bills/presentation/screens/add_bill_screen.dart';
import '../../features/bills/presentation/screens/bill_detail_screen.dart';
import '../../features/payments/presentation/screens/payment_redirect_screen.dart';
import '../../features/payments/presentation/screens/payment_history_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/add-bill', builder: (_, __) => const AddBillScreen()),
      GoRoute(
        path: '/bill/:id',
        builder: (_, state) => BillDetailScreen(billId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/pay/:billId',
        builder: (_, state) =>
            PaymentRedirectScreen(billId: state.pathParameters['billId']!),
      ),
      GoRoute(
        path: '/history/:billId',
        builder: (_, state) =>
            PaymentHistoryScreen(billId: state.pathParameters['billId']!),
      ),
      GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    ],
  );
});
```

### Task 2.3 — Home Screen

```dart
// lib/features/bills/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/bill_providers.dart';
import '../widgets/bill_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billState = ref.watch(billAccountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('বিলবাক্স'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/analytics'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: billState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (state) => _buildBody(context, ref, state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-bill'),
        icon: const Icon(Icons.add),
        label: const Text('বিল যোগ করুন'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, BillAccountsState state) {
    if (state.accounts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('কোনো বিল নেই', style: TextStyle(color: Colors.grey)),
            Text('"বিল যোগ করুন" বাটনে ক্লিক করুন'),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        if (state.overdue.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: _SectionHeader(title: '⚠️ মেয়াদ পেরিয়েছে', color: Colors.red),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => BillCard(account: state.overdue[i]),
              childCount: state.overdue.length,
            ),
          ),
        ],
        if (state.dueSoon.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: _SectionHeader(title: '⏰ শীঘ্রই দেয়', color: Colors.orange),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => BillCard(account: state.dueSoon[i]),
              childCount: state.dueSoon.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(
          child: _SectionHeader(title: 'সব বিল', color: Colors.blue),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => BillCard(account: state.accounts[i]),
            childCount: state.accounts.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: color,
      ),
    ),
  );
}
```

### Task 2.4 — Bill Card Widget

```dart
// lib/features/bills/presentation/widgets/bill_card.dart
class BillCard extends ConsumerWidget {
  const BillCard({super.key, required this.account});
  final BillAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _colorForType(account.utilityType),
          child: Icon(_iconForType(account.utilityType), color: Colors.white, size: 20),
        ),
        title: Text(account.nickname, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${account.utilityType.name.toUpperCase()} · ${account.accountNumber}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (account.typicalDueDay != null)
              Chip(
                label: Text('${account.typicalDueDay} তারিখ'),
                visualDensity: VisualDensity.compact,
              ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () => context.push('/pay/${account.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('পে করুন'),
            ),
          ],
        ),
        onTap: () => context.push('/bill/${account.id}'),
      ),
    );
  }

  Color _colorForType(UtilityType type) => switch (type) {
    UtilityType.desco => Colors.yellow.shade700,
    UtilityType.dpdc => Colors.orange,
    UtilityType.wasa => Colors.blue,
    UtilityType.titas => Colors.deepOrange,
    UtilityType.internet => Colors.purple,
    UtilityType.btcl => Colors.teal,
  };

  IconData _iconForType(UtilityType type) => switch (type) {
    UtilityType.desco || UtilityType.dpdc => Icons.bolt,
    UtilityType.wasa => Icons.water_drop,
    UtilityType.titas => Icons.local_fire_department,
    UtilityType.internet => Icons.wifi,
    UtilityType.btcl => Icons.phone,
  };
}
```

### Task 2.5 — Add Bill Screen

```dart
// lib/features/bills/presentation/screens/add_bill_screen.dart
class AddBillScreen extends ConsumerStatefulWidget {
  const AddBillScreen({super.key, this.existingAccount});
  final BillAccount? existingAccount;

  @override
  ConsumerState<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends ConsumerState<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  late UtilityType _selectedType;
  late TextEditingController _accountController;
  late TextEditingController _nicknameController;
  late TextEditingController _areaController;
  int? _dueDayValue;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAccount;
    _selectedType = existing?.utilityType ?? UtilityType.desco;
    _accountController = TextEditingController(text: existing?.accountNumber);
    _nicknameController = TextEditingController(text: existing?.nickname);
    _areaController = TextEditingController(text: existing?.area);
    _dueDayValue = existing?.typicalDueDay;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAccount != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'বিল সম্পাদনা' : 'নতুন বিল')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<UtilityType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'সেবা প্রদানকারী',
                border: OutlineInputBorder(),
              ),
              items: UtilityType.values.map((type) => DropdownMenuItem(
                value: type,
                child: Text(_labelForType(type)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountController,
              decoration: const InputDecoration(
                labelText: 'অ্যাকাউন্ট নম্বর',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty == true ? 'অ্যাকাউন্ট নম্বর দিন' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'নাম (যেমন: বাড়ি, অফিস)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty == true ? 'নাম দিন' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'এলাকা (ঐচ্ছিক)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              value: _dueDayValue,
              decoration: const InputDecoration(
                labelText: 'মাসিক বকেয়া তারিখ (ঐচ্ছিক)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('নির্ধারিত নেই')),
                ...List.generate(28, (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('${i + 1} তারিখ'),
                )),
              ],
              onChanged: (v) => setState(() => _dueDayValue = v),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : Text(isEditing ? 'আপডেট করুন' : 'সংরক্ষণ করুন'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final notifier = ref.read(billAccountsProvider.notifier);
      if (widget.existingAccount != null) {
        await notifier.updateAccount(widget.existingAccount!.copyWith(
          nickname: _nicknameController.text,
          area: _areaController.text,
          typicalDueDay: _dueDayValue,
        ));
      } else {
        await notifier.addAccount(BillAccount.create(
          utilityType: _selectedType,
          accountNumber: _accountController.text,
          nickname: _nicknameController.text,
          area: _areaController.text.isEmpty ? null : _areaController.text,
          typicalDueDay: _dueDayValue,
        ));
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _labelForType(UtilityType type) => switch (type) {
    UtilityType.desco => 'DESCO (ঢাকা উত্তর)',
    UtilityType.dpdc => 'DPDC (ঢাকা দক্ষিণ)',
    UtilityType.wasa => 'WASA (পানি)',
    UtilityType.titas => 'তিতাস গ্যাস',
    UtilityType.internet => 'ইন্টারনেট',
    UtilityType.btcl => 'BTCL',
  };
}
```

**Checkpoint:** Can add a bill, see it on home screen in the right section, edit and delete it.

---

## Phase 3 — Payment Redirect System (Day 5)

### Goal
Tap "পে করুন" → app opens payment URL in browser/bKash app → user returns → can log payment manually.

### Task 3.1 — Remote Config for Payment URLs

```dart
// lib/core/constants/utility_types.dart
const Map<String, String> kDefaultPaymentUrls = {
  'desco': 'https://selfservice.desco.org.bd/',
  'dpdc': 'https://ebill.dpdc.org.bd/',
  'wasa': 'https://dphe.portal.gov.bd/',       // placeholder
  'titas': 'https://bill.titasgas.org.bd/',
  'internet': '',                                // user sets manually
  'btcl': 'https://www.btcl.gov.bd/online-bill-pay',
};

// bKash bill pay deeplinks (if available)
const Map<String, String> kBkashBillUrls = {
  'desco': 'bkash://billpay/desco',
  'dpdc':  'bkash://billpay/dpdc',
  'wasa':  'bkash://billpay/wasa',
  'titas': 'bkash://billpay/titas',
};
```

```dart
// lib/features/payments/providers/payment_providers.dart — Remote Config provider
final remoteConfigProvider = FutureProvider<Map<String, String>>((ref) async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setDefaults(
    kDefaultPaymentUrls.map((k, v) => MapEntry('payment_url_$k', v)),
  );
  await remoteConfig.fetchAndActivate();

  return {
    for (final type in UtilityType.values)
      type.name: remoteConfig.getString('payment_url_${type.name}'),
  };
});
```

### Task 3.2 — Payment Redirect Screen

```dart
// lib/features/payments/presentation/screens/payment_redirect_screen.dart
class PaymentRedirectScreen extends ConsumerStatefulWidget {
  const PaymentRedirectScreen({super.key, required this.billId});
  final String billId;

  @override
  ConsumerState<PaymentRedirectScreen> createState() =>
      _PaymentRedirectScreenState();
}

class _PaymentRedirectScreenState extends ConsumerState<PaymentRedirectScreen>
    with WidgetsBindingObserver {
  bool _hasLaunched = false;
  bool _returnedFromPayment = false;

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
    if (state == AppLifecycleState.resumed && _hasLaunched) {
      setState(() => _returnedFromPayment = true);
      _showLogPaymentSheet();
    }
  }

  Future<void> _showLogPaymentSheet() async {
    final account = ref.read(billAccountsProvider).valueOrNull?.accounts
        .firstWhere((a) => a.id == widget.billId);
    if (account == null || !mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LogPaymentSheet(billAccount: account),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billState = ref.watch(billAccountsProvider);
    final remoteUrls = ref.watch(remoteConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('পেমেন্ট')),
      body: billState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          final account = state.accounts.firstWhere((a) => a.id == widget.billId);
          return _buildPaymentOptions(context, account, remoteUrls);
        },
      ),
    );
  }

  Widget _buildPaymentOptions(
    BuildContext context,
    BillAccount account,
    AsyncValue<Map<String, String>> remoteUrls,
  ) {
    if (_returnedFromPayment) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const Text('পেমেন্ট সম্পন্ন হয়েছে?'),
            FilledButton(
              onPressed: _showLogPaymentSheet,
              child: const Text('পেমেন্ট রেকর্ড করুন'),
            ),
          ],
        ),
      );
    }

    final url = account.paymentUrl ??
        remoteUrls.valueOrNull?[account.utilityType.name] ??
        kDefaultPaymentUrls[account.utilityType.name] ??
        '';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: ListTile(
              title: Text(account.nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${account.utilityType.name.toUpperCase()} · ${account.accountNumber}'),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'পেমেন্ট অপশন বেছে নিন:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          // bKash option (if deeplink available)
          if (kBkashBillUrls.containsKey(account.utilityType.name))
            _PaymentOptionButton(
              icon: 'assets/bkash_logo.png',
              label: 'bKash দিয়ে পে করুন',
              color: Colors.pink,
              onTap: () => _launchUrl(kBkashBillUrls[account.utilityType.name]!),
            ),
          const SizedBox(height: 12),
          // Official portal
          if (url.isNotEmpty)
            _PaymentOptionButton(
              icon: null,
              iconData: Icons.language,
              label: 'অফিসিয়াল ওয়েবসাইটে পে করুন',
              color: Colors.blue,
              onTap: () => _launchUrl(url),
            ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() => _hasLaunched = true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('অ্যাপ বা ওয়েবসাইট খোলা যায়নি')),
        );
      }
    }
  }
}
```

### Task 3.3 — Log Payment Sheet

```dart
// lib/features/payments/presentation/widgets/log_payment_sheet.dart
class LogPaymentSheet extends ConsumerStatefulWidget {
  const LogPaymentSheet({super.key, required this.billAccount});
  final BillAccount billAccount;

  @override
  ConsumerState<LogPaymentSheet> createState() => _LogPaymentSheetState();
}

class _LogPaymentSheetState extends ConsumerState<LogPaymentSheet> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.billAccount.nickname} — পেমেন্ট রেকর্ড',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'পরিমাণ (টাকা)',
              prefixText: '৳ ',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'নোট (ঐচ্ছিক)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const CircularProgressIndicator()
                : const Text('সংরক্ষণ করুন'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সঠিক পরিমাণ দিন')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(paymentHistoryProvider.notifier).addRecord(
        PaymentRecord.create(
          billAccountId: widget.billAccount.id,
          amount: amount,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
```

**Checkpoint:** "পে করুন" opens external payment. User returns to app. Log payment sheet appears. Record saved to SQLite.

---

## Phase 4 — Payment History & Analytics (Day 6)

### Goal
Each bill shows full payment history. Analytics screen shows monthly spend with charts.

### Task 4.1 — Payment History Providers

```dart
// lib/features/payments/providers/payment_providers.dart
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
      record.billAccountId, record.paidAt,
    );
    ref.invalidate(billAccountsProvider);
    ref.invalidateSelf();
  }
}

final paymentHistoryProvider =
    AsyncNotifierProvider<PaymentHistoryNotifier, List<PaymentRecord>>(
  PaymentHistoryNotifier.new,
);

// Analytics
final selectedAnalyticsYearProvider = StateProvider<int>((ref) {
  return DateTime.now().year;
});

final monthlyTotalsProvider = FutureProvider.family<List<MonthlyTotal>, int>(
  (ref, year) async {
    final repo = ref.watch(paymentRepositoryProvider);
    return repo.getMonthlyTotals(year);
  },
);
```

### Task 4.2 — Analytics Screen with fl_chart

```dart
// lib/features/analytics/presentation/screens/analytics_screen.dart
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedAnalyticsYearProvider);
    final totals = ref.watch(monthlyTotalsProvider(year));

    return Scaffold(
      appBar: AppBar(
        title: const Text('বিল বিশ্লেষণ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref
                .read(selectedAnalyticsYearProvider.notifier)
                .state = year - 1,
          ),
          Text('$year', style: const TextStyle(fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: year >= DateTime.now().year
                ? null
                : () => ref
                    .read(selectedAnalyticsYearProvider.notifier)
                    .state = year + 1,
          ),
        ],
      ),
      body: totals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) => _buildChart(data),
      ),
    );
  }

  Widget _buildChart(List<MonthlyTotal> data) {
    if (data.isEmpty) {
      return const Center(child: Text('এই বছরের কোনো পেমেন্ট নেই'));
    }
    final maxY = data.map((d) => d.total).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const months = ['জানু', 'ফেব', 'মার্চ', 'এপ্রি', 'মে', 'জুন',
                    'জুলা', 'আগ', 'সেপ', 'অক্টো', 'নভে', 'ডিসে'];
                  final idx = value.toInt() - 1;
                  if (idx < 0 || idx >= 12) return const SizedBox();
                  return Text(months[idx], style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) =>
                    Text('৳${value.toInt()}', style: const TextStyle(fontSize: 9)),
              ),
            ),
          ),
          barGroups: data.map((d) => BarChartGroupData(
            x: d.month,
            barRods: [BarChartRodData(toY: d.total, color: Colors.blue, width: 16)],
          )).toList(),
        ),
      ),
    );
  }
}
```

**Checkpoint:** Analytics screen shows monthly spend bar chart. Year selector works.

---

## Phase 5 — Firebase Auth + Firestore Sync (Day 7)

### Goal
Optional phone login. After login, bills and payments sync to Firestore for multi-device access.

### Task 5.1 — Auth Repository & Provider

```dart
// lib/features/auth/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get userChanges => _auth.authStateChanges();

  Future<void> sendOtp(
    String phoneNumber, {
    required Function(PhoneAuthCredential) onVerified,
    required Function(FirebaseAuthException) onFailed,
    required Function(String, int?) onCodeSent,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,    // e.g. "+8801711123456"
      verificationCompleted: onVerified,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> signInWithCode(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();
}
```

```dart
// lib/features/auth/providers/auth_providers.dart
sealed class AuthState {}
class Unauthenticated extends AuthState {}
class OtpSent extends AuthState {
  final String verificationId;
  OtpSent(this.verificationId);
}
class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() async {
    final user = _repo.currentUser;
    return user != null ? Authenticated(user) : Unauthenticated();
  }

  Future<void> sendOtp(String phone) async {
    state = const AsyncLoading();
    await _repo.sendOtp(
      phone,
      onVerified: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        state = AsyncData(Authenticated(FirebaseAuth.instance.currentUser!));
      },
      onFailed: (e) => state = AsyncError(e, StackTrace.current),
      onCodeSent: (verificationId, _) =>
          state = AsyncData(OtpSent(verificationId)),
    );
  }

  Future<void> verifyOtp(String verificationId, String smsCode) async {
    state = const AsyncLoading();
    await AsyncValue.guard(() => _repo.signInWithCode(verificationId, smsCode))
        .then((result) {
      if (result is AsyncError) {
        state = result;
      } else {
        state = AsyncData(Authenticated(FirebaseAuth.instance.currentUser!));
        ref.read(syncNotifierProvider.notifier).syncOnLogin();
      }
    });
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = AsyncData(Unauthenticated());
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
```

### Task 5.2 — Firestore Sync Service

```dart
// lib/features/sync/services/firestore_sync_service.dart
class FirestoreSyncService {
  FirestoreSyncService(this._db, this._auth);
  final Database _db;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference get _billsRef =>
      FirebaseFirestore.instance.collection('users/$_uid/bill_accounts');

  CollectionReference get _paymentsRef =>
      FirebaseFirestore.instance.collection('users/$_uid/payment_history');

  // Pull from Firestore on first login
  Future<void> pullOnLogin(BillRepository billRepo, PaymentRepository paymentRepo) async {
    final billDocs = await _billsRef.get();
    for (final doc in billDocs.docs) {
      final account = BillAccount.fromMap(doc.data() as Map<String, dynamic>);
      await billRepo.insert(account);
    }
    final paymentDocs = await _paymentsRef.get();
    for (final doc in paymentDocs.docs) {
      final record = PaymentRecord.fromMap(doc.data() as Map<String, dynamic>);
      await paymentRepo.insert(record);
    }
  }

  // Push unsynced payments after recording
  Future<void> pushPendingPayments(PaymentRepository paymentRepo) async {
    if (_auth.currentUser == null) return;
    final unsynced = await paymentRepo.getUnsynced();
    for (final record in unsynced) {
      await _paymentsRef.doc(record.id).set(record.toMap());
      await paymentRepo.markSynced(record.id);
    }
  }

  Future<void> pushBillAccount(BillAccount account) async {
    if (_auth.currentUser == null) return;
    await _billsRef.doc(account.id).set(account.toMap());
  }
}
```

**Checkpoint:** Phone OTP login works in Bangladesh (+880). Bills sync to Firestore on login.

---

## Phase 6 — Notifications & Remote Config (Day 8)

### Goal
Users get push reminders before bill due dates. Payment URLs served from Remote Config.

### Task 6.1 — Local Notification Reminder Service

```dart
// lib/features/notifications/services/reminder_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
    );
  }

  Future<void> scheduleMonthlyReminder({
    required int notificationId,
    required String billNickname,
    required int dayOfMonth,
    required String billId,
  }) async {
    // Cancel existing reminder for this bill first
    await _plugin.cancel(notificationId);

    final now = DateTime.now();
    var nextDue = DateTime(now.year, now.month, dayOfMonth)
        .subtract(const Duration(days: 2)); // 2 days before due

    if (nextDue.isBefore(now)) {
      nextDue = DateTime(now.year, now.month + 1, dayOfMonth)
          .subtract(const Duration(days: 2));
    }

    await _plugin.zonedSchedule(
      notificationId,
      '💡 বিল বকেয়া আছে',
      '$billNickname — পেমেন্ট করতে ভুলবেন না',
      TZDateTime.from(nextDue, local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bill_reminders',
          'বিল রিমাইন্ডার',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(int notificationId) async {
    await _plugin.cancel(notificationId);
  }
}
```

**Wire into BillAccountsNotifier** — schedule reminder on add/update:

```dart
// In BillAccountsNotifier.addAccount():
if (account.typicalDueDay != null) {
  final reminderService = ref.read(reminderServiceProvider);
  await reminderService.scheduleMonthlyReminder(
    notificationId: account.id.hashCode,
    billNickname: account.nickname,
    dayOfMonth: account.typicalDueDay!,
    billId: account.id,
  );
}
```

### Task 6.2 — FCM Setup for Future Remote Broadcasts

```dart
// In main.dart, after Firebase.initializeApp:
final messaging = FirebaseMessaging.instance;
await messaging.requestPermission();
final token = await messaging.getToken();
debugPrint('FCM token: $token');  // Store in Firestore if logged in

FirebaseMessaging.onMessage.listen((message) {
  // Show local notification for foreground messages
  debugPrint('FCM: ${message.notification?.title}');
});
```

**Add to `AndroidManifest.xml`:**
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

**Checkpoint:** Install app. Add a bill with due date = today + 3. Verify reminder fires after 2 minutes (adjust delay temporarily for testing).

---

## Phase 7 — Polish, Testing & Release (Day 9–10)

### Goal
Bug-free, tested MVP APK ready for internal testing / Play Store draft.

### Task 7.1 — Riverpod Provider Tests

```dart
// test/providers/bill_providers_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:bilbax/features/notifications/services/reminder_service.dart';
import 'package:bilbax/features/bills/providers/bill_providers.dart';
import 'bill_providers_test.mocks.dart';

@GenerateMocks([ReminderService])
void main() {
  setUpAll(() => sqfliteFfiInit());

  test('addAccount loads new account into state', () async {
    databaseFactory = databaseFactoryFfi;
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final mockReminder = MockReminderService();

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        reminderServiceProvider.overrideWithValue(mockReminder),
      ],
    );
    addTearDown(container.dispose);

    await container.read(billAccountsProvider.future);

    final notifier = container.read(billAccountsProvider.notifier);
    await notifier.addAccount(BillAccount.create(
      utilityType: UtilityType.desco,
      accountNumber: '111222',
      nickname: 'Test',
    ));

    final state = await container.read(billAccountsProvider.future);
    expect(state.accounts.length, 1);
    expect(state.accounts.first.nickname, 'Test');
  });
}
```

### Task 7.2 — Widget Smoke Tests

```dart
// test/widget/home_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bilbax/features/bills/presentation/screens/home_screen.dart';
import 'package:bilbax/features/bills/providers/bill_providers.dart';

void main() {
  testWidgets('shows empty state when no bills', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billAccountsProvider.overrideWith(() => _EmptyBillNotifier()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('কোনো বিল নেই'), findsOneWidget);
  });
}

class _EmptyBillNotifier extends AsyncNotifier<BillAccountsState> {
  @override
  Future<BillAccountsState> build() async =>
      BillAccountsState.fromAccounts([]);
}
```

### Task 7.3 — Release Build

```bash
# Android release APK
flutter build apk --release

# Or AAB for Play Store
flutter build appbundle --release

# Output: build/app/outputs/flutter-apk/app-release.apk
# Output: build/app/outputs/bundle/release/app-release.aab
```

**`android/app/build.gradle` — signing config:**
```groovy
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### Task 7.4 — Pre-Release Checklist

```
[ ] All bill types open the correct URL
[ ] bKash deeplinks tested on physical device
[ ] OTP login works with +880 number
[ ] Firestore sync round-trip tested (add on phone A, login on phone B)
[ ] Monthly reminder fires correctly (tested with 1-minute ahead time)
[ ] App works fully offline (airplane mode test)
[ ] Analytics shows chart for current month
[ ] Soft delete doesn't break payment history
[ ] Release APK installs on Android 8+ (API 26)
[ ] App name shows "বিলবাক্স" in Bengali on launcher
[ ] Firebase Remote Config serves updated URLs
```

---

## Summary: Day-by-Day Checklist

| Day | Tasks | Done When |
|---|---|---|
| 0 | Project create, deps, Firebase, `main.dart` | `flutter run` shows app on device |
| 1 | Models: `BillAccount`, `PaymentRecord`, `MonthlyTotal` | Unit tests pass |
| 2 | `DatabaseHelper`, repositories, core providers | DB creates, repos read/write |
| 3 | Riverpod providers, router, `HomeScreen` | Bills show in list |
| 4 | `AddBillScreen`, `BillCard`, `BillDetailScreen` | Can add/edit/delete bills |
| 5 | `PaymentRedirectScreen`, `LogPaymentSheet`, Remote Config | "পে করুন" opens URL, records payment |
| 6 | `PaymentHistoryScreen`, `AnalyticsScreen`, `fl_chart` | Chart shows monthly spend |
| 7 | Firebase Auth (OTP), Firestore sync | Login + sync works on real device |
| 8 | Local notifications, FCM, manifest permissions | Due date reminder fires |
| 9 | Tests (repo, provider, widget), release build | All tests green, APK builds |
| 10 | Buffer: Play Console draft, Firestore rules, polish | Uploaded to Play Console |

---

## Firestore Security Rules

```javascript
// firestore.rules
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

```bash
firebase deploy --only firestore:rules
```

---

## Cost Estimate (Monthly, Post-MVP)

| Service | Free Tier | MVP Usage | Cost |
|---|---|---|---|
| Firebase Auth | 10K verifications/month | ~500 logins | Free |
| Firestore | 1GB storage, 50K reads/day | <1MB, <1K reads | Free |
| Remote Config | Unlimited | 6 config keys | Free |
| FCM | Unlimited | Transactional | Free |
| Firebase Hosting (optional) | 10GB/month | Not needed at MVP | Free |
| **Total** | | | **৳০** |
