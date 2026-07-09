import 'package:fluent_ui/fluent_ui.dart';
import '../../shared/ini_reader.dart';
import '../section_widget.dart';
import '../setting_field.dart';

/// 通用 LED 配置 — 根据不同游戏型号显示不同板卡名称
class LedSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  final String boardName; // "led15093", "led15070", "led15083", "led15094"
  const LedSection({super.key, required this.projectPath, this.searchKeyword = '', required this.boardName});
  @override
  State<LedSection> createState() => _LedSectionState();
}

class _LedSectionState extends State<LedSection> implements ConfigSection {
  bool _loading = true, _boardEnable = false;
  bool _cabPipe = false, _cabSerial = false, _ctrlPipe = false, _ctrlSerial = false, _openithm = false;
  final _portCtrl = TextEditingController();
  final _baudCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _portCtrl.dispose(); _baudCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ini = await IniReader.load(widget.projectPath);
      var s = ini?.section(widget.boardName);
      if (s != null) _boardEnable = s.getBool('enable');
      s = ini?.section('led');
      if (s != null) {
        _cabPipe = s.getBool('cabLedOutputPipe');
        _cabSerial = s.getBool('cabLedOutputSerial');
        _ctrlPipe = s.getBool('controllerLedOutputPipe');
        _ctrlSerial = s.getBool('controllerLedOutputSerial');
        _openithm = s.getBool('controllerLedOutputOpeNITHM');
        _portCtrl.text = s.getString('serialPort');
        _baudCtrl.text = s.getString('serialBaud');
      }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();

  @override
  Map<String, Map<String, String>> getConfigData() {
    return {
      widget.boardName: { 'enable': _boardEnable ? '1' : '0' },
      'led': { 'cabLedOutputPipe': _cabPipe ? '1' : '0', 'cabLedOutputSerial': _cabSerial ? '1' : '0',
        'controllerLedOutputPipe': _ctrlPipe ? '1' : '0', 'controllerLedOutputSerial': _ctrlSerial ? '1' : '0',
        'controllerLedOutputOpeNITHM': _openithm ? '1' : '0',
        'serialPort': _portCtrl.text.isEmpty ? 'COM5' : _portCtrl.text,
        'serialBaud': _baudCtrl.text.isEmpty ? '921600' : _baudCtrl.text },
    };
  }

  Widget _sw(String label, bool val, ValueChanged<bool> onChanged) {
    if (widget.searchKeyword.isNotEmpty && !label.toLowerCase().contains(widget.searchKeyword.toLowerCase())) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: ToggleSwitch(checked: val, onChanged: onChanged, content: Text(label)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    const targets = ['LED Emulation', 'Billboard', 'Controller', 'Pipe', 'Serial', 'OpeNITHM', 'COM', 'Baud'];
    if (kw.isNotEmpty && !targets.any((l) => l.toLowerCase().contains(kw.toLowerCase()))) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sw('LED Board Emulation', _boardEnable, (v) => setState(() => _boardEnable = v)),
      if (kw.isEmpty || 'billboard'.contains(kw.toLowerCase()) || 'pipe'.contains(kw.toLowerCase()) || 'serial'.contains(kw.toLowerCase()))
        InfoLabel(label: 'Billboard LED', child: Row(children: [
          _sw('Pipe Output', _cabPipe, (v) => setState(() => _cabPipe = v)),
          const SizedBox(width: 20), _sw('Serial Output', _cabSerial, (v) => setState(() => _cabSerial = v)),
        ])),
      const SizedBox(height: 8),
      if (kw.isEmpty || 'controller'.contains(kw.toLowerCase()) || 'openithm'.contains(kw.toLowerCase()))
        InfoLabel(label: 'Controller LED', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _sw('Pipe Output', _ctrlPipe, (v) => setState(() => _ctrlPipe = v)),
            const SizedBox(width: 20), _sw('Serial Output', _ctrlSerial, (v) => setState(() => _ctrlSerial = v)),
          ]),
          _sw('Use OpeNITHM Protocol', _openithm, (v) => setState(() => _openithm = v)),
        ])),
      if (kw.isEmpty || 'com'.contains(kw.toLowerCase()) || 'baud'.contains(kw.toLowerCase()))
        Row(children: [
          Expanded(child: InfoLabel(label: 'Serial Port', child: TextBox(controller: _portCtrl, placeholder: 'COM5'))),
          const SizedBox(width: 20),
          Expanded(child: InfoLabel(label: 'Baud Rate', child: TextBox(controller: _baudCtrl, placeholder: '921600'))),
        ]),
    ]);
  }
}
