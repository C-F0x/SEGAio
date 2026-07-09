import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as p;
import '../config/modify_page.dart' as new_modify;

/// 转发到新的动态 ModifyPage（config/modify_page.dart）
class ModifyPage extends StatefulWidget {
  final String projectPath;
  final Map<String, dynamic> configData;
  final String searchKeyword;
  final bool isGlobalRelative;

  const ModifyPage({
    super.key,
    required this.projectPath,
    required this.configData,
    this.searchKeyword = "",
    required this.isGlobalRelative,
  });

  @override
  State<ModifyPage> createState() => ModifyPageState();
}

class ModifyPageState extends State<ModifyPage> {
  final GlobalKey<new_modify.ModifyPageState> _innerKey = GlobalKey();

  /// 从 configData 中提取游戏类型
  String get _gameType => (widget.configData['variety'] as String?) ?? 'chusan';

  void reloadData() {
    _innerKey.currentState?.reloadData();
  }

  Future<bool> triggerSaveAll() async {
    // 收集所有 section 数据
    final state = _innerKey.currentState;
    if (state == null) return false;

    final sections = state.sections;
    final Map<String, Map<String, String>> fullConfig = {};
    for (final s in sections) {
      fullConfig.addAll(s.getConfigData());
    }

    return await _saveIniFile(fullConfig);
  }

  Future<bool> _saveIniFile(Map<String, Map<String, String>> config) async {
    try {
      final file = File(p.join(widget.projectPath, 'segatools.ini'));
      final buffer = StringBuffer();
      config.forEach((section, items) {
        if (items.isNotEmpty) {
          buffer.writeln('[$section]');
          items.forEach((key, value) => buffer.writeln('$key=$value'));
          buffer.writeln();
        }
      });
      await file.writeAsString(buffer.toString().trimRight() + '\n');
      return true;
    } catch (e) {
      debugPrint("Save error: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new_modify.ModifyPage(
      key: _innerKey,
      projectPath: widget.projectPath,
      gameType: _gameType,
      configData: widget.configData,
      searchKeyword: widget.searchKeyword,
      isGlobalRelative: widget.isGlobalRelative,
    );
  }
}
