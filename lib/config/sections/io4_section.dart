import 'package:fluent_ui/fluent_ui.dart';
import '../../shared/ini_reader.dart';
import '../../shared/vk.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class Io4Section extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  final bool showMouse; // mu3 has mouse toggle
  final bool showMode;  // idac has mode selector (xinput/dinput/keyboard)
  final bool showSw;    // ekt/sekito have sw1/sw2
  const Io4Section({super.key, required this.projectPath, this.searchKeyword = '', this.showMouse = false, this.showMode = false, this.showSw = false});
  @override
  State<Io4Section> createState() => _Io4SectionState();
}

class _Io4SectionState extends State<Io4Section> implements ConfigSection {
  final _testCtrl = TextEditingController();
  final _serviceCtrl = TextEditingController();
  final _coinCtrl = TextEditingController();
  final _sw1Ctrl = TextEditingController();
  final _sw2Ctrl = TextEditingController();
  bool _loading = true, _mouse = false;
  String _mode = 'keyboard';

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _testCtrl.dispose(); _serviceCtrl.dispose(); _coinCtrl.dispose(); _sw1Ctrl.dispose(); _sw2Ctrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = (await IniReader.load(widget.projectPath))?.section('io4');
      if (s != null) {
        _testCtrl.text = s.getString('test');
        _serviceCtrl.text = s.getString('service');
        _coinCtrl.text = s.getString('coin');
        _mouse = s.getBool('mouse');
        _mode = s.getString('mode', 'keyboard');
        _sw1Ctrl.text = s.getString('sw1');
        _sw2Ctrl.text = s.getString('sw2');
      }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();

  @override
  Map<String, Map<String, String>> getConfigData() {
    final m = <String, String>{ 'test': _testCtrl.text, 'service': _serviceCtrl.text, 'coin': _coinCtrl.text };
    if (widget.showMouse) m['mouse'] = _mouse ? '1' : '0';
    if (widget.showMode) m['mode'] = _mode;
    if (widget.showSw) { m['sw1'] = _sw1Ctrl.text; m['sw2'] = _sw2Ctrl.text; }
    return { 'io4': m };
  }

  Widget _kc(String label, TextEditingController c) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
    Expanded(flex: 3, child: Text(label)),
    Expanded(flex: 7, child: Row(children: [
      Expanded(child: TextBox(controller: c, readOnly: true)),
      const SizedBox(width: 8), _badge(VKMapper.parse(c.text)),
      const SizedBox(width: 8), Button(child: const Icon(FluentIcons.keyboard_classic), onPressed: () => VKMapper.scan(context, (hex) => setState(() => c.text = hex))),
    ])),
  ]));

  Widget _badge(String name) {
    final t = FluentTheme.of(context);
    return Container(width: 80, alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: t.resources.surfaceStrokeColorDefault), borderRadius: BorderRadius.circular(4)),
      child: Text(name, style: TextStyle(color: t.accentColor, fontWeight: FontWeight.bold)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    if (kw.isNotEmpty && !'io4'.contains(kw.toLowerCase())) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _kc('TEST', _testCtrl), _kc('SERVICE', _serviceCtrl), _kc('COIN', _coinCtrl),
      if (widget.showMouse) SwitchField(section: 'io4', field: 'mouse', label: 'Mouse Lever Emulation', value: _mouse, onChanged: (v) => setState(() => _mouse = v), searchKeyword: kw),
      if (widget.showMode) SettingField(section: 'io4', field: 'mode', label: 'Input Mode', searchKeyword: kw,
        child: ComboBox<String>(value: _mode, items: ['keyboard', 'xinput', 'dinput'].map((e) => ComboBoxItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _mode = v!))),
      if (widget.showSw) ...[ _kc('SW1', _sw1Ctrl), _kc('SW2', _sw2Ctrl) ],
    ]);
  }
}
