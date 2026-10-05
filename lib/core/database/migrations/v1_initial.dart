import 'package:sqflite/sqflite.dart';

/// Initial schema for bilbax.db (version 1).
abstract final class V1Initial {
  static Future<void> up(Database db) async {
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

    await db.execute(
      'CREATE INDEX idx_payment_history_bill ON payment_history(bill_account_id)',
    );
    await db.execute(
      'CREATE INDEX idx_payment_history_paid ON payment_history(paid_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_bills_active ON bill_accounts(is_active)',
    );
  }
}
