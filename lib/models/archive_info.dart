import 'archive_entry.dart';
import 'archive_format.dart';

/// Information about an archive file
class ArchiveInfo {
  /// Path to the archive file on disk
  final String path;

  /// Detected archive format
  final ArchiveFormat format;

  /// List of all entries in the archive
  final List<ArchiveEntry> entries;

  /// Whether the archive itself is password-protected
  final bool isEncrypted;

  /// Whether this is a solid archive (7z feature)
  final bool isSolid;

  /// Whether this is a split/multi-volume archive
  final bool isSplit;

  /// All parts of a split archive (empty list if single volume)
  final List<String> splitParts;

  /// Archive comment (if any)
  final String? comment;

  const ArchiveInfo({
    required this.path,
    required this.format,
    required this.entries,
    this.isEncrypted = false,
    this.isSolid = false,
    this.isSplit = false,
    this.splitParts = const [],
    this.comment,
  });

  /// Total uncompressed size of all entries
  int get totalUncompressed => entries.fold(0, (sum, e) => sum + e.size);

  /// Total compressed size of all entries
  int get totalCompressed =>
      entries.fold(0, (sum, e) => sum + (e.compressedSize > 0 ? e.compressedSize : e.size));

  /// Number of files (excluding directories)
  int get fileCount => entries.where((e) => !e.isDirectory).length;

  /// Number of directories
  int get dirCount => entries.where((e) => e.isDirectory).length;

  /// Compression ratio (overall)
  double get ratio {
    final uncomp = totalUncompressed;
    return uncomp > 0 ? totalCompressed / uncomp : 1.0;
  }
}
