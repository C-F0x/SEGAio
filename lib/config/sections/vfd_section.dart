import 'package:fluent_ui/fluent_ui.dart';
import '../../shared/ini_reader.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class VfdSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  const VfdSection({super.key, required this.projectPath, this.searchKeyword = ''});
  @override
  State<VfdSection> createState() => _VfdSectionState();
}

class _VfdSectionState extends State<VfdSection> implements ConfigSection {
  bool _loading = true, _enable = false;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { final s = (await IniReader.load(widget.projectPath))?.section('vfd'); if (s != null) _enable = s.getBool('enable'); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  @override
  void reloadData() => _load();
  @override
  Map<String, Map<String, String>> getConfigData() => { 'vfd': { 'enable': _enable ? '1' : '0' } };
  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    return SwitchField(section: 'vfd', field: 'enable', label: 'Enable VFD Emulation', value: _enable, onChanged: (v) => setState(() => _enable = v), searchKeyword: widget.searchKeyword);
  }
}
