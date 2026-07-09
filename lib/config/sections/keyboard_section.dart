import 'package:fluent_ui/fluent_ui.dart';
import '../../shared/ini_reader.dart';
import '../../shared/vk.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class KeyboardSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  const KeyboardSection({super.key, required this.projectPath, this.searchKeyword = ''});
  @override
  State<KeyboardSection> createState() => _KeyboardSectionState();
}

class _KeyboardSectionState extends State<KeyboardSection> implements ConfigSection {
  final _keys = <String, TextEditingController>{};
  bool _loading = true;
  static const _fields = ['cancel', 'decide', 'up', 'down', 'left', 'right', 'reserve', 'left_2', 'right_2'];

  @override
  void initState() { super.initState(); for (final f in _fields) _keys[f] = TextEditingController(); _load(); }
  @override
  void dispose() { for (final c in _keys.values) c.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final s = (await IniReader.load(widget.projectPath))?.section('keyboard');
      if (s != null) { for (final e in _keys.entries) { final v = s.getString(e.key); if (v.isNotEmpty) e.value.text = v; } }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();
  @override
  Map<String, Map<String, String>> getConfigData() => { 'keyboard': _keys.map((k, v) => MapEntry(k, v.text)) };

  Widget _kc(String l, TextEditingController c) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
    Expanded(flex: 3, child: Text(l)), Expanded(flex: 7, child: Row(children: [
      Expanded(child: TextBox(controller: c, readOnly: true)), const SizedBox(width: 8),
      Container(width: 80, alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: FluentTheme.of(context).resources.surfaceStrokeColorDefault), borderRadius: BorderRadius.circular(4)),
        child: Text(VKMapper.parse(c.text), style: TextStyle(color: FluentTheme.of(context).accentColor, fontWeight: FontWeight.bold))),
      const SizedBox(width: 8), Button(child: const Icon(FluentIcons.keyboard_classic), onPressed: () => VKMapper.scan(context, (hex) => setState(() => c.text = hex))),
    ])),
  ]));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ..._keys.entries.where((e) => kw.isEmpty || e.key.contains(kw.toLowerCase())).map((e) => _kc(e.key.toUpperCase(), e.value)),
    ]);
  }
}
