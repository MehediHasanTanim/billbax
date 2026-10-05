import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';

/// Override in [main] after async init.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPreferencesProvider in main.dart');
});

/// Override in [main] after [DatabaseHelper] opens.
final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError('Override databaseProvider in main.dart');
});

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});
