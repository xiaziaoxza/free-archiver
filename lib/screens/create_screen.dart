import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/archive_provider.dart';
import '../models/archive_format.dart';
import '../utils/file_utils.dart';
import '../utils/constants.dart';

class CreateArchiveScreen extends StatefulWidget {
  final List<String>? initialPaths;

  const CreateArchiveScreen({super.key, this.initialPaths});

  @override
  State<CreateArchiveScreen> createState() => _CreateArchiveScreenState();
}

class _CreateArchiveScreenState extends State<CreateArchiveScreen> {
  final _nameController = TextEditingController(text: 'archive.zip');
  final _destController = TextEditingController();
  final _passwordController = TextEditingController();
  ArchiveFormat _format = ArchiveFormat.zip;
  int _compressionLevel = 6;
  int _splitSizeIndex = 0; // 0 = no split
  bool _solid = false;
  bool _usePassword = false;

  @override
  void initState() {
    super.initState();
    // Default output: same dir as source or current dir
    if (widget.initialPaths != null && widget.initialPaths!.isNotEmpty) {
      _destController.text = FileUtils.getParent(widget.initialPaths!.first);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('创建归档')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source files
            Text('源文件', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (widget.initialPaths != null && widget.initialPaths!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: widget.initialPaths!
                        .take(10)
                        .map((p) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.insert_drive_file, size: 20),
                              title: Text(FileUtils.getName(p), maxLines: 1),
                              trailing: Text(FileUtils.formatSize(0)),
                            ))
                        .toList(),
                  ),
                ),
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加文件'),
              onPressed: () => _pickFiles(),
            ),

            const SizedBox(height: 16),

            // Archive name
            Text('归档名称', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'archive.zip',
              ),
            ),

            const SizedBox(height: 16),

            // Format
            Text('格式', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ArchiveFormat>(
              segments: const [
                ButtonSegment(value: ArchiveFormat.zip, label: Text('ZIP')),
                ButtonSegment(value: ArchiveFormat.sevenZ, label: Text('7z')),
                ButtonSegment(value: ArchiveFormat.tar, label: Text('TAR')),
                ButtonSegment(value: ArchiveFormat.gzip, label: Text('TAR.GZ')),
                ButtonSegment(value: ArchiveFormat.xz, label: Text('TAR.XZ')),
              ],
              selected: {_format},
              onSelectionChanged: (v) => setState(() => _format = v.first),
            ),

            const SizedBox(height: 16),

            // Compression level
            Text('压缩级别: $_compressionLevel/9', style: Theme.of(context).textTheme.titleSmall),
            Slider(
              value: _compressionLevel.toDouble(),
              min: 0,
              max: 9,
              divisions: 9,
              label: _compressionLevel.toString(),
              onChanged: (v) => setState(() => _compressionLevel = v.toInt()),
            ),

            const SizedBox(height: 16),

            // Password
            SwitchListTile(
              title: const Text('设置密码'),
              subtitle: const Text('使用密码保护归档'),
              value: _usePassword,
              onChanged: (v) => setState(() {
                _usePassword = v;
                if (!v) _passwordController.clear();
              }),
              dense: true,
            ),
            if (_usePassword)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '输入密码',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Split volumes
            Text('分卷大小', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              value: _splitSizeIndex,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: 0, child: Text('不分卷')),
                for (int i = 0; i < AppConstants.splitSizes.length; i++)
                  DropdownMenuItem(
                    value: i + 1,
                    child: Text(FileUtils.formatSize(AppConstants.splitSizes[i])),
                  ),
              ],
              onChanged: (v) => setState(() => _splitSizeIndex = v ?? 0),
            ),

            // Solid (7z only)
            if (_format == ArchiveFormat.sevenZ) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('固实归档'),
                subtitle: const Text('更好的压缩率，但修改需要重写整个归档'),
                value: _solid,
                onChanged: (v) => setState(() => _solid = v),
                dense: true,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.archive),
            label: const Text('创建归档'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => _startCreation(),
          ),
        ),
      ),
    );
  }

  void _pickFiles() {
    // TODO: Implement file picker
  }

  void _startCreation() {
    if (widget.initialPaths == null || widget.initialPaths!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择文件')),
      );
      return;
    }

    final outputPath = '${_destController.text}/${_nameController.text}';

    final provider = context.read<ArchiveProvider>();
    provider.createArchive(
      outputPath: outputPath,
      sourcePaths: widget.initialPaths!,
      format: _format,
      compressionLevel: _compressionLevel,
      password: _usePassword && _passwordController.text.isNotEmpty
          ? _passwordController.text
          : null,
    );

    // Show progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Consumer<ArchiveProvider>(
          builder: (context, provider, _) {
            if (provider.state == ArchiveOperationState.done) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(ctx);
                Navigator.pop(context); // Back to browser
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('归档创建成功!')),
                );
              });
            }
            if (provider.state == ArchiveOperationState.error) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('创建失败: ${provider.error}')),
                );
              });
            }
            return AlertDialog(
              title: Text(provider.progressText),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: provider.progress),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
