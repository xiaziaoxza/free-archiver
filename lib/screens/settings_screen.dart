import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            children: [
              // Theme
              _sectionHeader(context, '外观'),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('主题'),
                subtitle: Text(_themeLabel(settings.themeMode)),
                onTap: () => _showThemeDialog(context, settings),
              ),

              const Divider(),

              // Compression defaults
              _sectionHeader(context, '压缩默认值'),
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('默认压缩级别'),
                subtitle: Text('级别 ${settings.defaultCompressionLevel}/9'),
                trailing: Slider(
                  value: settings.defaultCompressionLevel.toDouble(),
                  min: 0,
                  max: 9,
                  divisions: 9,
                  onChanged: (v) => settings.setDefaultCompressionLevel(v.toInt()),
                ),
              ),

              const Divider(),

              // Password
              _sectionHeader(context, '密码'),
              SwitchListTile(
                secondary: const Icon(Icons.password),
                title: const Text('自动查找密码'),
                subtitle: const Text('打开加密归档时自动尝试查找密码'),
                value: settings.autoFindPassword,
                onChanged: (v) => settings.setAutoFindPassword(v),
              ),

              const Divider(),

              // File browser
              _sectionHeader(context, '文件浏览'),
              SwitchListTile(
                secondary: const Icon(Icons.visibility_off),
                title: const Text('显示隐藏文件'),
                value: settings.showHiddenFiles,
                onChanged: (v) => settings.setShowHiddenFiles(v),
              ),
              ListTile(
                leading: const Icon(Icons.sort),
                title: const Text('排序方式'),
                subtitle: Text(_sortLabel(settings.sortBy)),
                onTap: () => _showSortDialog(context, settings),
              ),

              const Divider(),

              // About
              _sectionHeader(context, '关于'),
              const ListTile(
                leading: Icon(Icons.info),
                title: Text('自由解压'),
                subtitle: Text('版本 1.0.0'),
              ),
              const ListTile(
                leading: Icon(Icons.description),
                title: Text('无广告 · 完全离线 · 开源'),
                subtitle: Text('支持 ZIP/RAR/7z/TAR/GZ/BZ2/XZ/ZSTD'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
    }
  }

  String _sortLabel(String sort) {
    switch (sort) {
      case 'name':
        return '名称';
      case 'size':
        return '大小';
      case 'date':
        return '日期';
      case 'type':
        return '类型';
      default:
        return sort;
    }
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择主题'),
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('跟随系统'),
            value: ThemeMode.system,
            groupValue: settings.themeMode,
            onChanged: (v) {
              settings.setThemeMode(v!);
              Navigator.pop(ctx);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('浅色'),
            value: ThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (v) {
              settings.setThemeMode(v!);
              Navigator.pop(ctx);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('深色'),
            value: ThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (v) {
              settings.setThemeMode(v!);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showSortDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('排序方式'),
        children: [
          RadioListTile<String>(
            title: const Text('名称'),
            value: 'name',
            groupValue: settings.sortBy,
            onChanged: (v) {
              settings.setSortBy(v!);
              Navigator.pop(ctx);
            },
          ),
          RadioListTile<String>(
            title: const Text('大小'),
            value: 'size',
            groupValue: settings.sortBy,
            onChanged: (v) {
              settings.setSortBy(v!);
              Navigator.pop(ctx);
            },
          ),
          RadioListTile<String>(
            title: const Text('日期'),
            value: 'date',
            groupValue: settings.sortBy,
            onChanged: (v) {
              settings.setSortBy(v!);
              Navigator.pop(ctx);
            },
          ),
          RadioListTile<String>(
            title: const Text('类型'),
            value: 'type',
            groupValue: settings.sortBy,
            onChanged: (v) {
              settings.setSortBy(v!);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
