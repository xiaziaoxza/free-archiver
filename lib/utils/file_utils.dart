import 'dart:io';

/// File utility functions
class FileUtils {
  FileUtils._();

  /// Format file size to human-readable string
  static String formatSize(int bytes) {
    if (bytes < 0) return '---';
    if (bytes == 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    if (unitIndex == 0) {
      return '${size.toInt()} ${units[unitIndex]}';
    }
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Detect file type category by extension
  static String fileTypeCategory(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    const archives = {'zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz', 'zst', 'zstd', 'tgz', 'tbz', 'txz', 'jar', 'apk'};
    const images = {'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg', 'ico', 'heic', 'heif'};
    const videos = {'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', '3gp', 'm4v'};
    const audio = {'mp3', 'wav', 'flac', 'aac', 'ogg', 'wma', 'm4a', 'opus'};
    const documents = {'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv', 'md', 'epub', 'mobi'};
    const code = {'dart', 'py', 'js', 'ts', 'java', 'kt', 'c', 'cpp', 'h', 'rs', 'go', 'rb', 'php', 'html', 'css', 'json', 'xml', 'yaml', 'sh'};

    if (archives.contains(ext)) return '归档';
    if (images.contains(ext)) return '图片';
    if (videos.contains(ext)) return '视频';
    if (audio.contains(ext)) return '音频';
    if (documents.contains(ext)) return '文档';
    if (code.contains(ext)) return '代码';
    return '其他';
  }

  /// Get a simple icon character for a file type
  static String fileIcon(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'zip': case 'rar': case '7z': case 'tar': case 'gz': case 'bz2':
      case 'xz': case 'zst': case 'tgz': case 'tbz': case 'txz':
        return '📦';
      case 'jpg': case 'jpeg': case 'png': case 'gif': case 'bmp':
      case 'webp': case 'svg': case 'heic':
        return '🖼️';
      case 'mp4': case 'mkv': case 'avi': case 'mov': case 'webm':
        return '🎬';
      case 'mp3': case 'wav': case 'flac': case 'aac': case 'ogg':
        return '🎵';
      case 'pdf':
        return '📕';
      case 'doc': case 'docx':
        return '📝';
      case 'xls': case 'xlsx':
        return '📊';
      case 'txt': case 'md':
        return '📄';
      case 'apk':
        return '📱';
      default:
        return '📄';
    }
  }

  /// Check if a path is a directory
  static bool isDirectory(String path) {
    try {
      return FileSystemEntity.isDirectorySync(path);
    } catch (_) {
      return false;
    }
  }

  /// Check if a path is a file
  static bool isFile(String path) {
    try {
      return FileSystemEntity.isFileSync(path);
    } catch (_) {
      return false;
    }
  }

  /// Get file or directory name from path
  static String getName(String path) {
    path = path.replaceAll('\\', '/');
    // Remove trailing slash
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    final lastSlash = path.lastIndexOf('/');
    return lastSlash >= 0 ? path.substring(lastSlash + 1) : path;
  }

  /// Get parent directory path
  static String getParent(String path) {
    path = path.replaceAll('\\', '/');
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash <= 0) return '/';
    return path.substring(0, lastSlash);
  }
}
