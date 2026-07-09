import 'dart:convert';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';
import '../shared/app_paths.dart';
import '../config/registry.dart';
import '../shared/project.dart';
import 'dialogs.dart';

class ImportDialog {
  /// 显示导入 segatools 的预置弹窗
  static void show({
    required BuildContext context,
    required List<Project> currentProjects,
    required Function(Project) onSuccess,
  }) {
    final pathController = TextEditingController();
    String selectedType = gameTypes.first.id;

    // 从 settings.json 读取 segatoolsVersion，有值即允许导入
    final settingsFile = File(p.join(AppPaths.dataDir, 'settings.json'));
    String? segatoolsVersion;
    try {
      if (settingsFile.existsSync()) {
        final data = jsonDecode(settingsFile.readAsStringSync()) as Map<String, dynamic>;
        segatoolsVersion = data['segatoolsVersion'] as String?;
      }
    } catch (_) {}
    final bool segatoolsValid = segatoolsVersion != null && segatoolsVersion.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final bool canImport = segatoolsValid && pathController.text.isNotEmpty;

          return ContentDialog(
            title: const Text('Import segatools'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InfoLabel(
                  label: 'VARIETY',
                  child: ComboBox<String>(
                    isExpanded: true,
                    value: selectedType,
                    items: gameTypes.map((gt) =>
                        ComboBoxItem(value: gt.id, child: Text(gt.label))).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() {
                        selectedType = v;
                      });
                    },
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
                          placeholder: '选择游戏目录',
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Button(
                        child: const Icon(FluentIcons.folder_search),
                        onPressed: () async {
                          final dir = await FilePicker.getDirectoryPath(
                            lockParentWindow: true,
                          );
                          if (dir != null) {
                            setDialogState(() {
                              pathController.text = dir;
                            });
                          }
                        },
                      ),
                    ],
                    ),
                    ),
                if (!segatoolsValid) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(FluentIcons.warning, size: 14, color: Colors.orange.normal),
                      const SizedBox(width: 6),
                      Text('segatools.zip 已损坏',
                          style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              Button(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              Button(
                child: const Text('Skip'),
                onPressed: () {
                  Navigator.pop(context);
                  ProjectDialogs.showCreateDialog(
                    context: context,
                    currentProjects: currentProjects,
                    onSuccess: onSuccess,
                  );
                },
              ),
              FilledButton(
                onPressed: canImport
                    ? () async {
                        try {
                          await _extractVariety(selectedType, pathController.text);
                          if (!context.mounted) return;
                          displayInfoBar(context, builder: (c, close) => const InfoBar(
                            title: Text('Import successful'),
                            content: Text('segatools has been installed.'),
                            severity: InfoBarSeverity.success,
                          ));
                        } catch (e) {
                          if (!context.mounted) return;
                          displayInfoBar(context, builder: (c, close) => InfoBar(
                            title: const Text('Import failed'),
                            content: Text('$e'),
                            severity: InfoBarSeverity.error,
                          ));
                          return;
                        }
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ProjectDialogs.showCreateDialog(
                          context: context,
                          currentProjects: currentProjects,
                          onSuccess: onSuccess,
                          initialVariety: selectedType,
                          initialPath: pathController.text,
                        );
                      }
                    : null,
                child: const Text('Import'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 从 segatools.zip 中解压指定 variety 目录到 targetPath（不嵌套）
  static Future<void> _extractVariety(String variety, String targetPath) async {
    final zipPath = p.join(AppPaths.dataDir, 'segatools.zip');
    debugPrint('[Import] segatools.zip: $zipPath');
    debugPrint('[Import] target: $targetPath, variety: $variety');

    final outerBytes = await File(zipPath).readAsBytes();
    final outerArchive = ZipDecoder().decodeBytes(outerBytes);

    // 在外层 zip 中找到 $variety.zip 条目
    final innerEntry = outerArchive.firstWhere(
      (e) => e.name == '$variety.zip' && e.isFile,
    );

    // 内层 zip 解压到目标路径
    final innerBytes = innerEntry.content as List<int>;
    final innerArchive = ZipDecoder().decodeBytes(innerBytes);

    int count = 0;
    for (final entry in innerArchive) {
      if (!entry.isFile) continue;
      final outFile = File(p.join(targetPath, entry.name));
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(entry.content as List<int>);
      debugPrint('[Import]   extracted: ${entry.name}');
      count++;
    }
    debugPrint('[Import] done — $count files extracted');
  }
}
