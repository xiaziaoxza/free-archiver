import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/browser_provider.dart';
import 'providers/archive_provider.dart';
import 'providers/password_provider.dart';
import 'providers/settings_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsProvider = SettingsProvider();
  await settingsProvider.initialize();

  final passwordProvider = PasswordProvider();
  await passwordProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsProvider),
        ChangeNotifierProvider(create: (_) => BrowserProvider()),
        ChangeNotifierProvider(create: (_) => ArchiveProvider()),
        ChangeNotifierProvider(create: (_) => passwordProvider),
      ],
      child: const FreeArchiverApp(),
    ),
  );
}
