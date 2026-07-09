import 'package:fluent_ui/fluent_ui.dart';
import '../../shared/ini_reader.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class BoardSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  const BoardSection({super.key, required this.projectPath, this.searchKeyword = ''});
  @override
  State<BoardSection> createState() => _BoardSectionState();
}

class _BoardSectionState extends State<BoardSection> implements ConfigSection {
  final _idCtrl = TextEditingController();
  final _subnetCtrl = TextEditingController();
  final _pcbidCtrl = TextEditingController();
  bool _loading = true, _sysEnable = true, _freeplay = false;
  int _dipsw1 = 1, _dipsw2 = 1, _dipsw3 = 1, _dipsw4 = 0, _dipsw5 = 0;
  String? _idErr, _subnetErr, _pcbidErr;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _idCtrl.dispose(); _subnetCtrl.dispose(); _pcbidCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ini = await IniReader.load(widget.projectPath);
      var s = ini?.section('keychip');
      if (s != null) { _idCtrl.text = s.getString('id'); _subnetCtrl.text = s.getString('subnet'); }
      s = ini?.section('pcbid');
      if (s != null) { _pcbidCtrl.text = s.getString('serialNo'); }
      s = ini?.section('system');
      if (s != null) { _sysEnable = s.getBool('enable', true); _freeplay = s.getBool('freeplay');
        _dipsw1 = s.getInt('dipsw1', 1); _dipsw2 = s.getInt('dipsw2', 1); _dipsw3 = s.getInt('dipsw3', 1);
        _dipsw4 = s.getInt('dipsw4'); _dipsw5 = s.getInt('dipsw5'); }
      _validate();
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();

  void _validate() {
    setState(() {
      _idErr = !RegExp(r'^A\d{2}[EX]-(01|20)[ABCDEU]\d{8}$').hasMatch(_idCtrl.text) ? 'Format: A69E-01A88888888' : null;
      _subnetErr = !RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(_subnetCtrl.text) ? 'Invalid IP' : null;
      _pcbidErr = !RegExp(r'^[A-Z0-9]+$').hasMatch(_pcbidCtrl.text) ? 'Invalid PCBID' : null;
    });
  }

  @override
  Map<String, Map<String, String>> getConfigData() => {
    'keychip': { 'id': _idCtrl.text, 'subnet': _subnetCtrl.text },
    'pcbid': { 'serialNo': _pcbidCtrl.text },
    'system': { 'enable': _sysEnable ? '1' : '0', 'freeplay': _freeplay ? '1' : '0',
      'dipsw1': _dipsw1.toString(), 'dipsw2': _dipsw2.toString(), 'dipsw3': _dipsw3.toString(),
      'dipsw4': _dipsw4.toString(), 'dipsw5': _dipsw5.toString() },
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    const labels = ['Keychip ID', 'Subnet', 'PCBID', 'System', 'Free Play', 'LAN Install', 'Monitor', 'Cab Type'];
    if (kw.isNotEmpty && !labels.any((l) => l.toLowerCase().contains(kw.toLowerCase()))) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SettingField(section: 'keychip', field: 'id', label: 'Keychip ID', searchKeyword: kw, error: _idErr,
        child: TextBox(controller: _idCtrl, onChanged: (_) => _validate())),
      SettingField(section: 'keychip', field: 'subnet', label: 'Subnet Mask', searchKeyword: kw, error: _subnetErr,
        child: TextBox(controller: _subnetCtrl, onChanged: (_) => _validate())),
      SettingField(section: 'pcbid', field: 'serialNo', label: 'PCBID SerialNo', searchKeyword: kw, error: _pcbidErr,
        child: TextBox(controller: _pcbidCtrl, onChanged: (_) => _validate())),
      SwitchField(section: 'system', field: 'enable', label: 'Enable System', value: _sysEnable, onChanged: (v) => setState(() => _sysEnable = v), searchKeyword: kw),
      if (_sysEnable) ...[
        SwitchField(section: 'system', field: 'freeplay', label: 'Free Play', value: _freeplay, onChanged: (v) => setState(() => _freeplay = v), searchKeyword: kw),
        SettingField(section: 'system', field: 'dipsw1', label: 'LAN Install', searchKeyword: kw,
          child: ComboBox<int>(value: _dipsw1, items: const [ComboBoxItem(value: 1, child: Text('Server (1)')), ComboBoxItem(value: 0, child: Text('Client (0)'))],
            onChanged: (v) => setState(() => _dipsw1 = v!))),
        SettingField(section: 'system', field: 'dipsw2', label: 'Monitor', searchKeyword: kw,
          child: ComboBox<int>(value: _dipsw2, items: const [ComboBoxItem(value: 0, child: Text('120 FPS')), ComboBoxItem(value: 1, child: Text('60 FPS'))],
            onChanged: (v) => setState(() => _dipsw2 = v!))),
        SettingField(section: 'system', field: 'dipsw3', label: 'Cab Type', searchKeyword: kw,
          child: ComboBox<int>(value: _dipsw3, items: const [ComboBoxItem(value: 0, child: Text('SP')), ComboBoxItem(value: 1, child: Text('CVT'))],
            onChanged: (v) => setState(() => _dipsw3 = v!))),
      ],
    ]);
  }
}
