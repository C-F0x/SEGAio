import 'package:fluent_ui/fluent_ui.dart';
import '../../shared/ini_reader.dart';
import '../../shared/vk.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class Aime2Section extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  const Aime2Section({super.key, required this.projectPath, this.searchKeyword = ''});
  @override
  State<Aime2Section> createState() => _Aime2SectionState();
}
class _Aime2SectionState extends State<Aime2Section> implements ConfigSection {
  bool _loading = true, _enable = false;
  final _pathCtrl = TextEditingController();
  final _scanCtrl = TextEditingController();
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _pathCtrl.dispose(); _scanCtrl.dispose(); super.dispose(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { final s = (await IniReader.load(widget.projectPath))?.section('aime2');
      if (s != null) { _enable = s.getBool('enable'); _pathCtrl.text = s.getString('aimePath'); _scanCtrl.text = s.getString('scan'); }
    } finally { if (mounted) setState(() => _loading = false); }
  }
  @override void reloadData() => _load();
  @override Map<String, Map<String, String>> getConfigData() => { 'aime2': { 'enable': _enable ? '1' : '0', 'aimePath': _pathCtrl.text, 'scan': _scanCtrl.text } };
  @override Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SwitchField(section: 'aime2', field: 'enable', label: 'Enable 2nd Reader', value: _enable, onChanged: (v) => setState(() => _enable = v), searchKeyword: kw),
      SettingField(section: 'aime2', field: 'aimePath', label: 'Card Path (Reader 2)', searchKeyword: kw, child: TextBox(controller: _pathCtrl)),
      SettingField(section: 'aime2', field: 'scan', label: 'Scan Key (Reader 2)', searchKeyword: kw,
        child: Row(children: [Expanded(child: TextBox(controller: _scanCtrl, readOnly: true)), const SizedBox(width: 8),
          Button(child: const Icon(FluentIcons.keyboard_classic), onPressed: () => VKMapper.scan(context, (hex) => setState(() => _scanCtrl.text = hex)))])),
    ]);
  }
}
