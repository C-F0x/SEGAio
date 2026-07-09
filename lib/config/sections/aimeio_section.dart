import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../shared/ini_reader.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class AimeioSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  final bool isGlobalRelative;
  const AimeioSection({super.key, required this.projectPath, this.searchKeyword = '', required this.isGlobalRelative});
  @override
  State<AimeioSection> createState() => _AimeioSectionState();
}

class _AimeioSectionState extends State<AimeioSection> implements ConfigSection {
  final _pathCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _pathCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final s = (await IniReader.load(widget.projectPath))?.section('aimeio');
      if (s != null) _pathCtrl.text = s.getString('path');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();

  Future<void> _pickDll() async {
    final r = await FilePicker.pickFiles(allowedExtensions: ['dll'], type: FileType.custom);
    if (r != null) setState(() => _pathCtrl.text = widget.isGlobalRelative ? p.relative(r.files.single.path!, from: widget.projectPath) : p.normalize(r.files.single.path!));
  }

  @override
  Map<String, Map<String, String>> getConfigData() => { 'aimeio': { 'path': _pathCtrl.text } };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    if (kw.isNotEmpty && !'AimeIO DLL'.toLowerCase().contains(kw.toLowerCase())) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SettingField(section: 'aimeio', field: 'path', label: 'AimeIO DLL Path', searchKeyword: kw,
        child: Row(children: [
          Expanded(child: TextBox(controller: _pathCtrl, placeholder: 'aimeio.dll')),
          const SizedBox(width: 8), Button(child: const Icon(FluentIcons.file_system), onPressed: _pickDll),
        ]),
      ),
    ]);
  }
}
