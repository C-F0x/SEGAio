import 'package:fluent_ui/fluent_ui.dart';
import '../../shared/ini_reader.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class XinputSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  const XinputSection({super.key, required this.projectPath, this.searchKeyword = ''});
  @override
  State<XinputSection> createState() => _XinputSectionState();
}

class _XinputSectionState extends State<XinputSection> implements ConfigSection {
  bool _loading = true, _autoN = true, _singleStick = true, _linear = true;
  int _leftDead = 7849, _rightDead = 8689;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final s = (await IniReader.load(widget.projectPath))?.section('xinput');
      if (s != null) { _autoN = s.getBool('autoNeutral', true); _singleStick = s.getBool('singleStickSteering', true);
        _linear = s.getBool('linearSteering', true); _leftDead = s.getInt('leftStickDeadzone', 7849); _rightDead = s.getInt('rightStickDeadzone', 8689); }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();

  @override
  Map<String, Map<String, String>> getConfigData() => { 'xinput': { 'autoNeutral': _autoN ? '1' : '0',
    'singleStickSteering': _singleStick ? '1' : '0', 'linearSteering': _linear ? '1' : '0',
    'leftStickDeadzone': _leftDead.toString(), 'rightStickDeadzone': _rightDead.toString() } };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SwitchField(section: 'xinput', field: 'autoNeutral', label: 'Auto Neutral', value: _autoN, onChanged: (v) => setState(() => _autoN = v), searchKeyword: kw),
      SwitchField(section: 'xinput', field: 'singleStickSteering', label: 'Single Stick Steering', value: _singleStick, onChanged: (v) => setState(() => _singleStick = v), searchKeyword: kw),
      SwitchField(section: 'xinput', field: 'linearSteering', label: 'Linear Steering', value: _linear, onChanged: (v) => setState(() => _linear = v), searchKeyword: kw),
      SettingField(section: 'xinput', field: 'leftStickDeadzone', label: 'Left Stick Deadzone', searchKeyword: kw,
        child: NumberBox<int>(value: _leftDead, onChanged: (v) { if (v != null) setState(() => _leftDead = v); }, min: 0, max: 32767, mode: SpinButtonPlacementMode.inline)),
      SettingField(section: 'xinput', field: 'rightStickDeadzone', label: 'Right Stick Deadzone', searchKeyword: kw,
        child: NumberBox<int>(value: _rightDead, onChanged: (v) { if (v != null) setState(() => _rightDead = v); }, min: 0, max: 32767, mode: SpinButtonPlacementMode.inline)),
    ]);
  }
}
