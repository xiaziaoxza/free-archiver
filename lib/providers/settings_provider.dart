import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _defaultExtractDir = '';
  int _defaultCompressionLevel = 6;
  bool _autoFindPassword = true;
  bool _showHiddenFiles = false;
  String _sortBy = 'name'; // name, size, date, type
  bool _sortAscending = true;

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get defaultExtractDir => _defaultExtractDir;
  int get defaultCompressionLevel => _defaultCompressionLevel;
  bool get autoFindPassword => _autoFindPassword;
  bool get showHiddenFiles => _showHiddenFiles;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  Future<void> initialize() async {
    // In future: load from SharedPreferences
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setDefaultExtractDir(String dir) {
    _defaultExtractDir = dir;
    notifyListeners();
  }

  void setDefaultCompressionLevel(int level) {
    _defaultCompressionLevel = level.clamp(0, 9);
    notifyListeners();
  }

  void setAutoFindPassword(bool value) {
    _autoFindPassword = value;
    notifyListeners();
  }

  void setShowHiddenFiles(bool value) {
    _showHiddenFiles = value;
    notifyListeners();
  }

  void setSortBy(String field) {
    _sortBy = field;
    notifyListeners();
  }

  void toggleSortOrder() {
    _sortAscending = !_sortAscending;
    notifyListeners();
  }
}
