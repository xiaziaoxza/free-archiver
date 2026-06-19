import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/archive_provider.dart';
import '../providers/password_provider.dart';
import '../utils/file_utils.dart';
import 'password_screen.dart';

class ExtractScreen extends StatefulWidget {
  final String archivePath;

  const ExtractScreen({super.key, required this.archivePath});

  @override
  State<ExtractScreen> createState() => _ExtractScreenState();
}

class _ExtractScreenState extends State<ExtractScreen> {
  final _destController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _autoFindPassword = true;
  bool _preservePaths = true;
  String _overwriteMode = 'ask'; // ask, always, skip, rename

  @override
  void initState() {
    super.initState();
    // Default output directory: same directory as archive
    final parent = FileUtils.getParent(widget.archivePath);
    final stem = FileUtils.getName(widget.archivePath);
    final name = stem.contains('.') ? stem.substring(0, stem.lastIndexOf('.')) : stem;
    _destController.text = '$parent/$name';
  }

  @override
  void dispose() {
    _destController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('解压选项')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Archive info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.archive, color: Colors.orange, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            FileUtils.getName(widget.archivePath),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(widget.archivePath, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Output directory
            Text('解压到', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _destController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () => _selectDirectory(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Password
            Text('密码 (如需)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
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
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.orange),
                  tooltip: '自动查找密码',
                  onPressed: () async {
                    final result = await Navigator.push<PasswordFindResult>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PasswordScreen(archivePath: widget.archivePath),
                      ),
                    );
                    if (result != null) {
                      _passwordController.text = result.password;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              title: const Text('自动查找密码'),
              subtitle: const Text('如果未提供密码，自动尝试查找'),
              value: _autoFindPassword,
              onChanged: (v) => setState(() => _autoFindPassword = v),
              dense: true,
            ),

            const SizedBox(height: 16),

            // Options
            Text('选项', style: Theme.of(context).textTheme.titleSmall),
            SwitchListTile(
              title: const Text('保持目录结构'),
              value: _preservePaths,
              onChanged: (v) => setState(() => _preservePaths = v),
              dense: true,
            ),

            const SizedBox(height: 8),
            Text('覆盖模式', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ask', label: Text('询问')),
                ButtonSegment(value: 'always', label: Text('覆盖')),
                ButtonSegment(value: 'skip', label: Text('跳过')),
                ButtonSegment(value: 'rename', label: Text('重命名')),
              ],
              selected: {_overwriteMode},
              onSelectionChanged: (v) => setState(() => _overwriteMode = v.first),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.unarchive),
            label: const Text('开始解压'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => _startExtraction(),
          ),
        ),
      ),
    );
  }

  void _selectDirectory() async {
    // TODO: Implement directory picker
  }

  void _startExtraction() {
    final provider = context.read<ArchiveProvider>();
    provider.extractArchive(
      widget.archivePath,
      destDir: _destController.text,
      password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      autoFindPassword: _autoFindPassword,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('解压完成!')),
                );
              });
            }
            if (provider.state == ArchiveOperationState.error) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('解压失败: ${provider.error}')),
                );
              });
            }
            return AlertDialog(
              title: Text(provider.progressText),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: provider.progress),
                  const SizedBox(height: 16),
                  Text('${(provider.progress * 100).toStringAsFixed(0)}%'),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
