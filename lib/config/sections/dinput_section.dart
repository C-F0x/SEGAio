import 'package:fluent_ui/fluent_ui.dart';
import '../../shared/ini_reader.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class DinputSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  const DinputSection({super.key, required this.projectPath, this.searchKeyword = ''});
  @override
  State<DinputSection> createState() => _DinputSectionState();
}

class _DinputSectionState extends State<DinputSection> implements ConfigSection {
  bool _loading = true;
  final _devCtrl = TextEditingController();
  final _pedalsCtrl = TextEditingController();
  final _shifterCtrl = TextEditingController();
  final _brakeCtrl = TextEditingController(text: 'RZ');
  final _accelCtrl = TextEditingController(text: 'Y');
  int _start = 1, _viewChg = 2, _shiftDn = 6, _shiftUp = 5;
  int _constFF = 100, _damper = 100, _rumble = 100, _rumbleDur = 1000, _baseDamper = 20, _deadband = 20;
  final _axes = ['X', 'Y', 'Z', 'RX', 'RY', 'RZ', 'U', 'V'];

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _devCtrl.dispose(); _pedalsCtrl.dispose(); _shifterCtrl.dispose(); _brakeCtrl.dispose(); _accelCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final s = (await IniReader.load(widget.projectPath))?.section('dinput');
      if (s != null) {
        _devCtrl.text = s.getString('deviceName'); _pedalsCtrl.text = s.getString('pedalsName'); _shifterCtrl.text = s.getString('shifterName');
        _brakeCtrl.text = s.getString('brakeAxis', 'RZ'); _accelCtrl.text = s.getString('accelAxis', 'Y');
        _start = s.getInt('start', 1); _viewChg = s.getInt('viewChg', 2); _shiftDn = s.getInt('shiftDn', 6); _shiftUp = s.getInt('shiftUp', 5);
        _constFF = s.getInt('constantForceStrength', 100); _damper = s.getInt('damperStrength', 100);
        _rumble = s.getInt('rumbleStrength', 100); _rumbleDur = s.getInt('rumbleDuration', 1000);
        _baseDamper = s.getInt('baseDamperFraction', 20); _deadband = s.getInt('deadband', 20);
      }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();

  @override
  Map<String, Map<String, String>> getConfigData() => { 'dinput': {
    'deviceName': _devCtrl.text, 'pedalsName': _pedalsCtrl.text, 'shifterName': _shifterCtrl.text,
    'brakeAxis': _brakeCtrl.text, 'accelAxis': _accelCtrl.text,
    'start': _start.toString(), 'viewChg': _viewChg.toString(), 'shiftDn': _shiftDn.toString(), 'shiftUp': _shiftUp.toString(),
    'constantForceStrength': _constFF.toString(), 'damperStrength': _damper.toString(),
    'rumbleStrength': _rumble.toString(), 'rumbleDuration': _rumbleDur.toString(),
    'baseDamperFraction': _baseDamper.toString(), 'deadband': _deadband.toString(),
  }};

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SettingField(section: 'dinput', field: 'deviceName', label: 'Wheel Device Name', searchKeyword: kw,
        child: TextBox(controller: _devCtrl, placeholder: 'e.g. G29')),
      SettingField(section: 'dinput', field: 'pedalsName', label: 'Pedals Device Name', searchKeyword: kw,
        child: TextBox(controller: _pedalsCtrl, placeholder: 'Leave blank if combined')),
      SettingField(section: 'dinput', field: 'shifterName', label: 'Shifter Device Name', searchKeyword: kw,
        child: TextBox(controller: _shifterCtrl, placeholder: 'Leave blank to simulate')),
      SettingField(section: 'dinput', field: 'brakeAxis', label: 'Brake Axis', searchKeyword: kw,
        child: ComboBox<String>(value: _brakeCtrl.text, items: _axes.map((e) => ComboBoxItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _brakeCtrl.text = v!))),
      SettingField(section: 'dinput', field: 'accelAxis', label: 'Accel Axis', searchKeyword: kw,
        child: ComboBox<String>(value: _accelCtrl.text, items: _axes.map((e) => ComboBoxItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _accelCtrl.text = v!))),
      const Divider(),
      const Padding(padding: EdgeInsets.only(bottom: 4), child: Text('Button Mappings', style: TextStyle(fontWeight: FontWeight.w600))),
      _nb('start', 'Start Button', _start, (v) => _start = v),
      _nb('viewChg', 'View Change', _viewChg, (v) => _viewChg = v),
      _nb('shiftDn', 'Shift Down', _shiftDn, (v) => _shiftDn = v),
      _nb('shiftUp', 'Shift Up', _shiftUp, (v) => _shiftUp = v),
      const Divider(),
      const Padding(padding: EdgeInsets.only(bottom: 4), child: Text('Force Feedback', style: TextStyle(fontWeight: FontWeight.w600))),
      _nb('constantForceStrength', 'Constant Force %', _constFF, (v) => _constFF = v),
      _nb('damperStrength', 'Damper %', _damper, (v) => _damper = v),
      _nb('rumbleStrength', 'Rumble %', _rumble, (v) => _rumble = v),
      _nb('rumbleDuration', 'Rumble Duration Factor', _rumbleDur, (v) => _rumbleDur = v),
      _nb('baseDamperFraction', 'Base Damper', _baseDamper, (v) => _baseDamper = v),
      _nb('deadband', 'Deadband (x0.1%)', _deadband, (v) => _deadband = v),
    ]);
  }

  Widget _nb(String field, String label, int val, ValueChanged<int> onChanged) {
    return SettingField(section: 'dinput', field: field, label: label, searchKeyword: widget.searchKeyword,
      child: SizedBox(width: 120, child: NumberBox<int>(value: val, onChanged: (v) { if (v != null) setState(() => onChanged(v)); },
        min: 0, max: 32767, mode: SpinButtonPlacementMode.inline)));
  }
}
