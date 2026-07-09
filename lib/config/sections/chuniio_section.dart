import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../shared/ini_reader.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class ChuniioSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  final bool isGlobalRelative;
  const ChuniioSection({super.key, required this.projectPath, this.searchKeyword = '', required this.isGlobalRelative});
  @override
  State<ChuniioSection> createState() => _ChuniioSectionState();
}

class _ChuniioSectionState extends State<ChuniioSection> implements ConfigSection {
  final _pathCtrl = TextEditingController();
  final _path32Ctrl = TextEditingController();
  final _path64Ctrl = TextEditingController();
  bool _loading = true, _dual = false;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _pathCtrl.dispose(); _path32Ctrl.dispose(); _path64Ctrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final s = (await IniReader.load(widget.projectPath))?.section('chuniio');
      if (s != null) {
        _pathCtrl.text = s.getString('path');
        _path32Ctrl.text = s.getString('path32');
        _path64Ctrl.text = s.getString('path64');
        _dual = _path32Ctrl.text.isNotEmpty || _path64Ctrl.text.isNotEmpty;
      }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();

  Future<void> _pickDll(TextEditingController c) async {
    final r = await FilePicker.pickFiles(allowedExtensions: ['dll'], type: FileType.custom);
    if (r != null) setState(() => c.text = widget.isGlobalRelative ? p.relative(r.files.single.path!, from: widget.projectPath) : p.normalize(r.files.single.path!));
  }

  @override
  Map<String, Map<String, String>> getConfigData() {
    final m = <String, String>{};
    if (_dual) { m['path32'] = _path32Ctrl.text; m['path64'] = _path64Ctrl.text; }
    else { m['path'] = _pathCtrl.text; }
    return { 'chuniio': m };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SettingField(section: 'chuniio', field: 'path', label: 'Single DLL Mode', searchKeyword: kw,
        child: ToggleSwitch(checked: !_dual, onChanged: (v) => setState(() => _dual = !v), content: Text(_dual ? 'Dual DLL' : 'Single DLL'))),
      if (!_dual)
        SettingField(section: 'chuniio', field: 'path', label: 'chuniio DLL Path', searchKeyword: kw,
          child: Row(children: [Expanded(child: TextBox(controller: _pathCtrl, placeholder: 'chuniio.dll')), const SizedBox(width: 8), Button(child: const Icon(FluentIcons.file_system), onPressed: () => _pickDll(_pathCtrl))]))
      else ...[
        SettingField(section: 'chuniio', field: 'path32', label: 'x86 DLL Path', searchKeyword: kw,
          child: Row(children: [Expanded(child: TextBox(controller: _path32Ctrl, placeholder: 'chuniio_x86.dll')), const SizedBox(width: 8), Button(child: const Icon(FluentIcons.file_system), onPressed: () => _pickDll(_path32Ctrl))])),
        SettingField(section: 'chuniio', field: 'path64', label: 'x64 DLL Path', searchKeyword: kw,
          child: Row(children: [Expanded(child: TextBox(controller: _path64Ctrl, placeholder: 'chuniio_x64.dll')), const SizedBox(width: 8), Button(child: const Icon(FluentIcons.file_system), onPressed: () => _pickDll(_path64Ctrl))])),
      ],
    ]);
  }
}
