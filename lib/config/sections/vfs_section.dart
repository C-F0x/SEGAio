import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import '../../shared/ini_reader.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class VfsSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  final bool isGlobalRelative;
  const VfsSection({
    super.key,
    required this.projectPath,
    this.searchKeyword = '',
    required this.isGlobalRelative,
  });
  @override
  State<VfsSection> createState() => _VfsSectionState();
}

class _VfsSectionState extends State<VfsSection> implements ConfigSection {
  final _amfsCtrl = TextEditingController();
  final _optionCtrl = TextEditingController();
  final _appdataCtrl = TextEditingController();
  bool _loading = true;
  String? _amfsErr, _optionErr;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _amfsCtrl.dispose(); _optionCtrl.dispose(); _appdataCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ini = await IniReader.load(widget.projectPath);
      final vfs = ini?.section('vfs');
      if (vfs != null) {
        _amfsCtrl.text = vfs.getString('amfs');
        _optionCtrl.text = vfs.getString('option');
        _appdataCtrl.text = vfs.getString('appdata');
      }
      _validate();
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();

  void _validate() {
    setState(() {
      _amfsErr = _checkDir(_amfsCtrl.text, ['ICF1', 'ICF2']);
      _optionErr = _checkDir(_optionCtrl.text, ['A001']);
    });
  }

  String? _checkDir(String pathStr, List<String> items) {
    if (pathStr.isEmpty) return "Can't be blank";
    final full = p.isAbsolute(pathStr) ? pathStr : p.normalize(p.join(widget.projectPath, pathStr));
    final dir = Directory(full);
    if (!dir.existsSync()) return "Directory does not exist";
    try {
      final names = dir.listSync().map((e) => p.basename(e.path).toLowerCase()).toList();
      for (final item in items) { if (!names.contains(item.toLowerCase())) return "Missing: $item"; }
    } catch (_) { return "Read failed"; }
    return null;
  }

  String _fmt(String picked) => widget.isGlobalRelative ? p.relative(picked, from: widget.projectPath) : p.normalize(picked);

  Future<void> _pick(TextEditingController c) async {
    final sel = await FilePicker.getDirectoryPath();
    if (sel != null) { c.text = _fmt(sel); _validate(); }
  }

  @override
  Map<String, Map<String, String>> getConfigData() => {
    'vfs': { 'amfs': _amfsCtrl.text, 'option': _optionCtrl.text, 'appdata': _appdataCtrl.text },
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    const targets = ['AMFS Path', 'Option Path', 'AppData Path'];
    if (kw.isNotEmpty && !targets.any((l) => l.toLowerCase().contains(kw.toLowerCase()))) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SettingField(section: 'vfs', field: 'amfs', label: 'AMFS Path', searchKeyword: kw, error: _amfsErr,
        child: Row(children: [
          Expanded(child: TextBox(controller: _amfsCtrl, onChanged: (_) => _validate())),
          const SizedBox(width: 8),
          Button(child: const Icon(FluentIcons.folder_search), onPressed: () => _pick(_amfsCtrl)),
        ]),
      ),
      SettingField(section: 'vfs', field: 'option', label: 'Option Path', searchKeyword: kw, error: _optionErr,
        child: Row(children: [
          Expanded(child: TextBox(controller: _optionCtrl, onChanged: (_) => _validate())),
          const SizedBox(width: 8),
          Button(child: const Icon(FluentIcons.folder_search), onPressed: () => _pick(_optionCtrl)),
        ]),
      ),
      SettingField(section: 'vfs', field: 'appdata', label: 'AppData Path', searchKeyword: kw,
        child: Row(children: [
          Expanded(child: TextBox(controller: _appdataCtrl, onChanged: (_) => _validate())),
          const SizedBox(width: 8),
          Button(child: const Icon(FluentIcons.folder_search), onPressed: () => _pick(_appdataCtrl)),
        ]),
      ),
    ]);
  }
}
