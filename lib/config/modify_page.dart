import 'package:fluent_ui/fluent_ui.dart';
import 'registry.dart';
import 'setting_field.dart';
import 'section_widget.dart';
import '../shared/widgets/section_header.dart';

// Section widgets
import 'sections/vfs_section.dart';
import 'sections/aime_section.dart';
import 'sections/network_section.dart';
import 'sections/board_section.dart';
import 'sections/gfx_section.dart';
import 'sections/aimeio_section.dart';
import 'sections/led_section.dart';
import 'sections/io3_section.dart';
import 'sections/io4_section.dart';
import 'sections/io2_section.dart';
import 'sections/keyboard_section.dart';
import 'sections/xinput_section.dart';
import 'sections/dinput_section.dart';
import 'sections/slider_ir_section.dart';
import 'sections/chuniio_section.dart';
import 'sections/io_dll_custom.dart';
import 'sections/vfd_section.dart';
import 'sections/aime2_section.dart';
import 'sections/eeprom_section.dart';
import 'sections/special_sections.dart';

/// 动态 ModifyPage — 根据游戏类型渲染相应 section
class ModifyPage extends StatefulWidget {
  final String projectPath;
  final String gameType;       // "chusan", "mai2", etc.
  final Map<String, dynamic> configData;
  final String searchKeyword;
  final bool isGlobalRelative;

  const ModifyPage({
    super.key,
    required this.projectPath,
    required this.gameType,
    required this.configData,
    this.searchKeyword = '',
    required this.isGlobalRelative,
  });

  @override
  State<ModifyPage> createState() => ModifyPageState();
}

class ModifyPageState extends State<ModifyPage> {
  final Map<String, GlobalKey<State<StatefulWidget>>> _sectionKeys = {};
  GameType? get _gameType => findGameTypeById(widget.gameType);

  /// 收集所有实现了 ConfigSection 的 state
  List<ConfigSection> get sections {
    return _sectionKeys.values
        .map((k) => k.currentState)
        .whereType<ConfigSection>()
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _rebuildKeys();
  }

  @override
  void didUpdateWidget(ModifyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameType != widget.gameType || oldWidget.projectPath != widget.projectPath) {
      _rebuildKeys();
    }
  }

  void _rebuildKeys() {
    _sectionKeys.clear();
    final gt = _gameType;
    if (gt == null) return;
    for (final sd in gt.sections) {
      _sectionKeys[sd.name] = GlobalKey<State<StatefulWidget>>();
    }
  }

  /// 触发所有 section 保存
  Future<bool> triggerSaveAll() async {
    return true;
  }

  void reloadData() {
    setState(() {
      _rebuildKeys();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gt = _gameType;
    if (gt == null) {
      return Center(child: Text('Unknown game type: ${widget.gameType}'));
    }

    final List<Widget> children = [];
    for (final sd in gt.sections) {
      final widget_ = _buildSectionWidget(sd);
      if (widget_ != null) {
        children.add(widget_);
        children.add(const SizedBox(height: 16));
      }
    }
    if (children.isNotEmpty) children.removeLast();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget? _buildSectionWidget(SectionDef sd) {
    final key = _sectionKeys[sd.name];
    final Widget? content = _buildSectionContent(sd, key);
    if (content == null) return null;

    return Card(
      key: ValueKey('section_${sd.name}'),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SectionHeader(icon: sd.icon, title: sd.label, visible: widget.searchKeyword.isEmpty),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget? _buildSectionContent(SectionDef sd, GlobalKey? key) {
    final kw = widget.searchKeyword;
    final pp = widget.projectPath;
    final rel = widget.isGlobalRelative;

    switch (sd.name) {
      case 'vfs': return VfsSection(key: key, projectPath: pp, searchKeyword: kw, isGlobalRelative: rel);
      case 'aime': return AimeSection(key: key, projectPath: pp, searchKeyword: kw, isGlobalRelative: rel);
      case 'dns': return NetworkSection(key: key, projectPath: pp, searchKeyword: kw);
      case 'keychip': return BoardSection(key: key, projectPath: pp, searchKeyword: kw);
      case 'gfx': return GfxSection(key: key, projectPath: pp, searchKeyword: kw);
      case 'aimeio': return AimeioSection(key: key, projectPath: pp, searchKeyword: kw, isGlobalRelative: rel);

      case 'led15093': return LedSection(key: key, projectPath: pp, searchKeyword: kw, boardName: 'led15093');
      case 'led15070': return LedSection(key: key, projectPath: pp, searchKeyword: kw, boardName: 'led15070');
      case 'led15083': return LedSection(key: key, projectPath: pp, searchKeyword: kw, boardName: 'led15083');
      case 'led15094': return LedSection(key: key, projectPath: pp, searchKeyword: kw, boardName: 'led15094');
      case 'led': return LedSection(key: key, projectPath: pp, searchKeyword: kw, boardName: 'led');

      case 'io3': return Io3Section(key: key, projectPath: pp, searchKeyword: kw);
      case 'io4': return Io4Section(key: key, projectPath: pp, searchKeyword: kw);
      case 'io2': return Io2Section(key: key, projectPath: pp, searchKeyword: kw);
      case 'keyboard': return KeyboardSection(key: key, projectPath: pp, searchKeyword: kw);

      case 'xinput': return XinputSection(key: key, projectPath: pp, searchKeyword: kw);
      case 'dinput': return DinputSection(key: key, projectPath: pp, searchKeyword: kw);
      case 'slider': return SliderIrSection(key: key, projectPath: pp, searchKeyword: kw);
      case 'ir': return null; // handled by slider+ir combo in SliderIrSection

      case 'chuniio': return ChuniioSection(key: key, projectPath: pp, searchKeyword: kw, isGlobalRelative: rel);
      case 'idacio': return IoDllCustom(key: key, projectPath: pp, searchKeyword: kw, isGlobalRelative: rel, section: 'idacio', label: 'IDAC IO DLL');
      case 'ektio': return IoDllCustom(key: key, projectPath: pp, searchKeyword: kw, isGlobalRelative: rel, section: 'ektio', label: 'EKT IO DLL');
      case 'sekitoio': return IoDllCustom(key: key, projectPath: pp, searchKeyword: kw, isGlobalRelative: rel, section: 'sekitoio', label: 'Sekito IO DLL');
      case 'mu3io': return IoDllCustom(key: key, projectPath: pp, searchKeyword: kw, isGlobalRelative: rel, section: 'mu3io', label: 'Mu3 IO DLL');
      case 'mai2io': return IoDllCustom(key: key, projectPath: pp, searchKeyword: kw, isGlobalRelative: rel, section: 'mai2io', label: 'Mai2 IO DLL');

      case 'vfd': return VfdSection(key: key, projectPath: pp, searchKeyword: kw);
      case 'aime2': return Aime2Section(key: key, projectPath: pp, searchKeyword: kw);
      case 'eeprom': return EepromSection(key: key, projectPath: pp, searchKeyword: kw);
      case 'unity': return UnitySection(key: key, projectPath: pp, searchKeyword: kw);
      case 'ffb': return FfbSection(key: key, projectPath: pp, searchKeyword: kw);
      case 'indrun': return IndrunSection(key: key, projectPath: pp, searchKeyword: kw);

      default: return null;
    }
  }
}
