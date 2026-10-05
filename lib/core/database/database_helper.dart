import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations/v1_initial.dart';

/// SQLite singleton — schema & migrations live here.
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
      onCreate: (db, version) => V1Initial.up(db),
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations: if (oldVersion < 2) { await V2.up(db); }
  }

  /// Closes the DB (useful in tests).
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
