/// Supported archive formats
enum ArchiveFormat {
  zip,
  rar,
  sevenZ,
  tar,
  gzip,
  bzip2,
  xz,
  zstd;

  /// File extensions associated with this format
  List<String> get extensions {
    switch (this) {
      case ArchiveFormat.zip:
        return ['zip', 'jar', 'apk', 'docx', 'xlsx', 'pptx', 'epub'];
      case ArchiveFormat.rar:
        return ['rar', 'r00', 'r01'];
      case ArchiveFormat.sevenZ:
        return ['7z'];
      case ArchiveFormat.tar:
        return ['tar'];
      case ArchiveFormat.gzip:
        return ['gz', 'tgz'];
      case ArchiveFormat.bzip2:
        return ['bz2', 'tbz', 'tbz2'];
      case ArchiveFormat.xz:
        return ['xz', 'txz'];
      case ArchiveFormat.zstd:
        return ['zst', 'zstd', 'tzst'];
    }
  }

  /// Detect format from a file path's extension
  static ArchiveFormat? fromPath(String path) {
    final lower = path.toLowerCase();
    // Check compound extensions first (tar.gz, tar.bz2, etc.)
    if (lower.endsWith('.tar.gz') || lower.endsWith('.tgz')) {
      return ArchiveFormat.gzip;
    }
    if (lower.endsWith('.tar.bz2') || lower.endsWith('.tbz') || lower.endsWith('.tbz2')) {
      return ArchiveFormat.bzip2;
    }
    if (lower.endsWith('.tar.xz') || lower.endsWith('.txz')) {
      return ArchiveFormat.xz;
    }
    if (lower.endsWith('.tar.zst') || lower.endsWith('.tzst')) {
      return ArchiveFormat.zstd;
    }

    // Single extension detection
    for (final format in ArchiveFormat.values) {
      for (final ext in format.extensions) {
        if (lower.endsWith('.$ext')) {
          return format;
        }
      }
    }
    return null;
  }

  /// Whether this format supports password encryption
  bool get supportsPassword {
    switch (this) {
      case ArchiveFormat.zip:
      case ArchiveFormat.rar:
      case ArchiveFormat.sevenZ:
        return true;
      default:
        return false;
    }
  }

  /// Whether this format supports split/span volumes
  bool get supportsSplitting {
    switch (this) {
      case ArchiveFormat.zip:
      case ArchiveFormat.rar:
      case ArchiveFormat.sevenZ:
        return true;
      default:
        return false;
    }
  }

  /// Display name
  String get displayName {
    switch (this) {
      case ArchiveFormat.zip:
        return 'ZIP';
      case ArchiveFormat.rar:
        return 'RAR';
      case ArchiveFormat.sevenZ:
        return '7z';
      case ArchiveFormat.tar:
        return 'TAR';
      case ArchiveFormat.gzip:
        return 'GZip';
      case ArchiveFormat.bzip2:
        return 'BZip2';
      case ArchiveFormat.xz:
        return 'XZ';
      case ArchiveFormat.zstd:
        return 'Zstandard';
    }
  }
}
