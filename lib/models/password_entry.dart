/// A saved password entry in the password database
class PasswordEntry {
  final int? id;
  final String filenamePattern; // LIKE pattern or glob
  final String password;
  final String source; // 'manual', 'community', 'dictionary', 'filename', 'bruteforce'
  final int confidence; // 0-100
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int successCount;
  final int failCount;

  const PasswordEntry({
    this.id,
    required this.filenamePattern,
    required this.password,
    required this.source,
    this.confidence = 50,
    required this.createdAt,
    this.lastUsedAt,
    this.successCount = 0,
    this.failCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'filename_pattern': filenamePattern,
      'password': password,
      'source': source,
      'confidence': confidence,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_used_at': lastUsedAt?.millisecondsSinceEpoch,
      'success_count': successCount,
      'fail_count': failCount,
    };
  }

  factory PasswordEntry.fromMap(Map<String, dynamic> map) {
    return PasswordEntry(
      id: map['id'] as int?,
      filenamePattern: map['filename_pattern'] as String,
      password: map['password'] as String,
      source: (map['source'] as String?) ?? 'manual',
      confidence: (map['confidence'] as int?) ?? 50,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      lastUsedAt: map['last_used_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_used_at'] as int)
          : null,
      successCount: (map['success_count'] as int?) ?? 0,
      failCount: (map['fail_count'] as int?) ?? 0,
    );
  }

  PasswordEntry copyWith({
    int? id,
    String? filenamePattern,
    String? password,
    String? source,
    int? confidence,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? successCount,
    int? failCount,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      filenamePattern: filenamePattern ?? this.filenamePattern,
      password: password ?? this.password,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      successCount: successCount ?? this.successCount,
      failCount: failCount ?? this.failCount,
    );
  }
}

/// Source of a found password
enum PasswordSource {
  cache,
  filenameExtracted,
  database,
  dictionary,
  bruteForce,
  userProvided,
  community;

  String get displayName {
    switch (this) {
      case PasswordSource.cache:
        return '缓存';
      case PasswordSource.filenameExtracted:
        return '文件名提取';
      case PasswordSource.database:
        return '密码库';
      case PasswordSource.dictionary:
        return '辞典';
      case PasswordSource.bruteForce:
        return '暴力破解';
      case PasswordSource.userProvided:
        return '手动输入';
      case PasswordSource.community:
        return '社区密码库';
    }
  }
}
