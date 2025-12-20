import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/receipt.dart';

class ReceiptRepository {
  Database? _db;

  Future<void> init() async {
    if (_db != null) {
      return;
    }
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDir.path, 'receipts.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE receipts(
            id TEXT PRIMARY KEY,
            merchant_name TEXT,
            total_amount REAL,
            currency TEXT,
            purchase_date TEXT,
            category TEXT,
            status TEXT,
            image_path TEXT,
            raw_text TEXT,
            notes TEXT,
            created_at TEXT,
            updated_at TEXT,
            exported_at TEXT
          )
        ''');
      },
    );
  }

  Future<List<Receipt>> fetchAll() async {
    final db = _db;
    if (db == null) {
      return [];
    }
    final rows = await db.query('receipts', orderBy: 'purchase_date DESC');
    return rows.map(Receipt.fromMap).toList();
  }

  Future<void> upsert(Receipt receipt) async {
    final db = _db;
    if (db == null) {
      return;
    }
    await db.insert(
      'receipts',
      receipt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteByIds(List<String> ids) async {
    final db = _db;
    if (db == null || ids.isEmpty) {
      return;
    }
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      'receipts',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      return;
    }
    await db.close();
    _db = null;
  }
}
