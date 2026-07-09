import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../shared/ini_reader.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class IoDllCustom extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  final bool isGlobalRelative;
  final String section;   // "idacio", "ektio", "sekitoio", "mu3io", "mai2io"
  final String label;
  const IoDllCustom({super.key, required this.projectPath, this.searchKeyword = '', required this.isGlobalRelative, required this.section, required this.label});
  @override
  State<IoDllCustom> createState() => _IoDllCustomState();
}

class _IoDllCustomState extends State<IoDllCustom> implements ConfigSection {
  final _ctrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final s = (await IniReader.load(widget.projectPath))?.section(widget.section);
      if (s != null) _ctrl.text = s.getString('path');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();

  Future<void> _pick() async {
    final r = await FilePicker.pickFiles(allowedExtensions: ['dll'], type: FileType.custom);
    if (r != null) setState(() => _ctrl.text = widget.isGlobalRelative ? p.relative(r.files.single.path!, from: widget.projectPath) : p.normalize(r.files.single.path!));
  }

  @override
  Map<String, Map<String, String>> getConfigData() => { widget.section: { 'path': _ctrl.text } };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SettingField(section: widget.section, field: 'path', label: widget.label, searchKeyword: kw,
        child: Row(children: [Expanded(child: TextBox(controller: _ctrl, placeholder: '${widget.section}.dll')), const SizedBox(width: 8),
          Button(child: const Icon(FluentIcons.file_system), onPressed: _pick)])),
    ]);
  }
}
