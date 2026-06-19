/// App-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = '自由解压';
  static const String appVersion = '1.0.0';
  static const String appDescription = '无广告文件解压工具';

  // Database
  static const String dbName = 'free_archiver.db';
  static const int dbVersion = 1;

  // Password finding
  static const int maxDictionaryAttempts = 10000;
  static const int maxBruteForceLength = 4;
  static const int passwordCacheSize = 500;

  // File browser
  static const int maxVisibleFiles = 10000;
  static const int pageSize = 100;

  // Archive operations
  static const int defaultCompressionLevel = 6;
  static const List<int> splitSizes = [
    1024 * 1024,         // 1 MB
    5 * 1024 * 1024,     // 5 MB
    10 * 1024 * 1024,    // 10 MB
    50 * 1024 * 1024,    // 50 MB
    100 * 1024 * 1024,   // 100 MB
    650 * 1024 * 1024,   // 650 MB (CD)
    700 * 1024 * 1024,   // 700 MB (CD)
    1024 * 1024 * 1024,  // 1 GB
    2 * 1024 * 1024 * 1024, // 2 GB
    4 * 1024 * 1024 * 1024, // 4 GB
  ];
}
