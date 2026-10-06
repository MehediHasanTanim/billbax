import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/database/database_helper.dart';
import 'core/router/app_router.dart';
import 'features/bills/providers/bill_providers.dart';
import 'features/notifications/services/reminder_service.dart';
import 'firebase_options.dart';
import 'providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebase();

  final reminderService = ReminderService();
  await reminderService.init();

  final dbHelper = DatabaseHelper();
  final db = await dbHelper.database;
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        reminderServiceProvider.overrideWithValue(reminderService),
      ],
      child: const BilBaxApp(),
    ),
  );
}

Future<void> _initializeFirebase() async {
  if (!DefaultFirebaseOptions.isConfigured) {
    debugPrint(
      'Firebase: not configured yet. Run `flutterfire configure` '
      '(project package: com.nextgenai.billbax). Continuing without Firebase.',
    );
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase: initialized');
    await _initializeFcm();
  } catch (e, st) {
    debugPrint('Firebase: init failed — $e');
    debugPrint('$st');
  }
}

Future<void> _initializeFcm() async {
  if (Firebase.apps.isEmpty) return;

  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final token = await messaging.getToken();
    debugPrint('FCM token: $token');

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground: ${message.notification?.title}');
      final title = message.notification?.title ?? 'বিলবাক্স';
      final body = message.notification?.body ?? '';
      // Best-effort local mirror for foreground pushes.
      ReminderService().showImmediate(title: title, body: body);
    });
  } catch (e, st) {
    debugPrint('FCM init skipped: $e\n$st');
  }
}

class BilBaxApp extends ConsumerStatefulWidget {
  const BilBaxApp({super.key});

  @override
  ConsumerState<BilBaxApp> createState() => _BilBaxAppState();
}

class _BilBaxAppState extends ConsumerState<BilBaxApp> {
  @override
  void initState() {
    super.initState();
    // Reschedule after first frame so DB + providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billAccountsProvider.notifier).rescheduleAllReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
