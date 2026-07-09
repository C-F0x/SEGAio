import 'package:fluent_ui/fluent_ui.dart';
import '../../shared/ini_reader.dart';
import '../../shared/vk.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class Io3Section extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  const Io3Section({super.key, required this.projectPath, this.searchKeyword = ''});
  @override
  State<Io3Section> createState() => _Io3SectionState();
}

class _Io3SectionState extends State<Io3Section> implements ConfigSection {
  final Map<String, TextEditingController> _io3 = {
    'test': TextEditingController(), 'service': TextEditingController(),
    'coin': TextEditingController(), 'ir': TextEditingController(),
  };
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { for (final c in _io3.values) c.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = (await IniReader.load(widget.projectPath))?.section('io3');
      if (s != null) { for (final e in _io3.entries) { final v = s.getString(e.key); if (v.isNotEmpty) e.value.text = v; } }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();

  @override
  Map<String, Map<String, String>> getConfigData() => { 'io3': _io3.map((k, v) => MapEntry(k, v.text)) };

  Widget _keyItem(String label, TextEditingController ctrl) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
      Expanded(flex: 3, child: Text(label)),
      Expanded(flex: 7, child: Row(children: [
        Expanded(child: TextBox(controller: ctrl, readOnly: true)),
        const SizedBox(width: 8),
        Container(width: 80, alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(border: Border.all(color: FluentTheme.of(context).resources.surfaceStrokeColorDefault), borderRadius: BorderRadius.circular(4)),
          child: Text(VKMapper.parse(ctrl.text), style: TextStyle(color: FluentTheme.of(context).accentColor, fontWeight: FontWeight.bold))),
        const SizedBox(width: 8),
        Button(child: const Icon(FluentIcons.keyboard_classic), onPressed: () => VKMapper.scan(context, (hex) => setState(() => ctrl.text = hex))),
      ])),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    const targets = ['io3', 'test', 'service', 'coin', 'ir'];
    if (kw.isNotEmpty && !targets.any((t) => t.contains(kw.toLowerCase()))) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ..._io3.entries.where((e) => kw.isEmpty || e.key.contains(kw.toLowerCase())).map((e) => _keyItem(e.key.toUpperCase(), e.value)),
    ]);
  }
}
