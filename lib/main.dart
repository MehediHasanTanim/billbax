import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/database/database_helper.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';
import 'providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebase();

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
  } catch (e, st) {
    debugPrint('Firebase: init failed — $e');
    debugPrint('$st');
  }
}

class BilBaxApp extends ConsumerWidget {
  const BilBaxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
