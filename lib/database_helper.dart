import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('barcode.db');
    return _database!;
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      if (kIsWeb) {
        // Initialize for web
        var factory = databaseFactoryFfiWeb;
        return await factory.openDatabase(filePath,
            options: OpenDatabaseOptions(
              version: 1,
              onCreate: _createDB,
              onUpgrade: _upgradeDB,
            ));
      } else {
        // Initialize for other platforms
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, filePath);
        return await openDatabase(
          path,
          version: 1,
          onCreate: _createDB,
          onUpgrade: _upgradeDB,
        );
      }
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE barcodes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        description TEXT,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Create index for faster barcode lookups
    await db.execute('CREATE INDEX idx_barcode_code ON barcodes(code)');
    await db.execute('CREATE INDEX idx_barcode_date ON barcodes(created_at DESC)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle future database upgrades here
    if (oldVersion < newVersion) {
      // Add upgrade logic when needed
    }
  }

  Future<int> insertBarcode(String code, String description) async {
    try {
      final db = await database;
      return await db.insert(
        'barcodes',
        {
          'code': code,
          'description': description,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to insert barcode: $e');
    }
  }

  Future<Map<String, dynamic>?> getBarcodeInfo(String code) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'barcodes',
        where: 'code = ?',
        whereArgs: [code],
        limit: 1,
      );

      return maps.isNotEmpty ? maps.first : null;
    } catch (e) {
      throw Exception('Failed to get barcode info: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllBarcodes() async {
    try {
      final db = await database;
      return await db.query('barcodes', orderBy: 'created_at DESC');
    } catch (e) {
      throw Exception('Failed to get all barcodes: $e');
    }
  }

  Future<int> deleteBarcode(String code) async {
    try {
      final db = await database;
      return await db.delete(
        'barcodes',
        where: 'code = ?',
        whereArgs: [code],
      );
    } catch (e) {
      throw Exception('Failed to delete barcode: $e');
    }
  }

  Future<int> updateBarcode(String code, String description) async {
    try {
      final db = await database;
      return await db.update(
        'barcodes',
        {'description': description},
        where: 'code = ?',
        whereArgs: [code],
      );
    } catch (e) {
      throw Exception('Failed to update barcode: $e');
    }
  }

  Future<void> clearAllBarcodes() async {
    try {
      final db = await database;
      await db.delete('barcodes');
    } catch (e) {
      throw Exception('Failed to clear barcodes: $e');
    }
  }
}