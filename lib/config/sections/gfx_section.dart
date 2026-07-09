import 'package:fluent_ui/fluent_ui.dart';
import '../../shared/ini_reader.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class GfxSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  const GfxSection({super.key, required this.projectPath, this.searchKeyword = ''});
  @override
  State<GfxSection> createState() => _GfxSectionState();
}

class _GfxSectionState extends State<GfxSection> implements ConfigSection {
  bool _loading = true, _enable = true, _windowed = true, _framed = false, _dpiAware = true;
  int _monitor = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = (await IniReader.load(widget.projectPath))?.section('gfx');
      if (s != null) {
        _enable = s.getBool('enable', true);
        _windowed = s.getBool('windowed', true);
        _framed = s.getBool('framed');
        _dpiAware = s.getBool('dpiAware', true);
        _monitor = s.getInt('monitor');
      }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();

  @override
  Map<String, Map<String, String>> getConfigData() => {
    'gfx': { 'enable': _enable ? '1' : '0', 'windowed': _windowed ? '1' : '0', 'framed': _framed ? '1' : '0',
      'dpiAware': _dpiAware ? '1' : '0', 'monitor': _monitor.toString() },
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    const labels = ['Graphics Hook', 'Windowed', 'Frame', 'DPI', 'Monitor'];
    if (kw.isNotEmpty && !labels.any((l) => l.toLowerCase().contains(kw.toLowerCase()))) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SwitchField(section: 'gfx', field: 'enable', label: 'Enable Graphics Hook', value: _enable, onChanged: (v) => setState(() => _enable = v), searchKeyword: kw),
      SwitchField(section: 'gfx', field: 'windowed', label: 'Windowed Mode', value: _windowed, onChanged: (v) => setState(() => _windowed = v), searchKeyword: kw),
      SwitchField(section: 'gfx', field: 'framed', label: 'Show Window Frame', value: _framed, onChanged: (v) => setState(() => _framed = v), searchKeyword: kw),
      SwitchField(section: 'gfx', field: 'dpiAware', label: 'DPI Awareness', value: _dpiAware, onChanged: (v) => setState(() => _dpiAware = v), searchKeyword: kw),
      SettingField(section: 'gfx', field: 'monitor', label: 'Target Monitor (0=Primary)', searchKeyword: kw,
        child: SizedBox(width: 200, child: NumberBox<int>(value: _monitor, onChanged: (v) { if (v != null) setState(() => _monitor = v); }, min: 0, max: 16, mode: SpinButtonPlacementMode.inline))),
    ]);
  }
}
