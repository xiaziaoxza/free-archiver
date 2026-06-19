import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../models/archive_format.dart';
import '../database/database_helper.dart';

/// Possible states for password finding
enum PasswordFindState { idle, searching, found, notFound, error }

/// Result of a password find operation
class PasswordFindResult {
  final String password;
  final PasswordSource source;
  final int candidatesTested;

  const PasswordFindResult({
    required this.password,
    required this.source,
    this.candidatesTested = 0,
  });
}

/// Provider for password management and auto-finding
class PasswordProvider extends ChangeNotifier {
  final Map<String, String> _passwordCache = {}; // archivePath -> password
  PasswordFindState _findState = PasswordFindState.idle;
  String _findProgress = '';
  PasswordFindResult? _lastResult;
  String? _error;
  List<PasswordEntry> _savedPasswords = [];
  DatabaseHelper? _db;

  // Getters
  PasswordFindState get findState => _findState;
  String get findProgress => _findProgress;
  PasswordFindResult? get lastResult => _lastResult;
  String? get error => _error;
  List<PasswordEntry> get savedPasswords => _savedPasswords;

  Future<void> initialize() async {
    _db = DatabaseHelper();
    await _db!.database; // Ensure DB is initialized
    await loadPasswords();
  }

  /// Load all saved passwords from database
  Future<void> loadPasswords() async {
    if (_db == null) return;
    // TODO: Load from database
    _savedPasswords = [];
    notifyListeners();
  }

  /// Check password cache
  String? getCachedPassword(String archivePath) {
    return _passwordCache[archivePath];
  }

  /// Start auto-finding password for an archive
  Future<PasswordFindResult?> autoFindPassword(
    String archivePath, {
    ArchiveFormat? format,
  }) async {
    _findState = PasswordFindState.searching;
    _findProgress = '正在查找密码...';
    _error = null;
    notifyListeners();

    try {
      // Stage 1: Check cache
      final cached = _passwordCache[archivePath];
      if (cached != null) {
        _findState = PasswordFindState.found;
        _lastResult = PasswordFindResult(
          password: cached,
          source: PasswordSource.cache,
        );
        notifyListeners();
        return _lastResult;
      }

      // Stage 2: Parse filename for hints
      _findProgress = '正在从文件名解析密码...';
      final filenameHints = await _parseFilename(archivePath);
      if (filenameHints.isNotEmpty) {
        _findProgress = '正在尝试文件名提取的密码...';
        // TODO: Try each hint against the archive
        for (final hint in filenameHints) {
          final valid = await _tryPassword(archivePath, hint, format);
          if (valid) {
            _passwordCache[archivePath] = hint;
            await _saveSuccessfulPassword(archivePath, hint, 'filename');
            _findState = PasswordFindState.found;
            _lastResult = PasswordFindResult(
              password: hint,
              source: PasswordSource.filenameExtracted,
              candidatesTested: filenameHints.indexOf(hint) + 1,
            );
            notifyListeners();
            return _lastResult;
          }
        }
      }

      // Stage 3: Query database
      _findProgress = '正在查询密码库...';
      final dbMatches = await _queryDatabase(archivePath);
      if (dbMatches.isNotEmpty) {
        for (final entry in dbMatches) {
          final valid = await _tryPassword(archivePath, entry.password, format);
          if (valid) {
            _passwordCache[archivePath] = entry.password;
            _findState = PasswordFindState.found;
            _lastResult = PasswordFindResult(
              password: entry.password,
              source: PasswordSource.database,
            );
            notifyListeners();
            return _lastResult;
          }
        }
      }

      // Stage 4: Dictionary attack
      _findProgress = '正在尝试常用密码...';
      final dictResult = await _dictionaryAttack(archivePath, format);
      if (dictResult != null) {
        _passwordCache[archivePath] = dictResult.password;
        await _saveSuccessfulPassword(archivePath, dictResult.password, 'dictionary');
        _findState = PasswordFindState.found;
        _lastResult = dictResult;
        notifyListeners();
        return _lastResult;
      }

      // Not found
      _findState = PasswordFindState.notFound;
      _findProgress = '未找到密码，请手动输入';
    } catch (e) {
      _findState = PasswordFindState.error;
      _error = e.toString();
      _findProgress = '查找密码时出错';
    }

    notifyListeners();
    return null;
  }

  /// Parse filename for password hints
  Future<List<String>> _parseFilename(String archivePath) async {
    final filename = archivePath.split('/').last;
    final stem = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    final hints = <String>[];

    // Pattern 1: Domain extraction (e.g., "file_www.example.com.rar" -> "www.example.com")
    final urlPattern = RegExp(r'(?:www\.)?[a-zA-Z0-9-]+(?:\.[a-zA-Z]{2,})+');
    for (final match in urlPattern.allMatches(stem)) {
      hints.add(match.group(0)!);
    }

    // Pattern 2: 8-digit date (YYYYMMDD, DDMMYYYY)
    final datePattern = RegExp(r'\b\d{8}\b');
    for (final match in datePattern.allMatches(stem)) {
      hints.add(match.group(0)!);
    }

    // Pattern 3: 4-6 digit numbers
    final numPattern = RegExp(r'\b\d{4,6}\b');
    for (final match in numPattern.allMatches(stem)) {
      hints.add(match.group(0)!);
    }

    // Pattern 4: The file stem itself
    if (stem.length >= 3 && stem.length <= 32) {
      hints.add(stem);
    }

    return hints;
  }

  /// Query database for matching passwords
  Future<List<PasswordEntry>> _queryDatabase(String archivePath) async {
    if (_db == null) return [];
    final filename = archivePath.split('/').last;
    return _savedPasswords.where((entry) {
      // Simple glob matching
      final pattern = entry.filenamePattern
          .replaceAll('*', '.*')
          .replaceAll('?', '.');
      try {
        return RegExp(pattern, caseSensitive: false).hasMatch(filename);
      } catch (_) {
        return filename.toLowerCase().contains(entry.filenamePattern.toLowerCase());
      }
    }).toList();
  }

  /// Try common passwords from dictionary
  Future<PasswordFindResult?> _dictionaryAttack(
    String archivePath,
    ArchiveFormat? format,
  ) async {
    // For now: try a small set of common passwords
    const commonPasswords = [
      '123456', 'password', '12345678', 'qwerty', '12345',
      'wwwroot', 'admin', 'abc123', 'iloveyou', '5201314',
    ];

    for (int i = 0; i < commonPasswords.length; i++) {
      _findProgress = '正在尝试密码 (${i + 1}/${commonPasswords.length})...';
      final valid = await _tryPassword(archivePath, commonPasswords[i], format);
      if (valid) {
        return PasswordFindResult(
          password: commonPasswords[i],
          source: PasswordSource.dictionary,
          candidatesTested: i + 1,
        );
      }
    }

    return null;
  }

  /// Try a specific password against an archive
  Future<bool> _tryPassword(
    String archivePath,
    String password,
    ArchiveFormat? format,
  ) async {
    // TODO: Actually try the password against the archive
    await Future.delayed(const Duration(milliseconds: 50));
    return false; // Placeholder
  }

  /// Save a successfully found password
  Future<void> _saveSuccessfulPassword(
    String archivePath,
    String password,
    String source,
  ) async {
    if (_db == null) return;
    // TODO: Save to database
  }

  /// Add a password manually
  Future<void> addPassword(String filenamePattern, String password, {String source = 'manual'}) async {
    _savedPasswords.add(PasswordEntry(
      filenamePattern: filenamePattern,
      password: password,
      source: source,
      createdAt: DateTime.now(),
      successCount: 1,
    ));
    notifyListeners();
  }

  /// Cache a password for an archive
  void cachePassword(String archivePath, String password) {
    _passwordCache[archivePath] = password;
  }

  /// Reset find state
  void resetFind() {
    _findState = PasswordFindState.idle;
    _findProgress = '';
    _error = null;
    notifyListeners();
  }
}
