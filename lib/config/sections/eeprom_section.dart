import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/ini_reader.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class EepromSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  const EepromSection({super.key, required this.projectPath, this.searchKeyword = ''});
  @override
  State<EepromSection> createState() => _EepromSectionState();
}
class _EepromSectionState extends State<EepromSection> implements ConfigSection {
  bool _loading = true;
  final _eepromCtrl = TextEditingController();
  final _sramCtrl = TextEditingController();
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _eepromCtrl.dispose(); _sramCtrl.dispose(); super.dispose(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { final ini = await IniReader.load(widget.projectPath);
      var s = ini?.section('eeprom'); if (s != null) _eepromCtrl.text = s.getString('path');
      s = ini?.section('sram'); if (s != null) _sramCtrl.text = s.getString('path');
    } finally { if (mounted) setState(() => _loading = false); }
  }
  @override void reloadData() => _load();
  @override Map<String, Map<String, String>> getConfigData() => { 'eeprom': { 'path': _eepromCtrl.text }, 'sram': { 'path': _sramCtrl.text } };
  @override Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SettingField(section: 'eeprom', field: 'path', label: 'EEPROM File Path', searchKeyword: kw, child: TextBox(controller: _eepromCtrl, placeholder: 'e.g. appdata/eeprom.bin')),
      SettingField(section: 'sram', field: 'path', label: 'SRAM File Path', searchKeyword: kw, child: TextBox(controller: _sramCtrl, placeholder: 'e.g. appdata/sram.bin')),
    ]);
  }
}
