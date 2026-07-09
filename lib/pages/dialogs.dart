import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../shared/project.dart';
import '../services/segatools_updater.dart';
import '../config/registry.dart';

const String _defaultType = '_default';

/// 扫描目录，返回匹配的游戏类型 ID 列表
List<String> _detectTypes(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return [];
  try {
    final files = dir.listSync().map((e) => p.basename(e.path)).toSet();
    final results = <String>[];
    for (final gt in gameTypes) {
      if (files.contains(gt.detectFile)) {
        results.add(gt.id);
      }
    }
    return results;
  } catch (_) {
    return [];
  }
}

class ProjectDialogs {
  static void showCreateDialog({
    required BuildContext context,
    required List<Project> currentProjects,
    required Function(Project) onSuccess,
    String? initialVariety,
    String? initialPath,
  }) {
    final nameController = TextEditingController();
    final pathController = TextEditingController(text: initialPath ?? '');
    String selectedType = initialVariety ?? _defaultType;
    List<String> detectedTypes = [];
    String? warningText;

    void _recheckPath(String pathStr, StateSetter setDialogState) {
      if (pathStr.isEmpty) {
        setDialogState(() {
          detectedTypes = [];
          selectedType = _defaultType;
          warningText = null;
        });
        return;
      }
      final types = _detectTypes(pathStr);
      setDialogState(() {
        detectedTypes = types;
        if (types.length == 1) {
          selectedType = types.first;
          warningText = null;
        } else if (types.isEmpty) {
          selectedType = _defaultType;
          warningText = '无法读取游戏类型';
        } else {
          selectedType = _defaultType;
          warningText = '可能存在数据冗余';
        }
      });
    }

    /// 获取模板 ini — 从 segatools.zip 中读取
    Future<String> _loadTemplate(String type) async {
      final t = await SegatoolsUpdater.getTemplateIni(type);
      if (t != null) return t;
      // 降级到 chusan 模板
      final fallback = await SegatoolsUpdater.getTemplateIni('chusan');
      if (fallback != null) return fallback;
      throw Exception('Template not found in segatools.zip');
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // initialPath 预填时自动触发路径检测
          if (initialPath != null && detectedTypes.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _recheckPath(initialPath, setDialogState);
            });
          }
          final bool isDefault = selectedType == _defaultType;
          final bool canCreate = !isDefault &&
              nameController.text.isNotEmpty &&
              pathController.text.isNotEmpty;

          return ContentDialog(
            title: const Text('Create New Config'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InfoLabel(
                  label: 'VARIETY',
                  child: ComboBox<String>(
                    isExpanded: true,
                    value: selectedType,
                    items: [
                      const ComboBoxItem(value: _defaultType, child: Text('缺省')),
                      ...gameTypes.map((gt) => ComboBoxItem(value: gt.id, child: Text(gt.label))),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() {
                        selectedType = v;
                        if (!detectedTypes.contains(v)) {
                          warningText = null;
                        }
                      });
                    },
                  ),
                ),
                if (warningText != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(FluentIcons.warning, size: 14, color: Colors.orange.normal),
                      const SizedBox(width: 6),
                      Text(warningText!, style: TextStyle(color: Colors.orange.normal, fontSize: 12)),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                InfoLabel(
                  label: 'NAME',
                  child: TextBox(
                    controller: nameController,
                    placeholder: 'e.g init',
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ),
                const SizedBox(height: 16),
                InfoLabel(
                  label: 'PATH',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextBox(
                          controller: pathController,
                          placeholder: 'where segatools.ini exists',
                          onChanged: (v) => _recheckPath(v, setDialogState),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Button(
                        child: const Icon(FluentIcons.folder_search),
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['ini'],
                            lockParentWindow: true,
                          );

                          if (result != null && result.files.single.path != null) {
                            final filePath = result.files.single.path!;
                            final fileName = p.basename(filePath);

                            if (fileName.toLowerCase() == 'segatools.ini') {
                              final directoryPath = File(filePath).parent.path;
                              setDialogState(() { pathController.text = directoryPath; });
                              _recheckPath(directoryPath, setDialogState);
                            } else {
                              displayInfoBar(context, builder: (c, close) => const InfoBar(
                                title: Text('Invalid File'),
                                content: Text('Please select "segatools.ini" specifically.'),
                                severity: InfoBarSeverity.warning,
                              ));
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Button(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
              FilledButton(
                onPressed: canCreate ? () async {
                  try {
                    final String targetPath = p.join(pathController.text, 'segatools.ini');
                    if (!await File(targetPath).exists()) {
                      final String template = await _loadTemplate(selectedType);
                      await File(targetPath).writeAsString(template);
                    }
                    final newProject = Project(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      path: pathController.text,
                      type: selectedType,
                      createdAt: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                      sortIndex: currentProjects.length,
                      errState: 0,
                    );
                    onSuccess(newProject);
                    Navigator.pop(context);
                  } catch (_) {}
                } : null,
                child: const Text('Create & Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> confirmDelete({
    required BuildContext context,
    required Project project,
    required Function(bool deleteIni) onConfirm,
  }) async {
    bool deleteIniFile = false;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => ContentDialog(
          title: const Text('Confirm Deleting?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sure about deleting "${project.name}" '),
              const SizedBox(height: 16),
              Checkbox(
                checked: deleteIniFile,
                onChanged: (v) => setDialogState(() => deleteIniFile = v ?? false),
                content: const Text('BTW Delete binded segatools.ini'),
              ),
            ],
          ),
          actions: [
            Button(child: const Text('Cancel'), onPressed: () => Navigator.pop(context, 'cancel')),
            FilledButton(
              style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.red.normal)),
              onPressed: () => Navigator.pop(context, 'delete'),
              child: const Text('Confirm Deleting'),
            ),
          ],
        ),
      ),
    );

    if (result == 'delete') {
      onConfirm(deleteIniFile);
    }
  }
}
