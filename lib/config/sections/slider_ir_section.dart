import 'package:fluent_ui/fluent_ui.dart';
import '../../shared/ini_reader.dart';
import '../../shared/vk.dart';
import '../section_widget.dart';

class SliderIrSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  const SliderIrSection({super.key, required this.projectPath, this.searchKeyword = ''});
  @override
  State<SliderIrSection> createState() => _SliderIrSectionState();
}

class _SliderIrSectionState extends State<SliderIrSection> implements ConfigSection {
  bool _loading = true, _sliderEn = false, _keyboardBind = false;
  final Map<String, TextEditingController> _irCtrl = {};
  final Map<String, TextEditingController> _sliderCtrl = {};

  @override
  void initState() { super.initState();
    for (int i = 1; i <= 6; i++) _irCtrl['ir$i'] = TextEditingController();
    for (int i = 1; i <= 32; i++) _sliderCtrl['cell$i'] = TextEditingController();
    _load();
  }

  @override
  void dispose() { for (final c in _irCtrl.values) c.dispose(); for (final c in _sliderCtrl.values) c.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ini = await IniReader.load(widget.projectPath);
      var s = ini?.section('slider');
      if (s != null) { _sliderEn = s.getBool('enable');
        for (final e in _sliderCtrl.entries) { final v = s.getString(e.key); if (v.isNotEmpty) { e.value.text = v; if (v != '0x00') _keyboardBind = true; } }
      }
      s = ini?.section('ir');
      if (s != null) { for (final e in _irCtrl.entries) { final v = s.getString(e.key); if (v.isNotEmpty) { e.value.text = v; if (v != '0x00') _keyboardBind = true; } } }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();

  @override
  Map<String, Map<String, String>> getConfigData() {
    final r = <String, Map<String, String>>{};
    r['slider'] = { 'enable': _sliderEn ? '1' : '0' };
    if (_keyboardBind) {
      r['ir'] = _irCtrl.map((k, v) => MapEntry(k, v.text));
      r['slider']!.addAll(_sliderCtrl.map((k, v) => MapEntry(k, v.text)));
    }
    return r;
  }

  Widget _block(String label, TextEditingController c, Color active) {
    final name = VKMapper.parse(c.text);
    final has = c.text.isNotEmpty && c.text != '0x00';
    final t = FluentTheme.of(context);
    final borderColor = has ? t.accentColor : t.resources.surfaceStrokeColorDefault;
    final bgColor = has ? active : t.micaBackgroundColor.withOpacity(0.5);
    final textColor = has ? Colors.black : Colors.grey;

    return Expanded(
      child: GestureDetector(
        onTap: () => VKMapper.scan(context, (hex) => setState(() => c.text = hex)),
        child: Container(
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.contain,
                      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                    ),
                    if (has)
                      FittedBox(
                        fit: BoxFit.contain,
                        child: Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.8))),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    if (kw.isNotEmpty && !'slider ir air cell'.contains(kw.toLowerCase())) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        ToggleSwitch(checked: _sliderEn, onChanged: (v) => setState(() => _sliderEn = v), content: const Text('Slider Emulation')),
        const SizedBox(width: 24),
        ToggleSwitch(checked: _keyboardBind, onChanged: (v) {
          setState(() { _keyboardBind = v; if (!v) { for (final c in _irCtrl.values) c.clear(); for (final c in _sliderCtrl.values) c.clear(); } });
        }, content: const Text('Keyboard Bind')),
      ]),
      if (_keyboardBind) Padding(padding: const EdgeInsets.only(top: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 15, child: Column(children: [
          const Text('[ir]', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 360, child: Column(
            children: List.generate(6, (i) => _block('AIR ${6 - i}', _irCtrl['ir${6 - i}']!, const Color(0xFF00FFFF).withOpacity(0.6))),
          )),
        ])),
        const SizedBox(width: 20),
        Expanded(flex: 85, child: Column(children: [
          const Text('[slider]', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 360, child: Column(
            children: List.generate(2, (row) => Expanded(
              child: Row(
                children: List.generate(16, (col) {
                  final n = (15 - col) * 2 + (row + 1);
                  return _block('$n', _sliderCtrl['cell$n']!, const Color(0xFFFFBF00).withOpacity(0.6));
                }),
              ),
            )),
          )),
        ])),
      ])),
    ]);
  }
}
