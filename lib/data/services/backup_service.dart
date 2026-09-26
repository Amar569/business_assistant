import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:business_assistant/data/datasources/local/local_datasource.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  final LocalDataSource localDataSource;

  BackupService(this.localDataSource);

  static const List<String> _tables = [
    'customers',
    'invoices',
    'quotations',
    'payments',
  ];

  /// Exports all tables into a single JSON file and returns its path.
  Future<String> exportBackup() async {
    final Map<String, dynamic> backupData = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
    };

    for (final table in _tables) {
      final rows = await localDataSource.query(table);
      backupData[table] = rows;
    }

    final jsonString = jsonEncode(backupData);

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'business_assistant_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonString);

    return file.path;
  }

  /// Restores data from a backup JSON file.
  /// [merge] = true keeps existing rows and skips duplicates by id;
  /// false clears each table first (full overwrite restore).
  Future<void> restoreBackup(String filePath, {bool merge = false}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Backup file not found');
    }

    final jsonString = await file.readAsString();
    final Map<String, dynamic> backupData = jsonDecode(jsonString);

    final db = await localDataSource.database;

    await db.transaction((txn) async {
      for (final table in _tables) {
        if (!backupData.containsKey(table)) continue;

        final rows = List<Map<String, dynamic>>.from(backupData[table]);

        if (!merge) {
          await txn.delete(table);
        }

        for (final row in rows) {
          await txn.insert(
            table,
            row,
            conflictAlgorithm: merge
                ? ConflictAlgorithm.ignore // keep existing on conflict
                : ConflictAlgorithm.replace,
          );
        }
      }
    });
  }
}