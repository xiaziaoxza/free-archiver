/// Represents a single entry (file or directory) inside an archive
class ArchiveEntry {
  /// Full path inside the archive
  final String path;

  /// Uncompressed size in bytes
  final int size;

  /// Compressed size in bytes (0 if same as size or unknown)
  final int compressedSize;

  /// Whether this entry is a directory
  final bool isDirectory;

  /// Whether this entry is password-protected
  final bool isEncrypted;

  /// Whether this entry is a symlink
  final bool isSymlink;

  /// Modification timestamp (null if not available)
  final DateTime? modified;

  /// CRC32 checksum (null if not available)
  final int? crc32;

  const ArchiveEntry({
    required this.path,
    required this.size,
    this.compressedSize = 0,
    this.isDirectory = false,
    this.isEncrypted = false,
    this.isSymlink = false,
    this.modified,
    this.crc32,
  });

  /// Compression ratio: compressedSize / size. 0 if size is 0.
  double get ratio {
    if (size == 0) return 0;
    if (compressedSize == 0) return 1.0;
    return compressedSize / size;
  }

  /// File name (last component of path)
  String get name {
    final parts = path.split('/');
    return parts.lastWhere((p) => p.isNotEmpty, orElse: () => path);
  }

  /// Parent directory path inside archive
  String get parentPath {
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash <= 0) return '';
    return path.substring(0, lastSlash);
  }

  /// File extension
  String get extension {
    final name = this.name;
    final dot = name.lastIndexOf('.');
    return dot >= 0 ? name.substring(dot + 1).toLowerCase() : '';
  }

  /// Whether the file extension indicates a compressed/archive file
  bool get isArchive {
    const archiveExtensions = {
      'zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz', 'zst', 'zstd',
      'jar', 'apk', 'tgz', 'tbz', 'txz', 'epub',
    };
    return archiveExtensions.contains(extension);
  }
}
