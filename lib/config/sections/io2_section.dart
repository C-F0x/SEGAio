import 'package:fluent_ui/fluent_ui.dart';
import '../../shared/ini_reader.dart';
import '../../shared/vk.dart';
import '../section_widget.dart';

class Io2Section extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  const Io2Section({super.key, required this.projectPath, this.searchKeyword = ''});
  @override
  State<Io2Section> createState() => _Io2SectionState();
}

class _Io2SectionState extends State<Io2Section> implements ConfigSection {
  final _testCtrl = TextEditingController();
  final _serviceCtrl = TextEditingController();
  final _coinCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _testCtrl.dispose(); _serviceCtrl.dispose(); _coinCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final s = (await IniReader.load(widget.projectPath))?.section('io2');
      if (s != null) { _testCtrl.text = s.getString('test'); _serviceCtrl.text = s.getString('service'); _coinCtrl.text = s.getString('coin'); }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();
  @override
  Map<String, Map<String, String>> getConfigData() => { 'io2': { 'test': _testCtrl.text, 'service': _serviceCtrl.text, 'coin': _coinCtrl.text } };

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
    if (kw.isNotEmpty && !'io2'.contains(kw.toLowerCase())) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _kc('TEST', _testCtrl), _kc('SERVICE', _serviceCtrl), _kc('COIN', _coinCtrl),
    ]);
  }
}
