import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/password_provider.dart';
import '../models/password_entry.dart';
import '../utils/file_utils.dart';

class PasswordScreen extends StatefulWidget {
  final String archivePath;

  const PasswordScreen({super.key, required this.archivePath});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _manualController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Auto-start password finding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoFind();
    });
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('密码查找')),
      body: Consumer<PasswordProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Archive info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            FileUtils.getName(widget.archivePath),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Auto-find section
                _buildAutoFindSection(provider),

                const SizedBox(height: 20),

                // Manual entry
                Text('手动输入', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: '输入解压密码',
                          prefixIcon: const Icon(Icons.vpn_key),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.check_circle, size: 32, color: Colors.green),
                      tooltip: '使用此密码',
                      onPressed: _manualController.text.isNotEmpty
                          ? () {
                              provider.cachePassword(
                                widget.archivePath,
                                _manualController.text,
                              );
                              Navigator.pop(
                                context,
                                PasswordFindResult(
                                  password: _manualController.text,
                                  source: PasswordSource.userProvided,
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Result
                if (provider.lastResult != null) ...[
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 48),
                          const SizedBox(height: 8),
                          const Text('找到密码!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Text(
                              provider.lastResult!.password,
                              style: const TextStyle(fontSize: 20, fontFamily: 'monospace'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('来源: ${provider.lastResult!.source.displayName}'),
                          Text('已尝试 ${provider.lastResult!.candidatesTested} 个候选'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('使用此密码'),
                            onPressed: () {
                              Navigator.pop(context, provider.lastResult);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (provider.findState == PasswordFindState.notFound) ...[
                  Card(
                    color: Colors.orange.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.help_outline, color: Colors.orange, size: 48),
                          SizedBox(height: 8),
                          Text('未找到密码', style: TextStyle(fontSize: 16)),
                          Text('请手动输入密码'),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAutoFindSection(PasswordProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue),
                const SizedBox(width: 8),
                Text('自动查找', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),

            switch (provider.findState) {
              PasswordFindState.idle => const Text('准备查找密码...'),
              PasswordFindState.searching => Column(
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(provider.findProgress),
                  ],
                ),
              PasswordFindState.found => Column(
                  children: [
                    const Text('✅ 密码已找到!', style: TextStyle(color: Colors.green)),
                    Text(provider.findProgress),
                  ],
                ),
              PasswordFindState.notFound => Column(
                  children: [
                    const Text('❌ 未找到', style: TextStyle(color: Colors.orange)),
                    Text(provider.findProgress),
                  ],
                ),
              PasswordFindState.error => Column(
                  children: [
                    Text('❌ 错误: ${provider.error}', style: const TextStyle(color: Colors.red)),
                  ],
                ),
            },

            const SizedBox(height: 12),

            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(
                provider.findState == PasswordFindState.searching ? '查找中...' : '重新查找',
              ),
              onPressed: provider.findState == PasswordFindState.searching
                  ? null
                  : () => _startAutoFind(),
            ),
          ],
        ),
      ),
    );
  }

  void _startAutoFind() {
    context.read<PasswordProvider>().autoFindPassword(widget.archivePath);
  }
}
