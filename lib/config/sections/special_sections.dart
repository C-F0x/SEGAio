import 'package:fluent_ui/fluent_ui.dart';
import '../../shared/ini_reader.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class UnitySection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  const UnitySection({super.key, required this.projectPath, this.searchKeyword = ''});
  @override
  State<UnitySection> createState() => _UnitySectionState();
}
class _UnitySectionState extends State<UnitySection> implements ConfigSection {
  bool _loading = true, _enable = false;
  final _targetCtrl = TextEditingController();
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _targetCtrl.dispose(); super.dispose(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { final s = (await IniReader.load(widget.projectPath))?.section('unity');
      if (s != null) { _enable = s.getBool('enable'); _targetCtrl.text = s.getString('targetAssembly'); }
    } finally { if (mounted) setState(() => _loading = false); }
  }
  @override void reloadData() => _load();
  @override Map<String, Map<String, String>> getConfigData() => { 'unity': { 'enable': _enable ? '1' : '0', 'targetAssembly': _targetCtrl.text } };
  @override Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SwitchField(section: 'unity', field: 'enable', label: 'Enable Unity Hook', value: _enable, onChanged: (v) => setState(() => _enable = v), searchKeyword: kw),
      SettingField(section: 'unity', field: 'targetAssembly', label: 'Target Assembly DLL', searchKeyword: kw, child: TextBox(controller: _targetCtrl, placeholder: 'Path to .NET DLL')),
    ]);
  }
}

class FfbSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  const FfbSection({super.key, required this.projectPath, this.searchKeyword = ''});
  @override
  State<FfbSection> createState() => _FfbSectionState();
}
class _FfbSectionState extends State<FfbSection> implements ConfigSection {
  bool _loading = true, _enable = false;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { final s = (await IniReader.load(widget.projectPath))?.section('ffb'); if (s != null) _enable = s.getBool('enable'); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  @override void reloadData() => _load();
  @override Map<String, Map<String, String>> getConfigData() => { 'ffb': { 'enable': _enable ? '1' : '0' } };
  @override Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    return SwitchField(section: 'ffb', field: 'enable', label: 'Enable Force Feedback', value: _enable, onChanged: (v) => setState(() => _enable = v), searchKeyword: widget.searchKeyword);
  }
}

class IndrunSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  const IndrunSection({super.key, required this.projectPath, this.searchKeyword = ''});
  @override
  State<IndrunSection> createState() => _IndrunSectionState();
}
class _IndrunSectionState extends State<IndrunSection> implements ConfigSection {
  bool _loading = true, _enable = false;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { final s = (await IniReader.load(widget.projectPath))?.section('indrun'); if (s != null) _enable = s.getBool('enable'); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  @override void reloadData() => _load();
  @override Map<String, Map<String, String>> getConfigData() => { 'indrun': { 'enable': _enable ? '1' : '0' } };
  @override Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    return SwitchField(section: 'indrun', field: 'enable', label: 'Enable IndRun Hooks', value: _enable, onChanged: (v) => setState(() => _enable = v), searchKeyword: widget.searchKeyword);
  }
}
