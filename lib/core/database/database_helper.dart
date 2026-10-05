import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations/v1_initial.dart';

/// SQLite singleton — schema & migrations live here.
class DatabaseHelper {
  static const _dbName = 'bilbax.db';
  static const _dbVersion = 1;

  static Database? _db;

  /// When true, opens an in-memory DB (tests only).
  final bool inMemory;

  DatabaseHelper({this.inMemory = false});

  Future<Database> get database async {
    if (inMemory) {
      return _openDatabase(inMemoryDatabasePath);
    }
    _db ??= await _openDatabase(join(await getDatabasesPath(), _dbName));
    return _db!;
  }

  Future<Database> _openDatabase(String path) {
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) => V1Initial.up(db),
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations: if (oldVersion < 2) { await V2.up(db); }
  }

  /// Closes the shared on-disk DB (useful in tests).
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  /// Resets the singleton cache without closing (tests that manage their own DB).
  static void resetSingleton() {
    _db = null;
  }
}
