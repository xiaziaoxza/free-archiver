import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/constants.dart';

/// Database helper for SQLite operations
class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Passwords table
    await db.execute('''
      CREATE TABLE passwords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filename_pattern TEXT NOT NULL,
        password TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual',
        confidence INTEGER NOT NULL DEFAULT 50,
        created_at INTEGER NOT NULL,
        last_used_at INTEGER,
        success_count INTEGER NOT NULL DEFAULT 0,
        fail_count INTEGER NOT NULL DEFAULT 0,
        UNIQUE(filename_pattern, password, source)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_passwords_pattern ON passwords(filename_pattern)
    ''');
    await db.execute('''
      CREATE INDEX idx_passwords_source ON passwords(source)
    ''');

    // Community passwords table
    await db.execute('''
      CREATE TABLE community_passwords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        domain TEXT NOT NULL,
        password TEXT NOT NULL,
        download_count INTEGER NOT NULL DEFAULT 0,
        verify_count INTEGER NOT NULL DEFAULT 0,
        reliability REAL NOT NULL DEFAULT 0.5,
        added_at INTEGER NOT NULL,
        UNIQUE(domain, password)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_community_domain ON community_passwords(domain)
    ''');

    // Bookmarks table
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT NOT NULL UNIQUE,
        label TEXT,
        added_at INTEGER NOT NULL
      )
    ''');

    // Operation history table
    await db.execute('''
      CREATE TABLE operation_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL,
        archive_path TEXT NOT NULL,
        target_path TEXT,
        format TEXT,
        success INTEGER NOT NULL,
        password_used TEXT,
        error_message TEXT,
        started_at INTEGER NOT NULL,
        duration_ms INTEGER,
        file_count INTEGER,
        total_bytes INTEGER
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_history_time ON operation_history(started_at DESC)
    ''');
    await db.execute('''
      CREATE INDEX idx_history_type ON operation_history(operation_type)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations
  }

  // --- Password CRUD ---

  Future<int> insertPassword(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('passwords', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryPasswords(String pattern) async {
    final db = await database;
    return await db.query(
      'passwords',
      where: 'filename_pattern LIKE ?',
      whereArgs: ['%$pattern%'],
      orderBy: 'success_count DESC',
      limit: 50,
    );
  }

  Future<List<Map<String, dynamic>>> getAllPasswords() async {
    final db = await database;
    return await db.query('passwords', orderBy: 'created_at DESC');
  }

  Future<int> updatePasswordSuccess(int id) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE passwords SET success_count = success_count + 1, last_used_at = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch, id],
    );
  }

  Future<int> deletePassword(int id) async {
    final db = await database;
    return await db.delete('passwords', where: 'id = ?', whereArgs: [id]);
  }

  // --- Bookmarks ---

  Future<int> insertBookmark(String path, {String? label}) async {
    final db = await database;
    return await db.insert('bookmarks', {
      'path': path,
      'label': label,
      'added_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final db = await database;
    return await db.query('bookmarks', orderBy: 'added_at DESC');
  }

  Future<int> deleteBookmark(String path) async {
    final db = await database;
    return await db.delete('bookmarks', where: 'path = ?', whereArgs: [path]);
  }

  // --- Operation History ---

  Future<int> insertHistory(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('operation_history', row);
  }

  Future<List<Map<String, dynamic>>> getRecentHistory({int limit = 50}) async {
    final db = await database;
    return await db.query(
      'operation_history',
      orderBy: 'started_at DESC',
      limit: limit,
    );
  }
}
