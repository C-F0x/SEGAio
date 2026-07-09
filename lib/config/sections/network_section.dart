import 'package:fluent_ui/fluent_ui.dart';
import '../../shared/ini_reader.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class NetworkSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  const NetworkSection({super.key, required this.projectPath, this.searchKeyword = ''});
  @override
  State<NetworkSection> createState() => _NetworkSectionState();
}

class _NetworkSectionState extends State<NetworkSection> implements ConfigSection {
  final _dnsCtrl = TextEditingController();
  bool _loading = true, _netenv = false;
  double _suffix = 11.0;
  String _dnsPreset = 'Custom';
  static const _presets = {'Local': '127.0.0.1', 'AquaDX': 'aquadx.hydev.org', 'RIN-NET': 'aqua.naominet.live', 'Yuzu-net': 'aime.yuzunet.cn', 'Custom': ''};

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _dnsCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ini = await IniReader.load(widget.projectPath);
      final dns = ini?.section('dns');
      if (dns != null) {
        final v = dns.getString('default');
        _dnsCtrl.text = v;
        _dnsPreset = 'Custom';
        _presets.forEach((k, p) { if (v == p && k != 'Custom') _dnsPreset = k; });
      }
      final ne = ini?.section('netenv');
      if (ne != null) { _netenv = ne.getBool('enable'); _suffix = ne.getInt('addrSuffix', 11).toDouble(); }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();

  @override
  Map<String, Map<String, String>> getConfigData() => {
    'dns': { 'default': _dnsCtrl.text },
    'netenv': { 'enable': _netenv ? '1' : '0', 'addrSuffix': _suffix.toInt().toString() },
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    const targets = ['Server Address', 'Enable NetEnv', 'IP Suffix'];
    if (kw.isNotEmpty && !targets.any((l) => l.toLowerCase().contains(kw.toLowerCase()))) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SettingField(section: 'dns', field: 'default', label: 'Server Address', searchKeyword: kw,
        child: Row(children: [
          SizedBox(width: 140, child: ComboBox<String>(value: _dnsPreset,
            items: _presets.keys.map((e) => ComboBoxItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() { _dnsPreset = v!; if (v != 'Custom') _dnsCtrl.text = _presets[v]!; }))),
          const SizedBox(width: 8),
          Expanded(child: TextBox(controller: _dnsCtrl, placeholder: '127.0.0.1', enabled: _dnsPreset == 'Custom')),
        ]),
      ),
      SwitchField(section: 'netenv', field: 'enable', label: 'Enable NetEnv', value: _netenv, onChanged: (v) => setState(() => _netenv = v), searchKeyword: kw),
      SettingField(section: 'netenv', field: 'addrSuffix', label: 'IP Suffix: ${_suffix.toInt()}', searchKeyword: kw,
        child: Slider(value: _suffix, min: 2, max: 254, onChanged: _netenv ? (v) => setState(() => _suffix = v) : null)),
    ]);
  }
}
