import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/washer_config.dart';
import '../services/washer_config_service.dart';

class WasherSettingsPage extends StatefulWidget {
  const WasherSettingsPage({
    super.key,
    required this.initialConfig,
    required this.configService,
    this.onConfigChanged,
    this.closeOnSave = true,
  });

  final WasherConfig initialConfig;
  final WasherConfigService configService;
  final ValueChanged<WasherConfig>? onConfigChanged;
  final bool closeOnSave;

  @override
  State<WasherSettingsPage> createState() => _WasherSettingsPageState();
}

class _WasherSettingsPageState extends State<WasherSettingsPage> {
  late WasherConfig _config;
  late TextEditingController _baseUrlController;
  late TextEditingController _endpointController;
  late TextEditingController _qrTemplateController;
  final List<_HeaderField> _headers = [];
  bool _isSaving = false;
  late int _reminderLeadMinutes;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _baseUrlController = TextEditingController(text: _config.baseUrl);
    _endpointController = TextEditingController(text: _config.endpoint);
    _qrTemplateController = TextEditingController(text: _config.qrTemplate);
    _reminderLeadMinutes = _config.reminderLeadMinutes;
    _headers.addAll(
      _config.headers.entries.map(
        (entry) => _HeaderField(
          keyController: TextEditingController(text: entry.key),
          valueController: TextEditingController(text: entry.value),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _endpointController.dispose();
    _qrTemplateController.dispose();
    for (final field in _headers) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('接口设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: '导入配置',
            onPressed: _isSaving ? null : _handleImport,
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: '导出配置',
            onPressed: _isSaving ? null : _handleExport,
          ),
          IconButton(
            icon: const Icon(Icons.restore_outlined),
            tooltip: '恢复默认',
            onPressed: _isSaving ? null : _restoreDefault,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle(theme, '基础设置'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _baseUrlController,
                label: 'Base URL',
                hint: '例如 https://api.ulife.group',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _endpointController,
                label: '接口路径',
                hint: '例如 /washer/device/scanCode',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _qrTemplateController,
                label: '二维码模板',
                hint: '使用 {code} 作为替换符，例如 http://base.xmulife.com?t=w&name={code}',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '提醒提前分钟数',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: TextFormField(
                      initialValue: '$_reminderLeadMinutes',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixText: '分钟',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsed = int.tryParse(value) ?? 0;
                        setState(() {
                          _reminderLeadMinutes = parsed.clamp(0, 120);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, '请求头'),
              const SizedBox(height: 12),
              ..._buildHeaderFields(theme),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _addHeader,
                icon: const Icon(Icons.add),
                label: const Text('新增请求头'),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('保存并返回'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  List<Widget> _buildHeaderFields(ThemeData theme) {
    if (_headers.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('暂无额外请求头'),
        ),
      ];
    }
    return _headers.map((field) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: field.keyController,
                decoration: const InputDecoration(
                  labelText: 'Header Key',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: field.valueController,
                decoration: const InputDecoration(
                  labelText: 'Header Value',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '移除',
              onPressed: () {
                setState(() {
                  field.dispose();
                  _headers.remove(field);
                });
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _addHeader() async {
    setState(() {
      _headers.add(
        _HeaderField(
          keyController: TextEditingController(),
          valueController: TextEditingController(),
        ),
      );
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });
    try {
      final headers = <String, String>{};
      for (final field in _headers) {
        final key = field.keyController.text.trim();
        final value = field.valueController.text.trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          headers[key] = value;
        }
      }
      final updated = _config.copyWith(
        baseUrl: _baseUrlController.text.trim(),
        endpoint: _endpointController.text.trim(),
        qrTemplate: _qrTemplateController.text.trim(),
        headers: headers,
        reminderLeadMinutes: _reminderLeadMinutes,
      );
      await widget.configService.saveConfig(updated);
      widget.onConfigChanged?.call(updated);
      if (!mounted) {
        return;
      }
      if (widget.closeOnSave) {
        Navigator.of(context).pop(updated);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('配置已保存'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleExport() async {
    try {
      final file = await widget.configService.exportConfig(_config);
      await Share.shareXFiles([XFile(file.path)], text: '我的洗衣机配置');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败: $error'),
        ),
      );
    }
  }

  Future<void> _handleImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.single.path == null) {
        return;
      }
      final file = File(result.files.single.path!);
      final config = await widget.configService.importConfigFromFile(file);
      if (!mounted) {
        return;
      }
      setState(() {
        _config = config;
        _baseUrlController.text = config.baseUrl;
        _endpointController.text = config.endpoint;
        _qrTemplateController.text = config.qrTemplate;
        for (final field in _headers) {
          field.dispose();
        }
        _headers
          ..clear()
          ..addAll(
            config.headers.entries.map(
              (entry) => _HeaderField(
                keyController: TextEditingController(text: entry.key),
                valueController: TextEditingController(text: entry.value),
              ),
            ),
          );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导入失败: $error'),
        ),
      );
    }
  }

  Future<void> _restoreDefault() async {
    setState(() {
      _config = WasherConfig.defaultConfig();
      _baseUrlController.text = _config.baseUrl;
      _endpointController.text = _config.endpoint;
      _qrTemplateController.text = _config.qrTemplate;
      for (final field in _headers) {
        field.dispose();
      }
      _headers
        ..clear()
        ..addAll(
          _config.headers.entries.map(
            (entry) => _HeaderField(
              keyController: TextEditingController(text: entry.key),
              valueController: TextEditingController(text: entry.value),
            ),
          ),
        );
    });
  }
}

class _HeaderField {
  _HeaderField({
    required this.keyController,
    required this.valueController,
  });

  final TextEditingController keyController;
  final TextEditingController valueController;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
