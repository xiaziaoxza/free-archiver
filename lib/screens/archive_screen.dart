import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/archive_provider.dart';
import '../utils/file_utils.dart';
import 'extract_screen.dart';

class ArchiveScreen extends StatefulWidget {
  final String archivePath;

  const ArchiveScreen({super.key, required this.archivePath});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArchiveProvider>().listArchive(widget.archivePath);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FileUtils.getName(widget.archivePath)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '归档信息',
            onPressed: () => _showArchiveInfo(),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    final provider = context.watch<ArchiveProvider>();

    switch (provider.state) {
      case ArchiveOperationState.listing:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(provider.progressText),
            ],
          ),
        );
      case ArchiveOperationState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(provider.error ?? '未知错误'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.listArchive(widget.archivePath),
                child: const Text('重试'),
              ),
            ],
          ),
        );
      case ArchiveOperationState.done:
        final archive = provider.currentArchive;
        if (archive == null) {
          return const Center(child: Text('无法读取归档'));
        }

        return Column(
          children: [
            // Archive summary card
            _buildSummaryCard(archive),
            // Entry list
            Expanded(child: _buildEntryList(archive)),
          ],
        );
      default:
        return const Center(child: Text('正在加载...'));
    }
  }

  Widget _buildSummaryCard(dynamic archive) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.archive, color: Colors.orange, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        archive.format.displayName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(FileUtils.getName(archive.path)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow('条目数', '${archive.fileCount} 文件, ${archive.dirCount} 目录'),
            _infoRow('原始大小', FileUtils.formatSize(archive.totalUncompressed)),
            _infoRow('压缩后', FileUtils.formatSize(archive.totalCompressed)),
            _infoRow('压缩率', '${(archive.ratio * 100).toStringAsFixed(1)}%'),
            if (archive.isEncrypted) _infoRow('加密', '是 🔒'),
            if (archive.isSolid) _infoRow('固实', '是'),
            if (archive.isSplit) _infoRow('分卷', '${archive.splitParts.length} 个部分'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildEntryList(dynamic archive) {
    if (archive.entries.isEmpty) {
      return const Center(child: Text('归档为空'));
    }

    return ListView.builder(
      itemCount: archive.entries.length,
      itemBuilder: (context, index) {
        final entry = archive.entries[index];
        return ListTile(
          leading: Icon(
            entry.isDirectory ? Icons.folder : Icons.insert_drive_file,
            color: entry.isDirectory ? Colors.amber : Colors.grey,
            size: 24,
          ),
          title: Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${entry.isDirectory ? '目录' : FileUtils.formatSize(entry.size)}'
            '${entry.isEncrypted ? ' 🔒' : ''}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(
            '${(entry.ratio * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final provider = context.watch<ArchiveProvider>();
    if (provider.state != ArchiveOperationState.done || provider.currentArchive == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.unarchive),
                label: const Text('解压全部'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExtractScreen(archivePath: widget.archivePath),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.verified),
              label: const Text('测试'),
              onPressed: () {
                // TODO: Test archive integrity
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showArchiveInfo() {
    final provider = context.read<ArchiveProvider>();
    final archive = provider.currentArchive;
    if (archive == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('归档信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('格式', archive.format.displayName),
            _infoRow('路径', archive.path),
            _infoRow('总条目', archive.entries.length.toString()),
            _infoRow('加密', archive.isEncrypted ? '是' : '否'),
            _infoRow('固实', archive.isSolid ? '是' : '否'),
            _infoRow('分卷', archive.isSplit ? '是 (${archive.splitParts.length}卷)' : '否'),
            if (archive.comment != null) ...[
              const SizedBox(height: 8),
              const Text('注释:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(archive.comment!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
