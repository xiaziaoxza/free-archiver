import 'package:flutter/material.dart';
import '../models/archive_info.dart';
import '../models/archive_format.dart';

/// Possible states for archive operations
enum ArchiveOperationState { idle, listing, extracting, creating, done, error }

/// Provider for archive operations state
class ArchiveProvider extends ChangeNotifier {
  ArchiveInfo? _currentArchive;
  ArchiveOperationState _state = ArchiveOperationState.idle;
  String? _error;
  double _progress = 0;
  String _progressText = '';

  // Getters
  ArchiveInfo? get currentArchive => _currentArchive;
  ArchiveOperationState get state => _state;
  String? get error => _error;
  double get progress => _progress;
  String get progressText => _progressText;
  bool get isBusy => _state == ArchiveOperationState.listing ||
      _state == ArchiveOperationState.extracting ||
      _state == ArchiveOperationState.creating;

  /// Start listing an archive
  Future<void> listArchive(String path) async {
    _state = ArchiveOperationState.listing;
    _error = null;
    _progress = 0;
    _progressText = '正在读取归档...';
    notifyListeners();

    try {
      final format = ArchiveFormat.fromPath(path);
      if (format == null) {
        throw Exception('不支持的归档格式');
      }

      // TODO: Implement actual archive listing via service
      // _currentArchive = await _archiveService.list(path, format);

      _state = ArchiveOperationState.done;
      _progress = 1;
    } catch (e) {
      _state = ArchiveOperationState.error;
      _error = e.toString();
    }

    notifyListeners();
  }

  /// Start extracting an archive
  Future<void> extractArchive(
    String archivePath, {
    required String destDir,
    String? password,
    bool autoFindPassword = true,
  }) async {
    _state = ArchiveOperationState.extracting;
    _error = null;
    _progress = 0;
    _progressText = '正在解压...';
    notifyListeners();

    try {
      // TODO: Implement actual extraction via service
      _state = ArchiveOperationState.done;
      _progress = 1;
    } catch (e) {
      _state = ArchiveOperationState.error;
      _error = e.toString();
    }

    notifyListeners();
  }

  /// Start creating an archive
  Future<void> createArchive({
    required String outputPath,
    required List<String> sourcePaths,
    required ArchiveFormat format,
    int compressionLevel = 6,
    String? password,
  }) async {
    _state = ArchiveOperationState.creating;
    _error = null;
    _progress = 0;
    _progressText = '正在创建归档...';
    notifyListeners();

    try {
      // TODO: Implement actual creation via service
      _state = ArchiveOperationState.done;
      _progress = 1;
    } catch (e) {
      _state = ArchiveOperationState.error;
      _error = e.toString();
    }

    notifyListeners();
  }

  /// Reset state
  void reset() {
    _state = ArchiveOperationState.idle;
    _error = null;
    _progress = 0;
    _progressText = '';
    notifyListeners();
  }

  /// Clear current archive
  void clearArchive() {
    _currentArchive = null;
    reset();
    notifyListeners();
  }
}
