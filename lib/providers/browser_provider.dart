import 'dart:io';
import 'package:flutter/material.dart';

/// Represents a file system item in the browser
class FileItem {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime modified;

  const FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.modified,
  });
}

/// Provider for file browser state
class BrowserProvider extends ChangeNotifier {
  String _currentPath = '/storage/emulated/0';
  List<FileItem> _items = [];
  bool _isLoading = false;
  String? _error;
  final Set<String> _selectedPaths = {};
  final List<String> _pathHistory = [];
  int _historyIndex = -1;
  String _searchQuery = '';

  // Getters
  String get currentPath => _currentPath;
  List<FileItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get selectedPaths => _selectedPaths;
  bool get canGoBack => _historyIndex > 0;
  bool get canGoForward => _historyIndex < _pathHistory.length - 1;
  String get searchQuery => _searchQuery;

  /// Navigate to a directory
  Future<void> navigateTo(String path) async {
    if (!Directory(path).existsSync()) {
      _error = '目录不存在: $path';
      notifyListeners();
      return;
    }

    _currentPath = path;
    _selectedPaths.clear();
    _searchQuery = '';

    // Update history
    if (_historyIndex < _pathHistory.length - 1) {
      _pathHistory.removeRange(_historyIndex + 1, _pathHistory.length);
    }
    _pathHistory.add(path);
    _historyIndex = _pathHistory.length - 1;

    await _loadDirectory();
  }

  /// Go back in history
  Future<void> goBack() async {
    if (_historyIndex > 0) {
      _historyIndex--;
      _currentPath = _pathHistory[_historyIndex];
      _selectedPaths.clear();
      await _loadDirectory();
    }
  }

  /// Go forward in history
  Future<void> goForward() async {
    if (_historyIndex < _pathHistory.length - 1) {
      _historyIndex++;
      _currentPath = _pathHistory[_historyIndex];
      _selectedPaths.clear();
      await _loadDirectory();
    }
  }

  /// Go to parent directory
  Future<void> goUp() async {
    final parent = _getParentPath(_currentPath);
    if (parent != _currentPath) {
      await navigateTo(parent);
    }
  }

  /// Load directory contents
  Future<void> _loadDirectory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dir = Directory(_currentPath);
      final entities = dir.listSync();

      _items = entities
          .map((e) {
            final stat = e.statSync();
            return FileItem(
              name: _getName(e.path),
              path: e.path,
              isDirectory: stat.type == FileSystemEntityType.directory,
              size: stat.size,
              modified: stat.modified,
            );
          })
          .toList();

      // Sort: directories first, then by name
      _items.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    } catch (e) {
      _error = '无法读取目录: $e';
      _items = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Toggle selection of a file/directory
  void toggleSelection(String path) {
    if (_selectedPaths.contains(path)) {
      _selectedPaths.remove(path);
    } else {
      _selectedPaths.add(path);
    }
    notifyListeners();
  }

  /// Select all items
  void selectAll() {
    _selectedPaths.addAll(_items.map((e) => e.path));
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedPaths.clear();
    notifyListeners();
  }

  /// Set search query and filter
  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Get filtered items
  List<FileItem> getFilteredItems() {
    if (_searchQuery.isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items.where((item) => item.name.toLowerCase().contains(q)).toList();
  }

  String _getName(String path) {
    path = path.replaceAll('\\', '/');
    if (path.endsWith('/')) path = path.substring(0, path.length - 1);
    return path.split('/').last;
  }

  String _getParentPath(String path) {
    path = path.replaceAll('\\', '/');
    if (path.endsWith('/')) path = path.substring(0, path.length - 1);
    final idx = path.lastIndexOf('/');
    if (idx <= 0) return '/';
    return path.substring(0, idx);
  }
}
