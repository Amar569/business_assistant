import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:business_assistant/core/constants/app_constants.dart';

class LocalDataSource {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, AppConstants.databaseName);

    return await openDatabase(
      dbPath,
      version: AppConstants.databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Create Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        gstin TEXT,
        outstandingBalance REAL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');

    // Create Invoices Table
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        invoiceNumber TEXT NOT NULL UNIQUE,
        customerId TEXT NOT NULL,
        date TEXT NOT NULL,
        dueDate TEXT,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        taxRate REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        items TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE quotations (
        id TEXT PRIMARY KEY,
        quotationNumber TEXT NOT NULL,
        customerId TEXT NOT NULL,
        customerName TEXT NOT NULL,
        date TEXT NOT NULL,
        validUntil TEXT,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        taxRate REAL NOT NULL,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        items TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create Payments Table
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        invoiceId TEXT NOT NULL,
        customerId TEXT NOT NULL,
        amount REAL NOT NULL,
        paymentDate TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        transactionId TEXT,
        status TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Create Settings Table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Add the taxRate column to existing invoices tables that were
      // created before this column existed.
      final columns = await db.rawQuery('PRAGMA table_info(invoices)');
      final hasTaxRate = columns.any((col) => col['name'] == 'taxRate');
      if (!hasTaxRate) {
        await db.execute(
          'ALTER TABLE invoices ADD COLUMN taxRate REAL NOT NULL DEFAULT 0',
        );
      }
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quotations (
          id TEXT PRIMARY KEY,
          quotationNumber TEXT NOT NULL UNIQUE,
          customerId TEXT NOT NULL,
          date TEXT NOT NULL,
          validUntil TEXT,
          subtotal REAL NOT NULL,
          tax REAL NOT NULL,
          taxRate REAL NOT NULL DEFAULT 0,
          total REAL NOT NULL,
          status TEXT NOT NULL,
          items TEXT NOT NULL,
          notes TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT,
          FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // Generic CRUD Operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> getCount(String table) async {
    final db = await database;
    final result = await db.query(table);
    return result.length;
  }
}
