import 'dart:io';

/// Service for file system operations
class FileService {
  /// Copy a file or directory
  static Future<void> copy(String source, String dest, {void Function(double)? onProgress}) async {
    final src = source;
    final dst = dest;

    if (Directory(src).existsSync()) {
      await _copyDirectory(src, dst, onProgress: onProgress);
    } else if (File(src).existsSync()) {
      await _copyFile(src, dst);
    } else {
      throw Exception('源路径不存在: $src');
    }
  }

  static Future<void> _copyFile(String source, String dest) async {
    final file = File(source);
    await file.copy(dest);
  }

  static Future<void> _copyDirectory(String source, String dest, {void Function(double)? onProgress}) async {
    final dir = Directory(dest);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final entities = Directory(source).listSync();
    for (int i = 0; i < entities.length; i++) {
      final entity = entities[i];
      final newPath = '$dest/${entity.path.split('/').last}';

      if (entity is Directory) {
        await _copyDirectory(entity.path, newPath);
      } else if (entity is File) {
        await _copyFile(entity.path, newPath);
      }

      onProgress?.call((i + 1) / entities.length);
    }
  }

  /// Move a file or directory
  static Future<void> move(String source, String dest) async {
    final src = source;
    final dst = dest;

    if (Directory(src).existsSync()) {
      await Directory(src).rename(dst);
    } else if (File(src).existsSync()) {
      await File(src).rename(dst);
    } else {
      throw Exception('源路径不存在: $src');
    }
  }

  /// Delete a file or directory
  static Future<void> delete(String path) async {
    if (Directory(path).existsSync()) {
      await Directory(path).delete(recursive: true);
    } else if (File(path).existsSync()) {
      await File(path).delete();
    }
  }

  /// Rename a file or directory
  static Future<void> rename(String oldPath, String newName) {
    final parent = oldPath.split('/').sublist(0, oldPath.split('/').length - 1).join('/');
    final newPath = '$parent/$newName';
    return move(oldPath, newPath);
  }

  /// Create a new directory
  static Future<Directory> createDirectory(String path) async {
    return Directory(path).create(recursive: true);
  }

  /// Get disk space info for a path
  static Future<DiskInfo> getDiskInfo(String path) async {
    try {
      // On Android, we can't easily get disk info. Return placeholder.
      return DiskInfo(
        totalSpace: 0,
        freeSpace: 0,
        usedSpace: 0,
      );
    } catch (_) {
      return DiskInfo(totalSpace: 0, freeSpace: 0, usedSpace: 0);
    }
  }
}

class DiskInfo {
  final int totalSpace;
  final int freeSpace;
  final int usedSpace;

  const DiskInfo({
    required this.totalSpace,
    required this.freeSpace,
    required this.usedSpace,
  });

  double get usageRatio => totalSpace > 0 ? usedSpace / totalSpace : 0;
}
