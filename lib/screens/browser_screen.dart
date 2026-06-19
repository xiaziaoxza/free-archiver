import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../models/archive_format.dart';
import '../utils/file_utils.dart';
import 'archive_screen.dart';
import 'create_screen.dart';
import 'settings_screen.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrowserProvider>().navigateTo('/storage/emulated/0');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_showSearch) {
      return AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜索文件...',
            border: InputBorder.none,
          ),
          onChanged: (q) => context.read<BrowserProvider>().search(q),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() => _showSearch = false);
              _searchController.clear();
              context.read<BrowserProvider>().search('');
            },
          ),
        ],
      );
    }

    final provider = context.watch<BrowserProvider>();
    return AppBar(
      title: Text(
        FileUtils.getName(provider.currentPath),
        style: const TextStyle(fontSize: 16),
      ),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _showSearch = true),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showOptionsMenu(context),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.archive, size: 48),
                SizedBox(height: 8),
                Text('自由解压', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('无广告文件解压工具'),
              ],
            ),
          ),
          _buildDrawerItem(Icons.folder, '内部存储', '/storage/emulated/0'),
          _buildDrawerItem(Icons.download, '下载', '/storage/emulated/0/Download'),
          _buildDrawerItem(Icons.image, '图片', '/storage/emulated/0/Pictures'),
          _buildDrawerItem(Icons.music_note, '音乐', '/storage/emulated/0/Music'),
          _buildDrawerItem(Icons.videocam, '视频', '/storage/emulated/0/Movies'),
          _buildDrawerItem(Icons.description, '文档', '/storage/emulated/0/Documents'),
          const Divider(),
          _buildDrawerItem(Icons.terminal, 'Termux', '/data/data/com.termux/files/home'),
          _buildDrawerItem(Icons.sd_card, '根目录', '/'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String path) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        context.read<BrowserProvider>().navigateTo(path);
      },
    );
  }

  Widget _buildBody() {
    final provider = context.watch<BrowserProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(provider.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.navigateTo(provider.currentPath),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final items = provider.getFilteredItems();
    if (items.isEmpty && provider.searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('未找到匹配 "${provider.searchQuery}" 的文件'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Breadcrumb navigation
        _buildBreadcrumbs(provider.currentPath),
        // File list
        Expanded(child: _buildFileList(provider, items)),
        // Bottom status bar
        _buildStatusBar(provider),
      ],
    );
  }

  Widget _buildBreadcrumbs(String currentPath) {
    final parts = currentPath.split('/').where((p) => p.isNotEmpty).toList();
    final crumbs = <Widget>[];

    crumbs.add(
      GestureDetector(
        onTap: () => context.read<BrowserProvider>().navigateTo('/'),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.home, size: 18),
        ),
      ),
    );

    for (int i = 0; i < parts.length; i++) {
      crumbs.add(const Icon(Icons.chevron_right, size: 16, color: Colors.grey));
      final path = '/' + parts.sublist(0, i + 1).join('/');
      crumbs.add(
        GestureDetector(
          onTap: () => context.read<BrowserProvider>().navigateTo(path),
          child: Text(
            parts[i],
            style: TextStyle(
              fontSize: 12,
              color: i == parts.length - 1
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              fontWeight: i == parts.length - 1 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      height: 32,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: crumbs),
      ),
    );
  }

  Widget _buildFileList(BrowserProvider provider, List<FileItem> items) {
    return ListView.builder(
      itemCount: items.length + 1, // +1 for parent dir
      itemBuilder: (context, index) {
        if (index == 0) {
          // Parent directory entry
          return ListTile(
            leading: const Icon(Icons.arrow_upward, color: Colors.blue),
            title: const Text('..'),
            onTap: () => provider.goUp(),
          );
        }

        final item = items[index - 1];
        final isSelected = provider.selectedPaths.contains(item.path);
        final icon = item.isDirectory
            ? Icons.folder
            : _getFileIcon(item.name);

        return ListTile(
          leading: Icon(
            icon,
            color: item.isDirectory ? Colors.amber : _getFileIconColor(item.name),
            size: 28,
          ),
          title: Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${item.isDirectory ? '目录' : FileUtils.formatSize(item.size)}  '
            '${_formatDate(item.modified)}',
            style: const TextStyle(fontSize: 12),
          ),
          selected: isSelected,
          selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
          trailing: item.isDirectory
              ? const Icon(Icons.chevron_right, size: 20)
              : (ArchiveFormat.fromPath(item.name) != null
                  ? const Icon(Icons.archive, size: 20, color: Colors.orange)
                  : null),
          onTap: () {
            if (provider.selectedPaths.isNotEmpty) {
              provider.toggleSelection(item.path);
            } else if (item.isDirectory) {
              provider.navigateTo(item.path);
            } else {
              _onFileTap(item);
            }
          },
          onLongPress: () => provider.toggleSelection(item.path),
        );
      },
    );
  }

  Widget _buildStatusBar(BrowserProvider provider) {
    final selectedCount = provider.selectedPaths.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${provider.items.length} 个项目',
            style: const TextStyle(fontSize: 12),
          ),
          if (selectedCount > 0) ...[
            const SizedBox(width: 16),
            Text(
              '已选 $selectedCount 项',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (selectedCount > 0) ...[
              TextButton.icon(
                icon: const Icon(Icons.archive, size: 18),
                label: const Text('压缩'),
                onPressed: () => _compressSelected(provider),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'compress',
          tooltip: '创建归档',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateArchiveScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  void _onFileTap(FileItem item) {
    final format = ArchiveFormat.fromPath(item.name);
    if (format != null) {
      // Open archive
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArchiveScreen(archivePath: item.path),
        ),
      );
    } else {
      // TODO: Open file with system handler
    }
  }

  void _compressSelected(BrowserProvider provider) {
    final paths = provider.selectedPaths.toList();
    if (paths.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateArchiveScreen(initialPaths: paths),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final provider = context.read<BrowserProvider>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.select_all),
            title: const Text('全选'),
            onTap: () { provider.selectAll(); Navigator.pop(ctx); },
          ),
          ListTile(
            leading: const Icon(Icons.deselect),
            title: const Text('取消选择'),
            onTap: () { provider.clearSelection(); Navigator.pop(ctx); },
          ),
          ListTile(
            leading: const Icon(Icons.create_new_folder),
            title: const Text('新建目录'),
            onTap: () { Navigator.pop(ctx); _showCreateDirDialog(); },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('刷新'),
            onTap: () { provider.navigateTo(provider.currentPath); Navigator.pop(ctx); },
          ),
        ],
      ),
    );
  }

  void _showCreateDirDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建目录'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '目录名'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final dir = Directory(
                  '${context.read<BrowserProvider>().currentPath}/${controller.text}',
                );
                dir.createSync();
                context.read<BrowserProvider>().navigateTo(
                  context.read<BrowserProvider>().currentPath,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ArchiveFormat.fromPath(filename)) {
      case ArchiveFormat.zip:
      case ArchiveFormat.rar:
      case ArchiveFormat.sevenZ:
        return Icons.archive;
      case ArchiveFormat.tar:
      case ArchiveFormat.gzip:
      case ArchiveFormat.bzip2:
      case ArchiveFormat.xz:
      case ArchiveFormat.zstd:
        return Icons.compress;
      default:
        break;
    }
    const images = {'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'};
    const videos = {'mp4', 'mkv', 'avi', 'mov', 'webm'};
    const audio = {'mp3', 'wav', 'flac', 'aac', 'ogg'};
    if (images.contains(ext)) return Icons.image;
    if (videos.contains(ext)) return Icons.movie;
    if (audio.contains(ext)) return Icons.audiotrack;
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (ext == 'apk') return Icons.android;
    return Icons.insert_drive_file;
  }

  Color _getFileIconColor(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    if (ArchiveFormat.fromPath(filename) != null) return Colors.orange;
    const images = {'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'};
    if (images.contains(ext)) return Colors.green;
    if (ext == 'pdf') return Colors.red;
    if (ext == 'apk') return Colors.teal;
    return Colors.grey;
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
