import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as p;
import '../shared/ini_reader.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/setting_item.dart';

class BoardConfig extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;

  const BoardConfig({
    super.key,
    required this.projectPath,
    this.searchKeyword = "",
  });

  @override
  State<BoardConfig> createState() => BoardConfigState();
}

class BoardConfigState extends State<BoardConfig> {
  final TextEditingController _keychipIdController = TextEditingController();
  final TextEditingController _keychipSubnetController =
      TextEditingController();
  final TextEditingController _pcbidController = TextEditingController();

  bool _isLoading = true;
  bool _systemEnable = true;
  bool _freeplay = false;
  int _dipsw1 = 1;
  int _dipsw2 = 1;
  int _dipsw3 = 1;

  String? _keychipIdError, _keychipSubnetError, _pcbidError;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _keychipIdController.dispose();
    _keychipSubnetController.dispose();
    _pcbidController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final ini = await IniReader.load(widget.projectPath);
      if (ini == null) return;

      final keychip = ini.section('keychip');
      if (keychip != null) {
        _keychipIdController.text = keychip.getString('id');
        _keychipSubnetController.text = keychip.getString('subnet');
      }

      final pcbid = ini.section('pcbid');
      if (pcbid != null) {
        _pcbidController.text = pcbid.getString('serialNo');
      }

      final system = ini.section('system');
      if (system != null) {
        _systemEnable = system.getBool('enable', true);
        _freeplay = system.getBool('freeplay');
        _dipsw1 = system.getInt('dipsw1', 1);
        _dipsw2 = system.getInt('dipsw2', 1);
        _dipsw3 = system.getInt('dipsw3', 1);
      }

      _validateAll();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _validateAll() {
    setState(() {
      final id = _keychipIdController.text;
      if (id.isEmpty) {
        _keychipIdError = "Must print sth...";
      } else if (!RegExp(r'^A\d{2}[EX]-(01|20)[ABCDEU]\d{8}$')
          .hasMatch(id)) {
        _keychipIdError = "Format ERR (e.g A69E-01A88888888)";
      } else {
        _keychipIdError = null;
      }

      final subnet = _keychipSubnetController.text;
      if (subnet.isEmpty) {
        _keychipSubnetError = "Print sth..";
      } else if (!RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')
          .hasMatch(subnet)) {
        _keychipSubnetError = "Err IP";
      } else {
        _keychipSubnetError = null;
      }

      final pcbid = _pcbidController.text;
      if (pcbid.isEmpty) {
        _pcbidError = "Print Now";
      } else if (!RegExp(r'^[A-Z0-9]+$').hasMatch(pcbid)) {
        _pcbidError = "Null PCBID";
      } else {
        _pcbidError = null;
      }
    });
  }

  Map<String, Map<String, String>> getConfigData() {
    return {
      'keychip': {
        'id': _keychipIdController.text,
        'subnet': _keychipSubnetController.text,
      },
      'pcbid': {
        'serialNo': _pcbidController.text,
      },
      'system': {
        'enable': _systemEnable ? '1' : '0',
        'freeplay': _freeplay ? '1' : '0',
        'dipsw1': _dipsw1.toString(),
        'dipsw2': _dipsw2.toString(),
        'dipsw3': _dipsw3.toString(),
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    const labels = [
      "Keychip ID", "Subnet Mask", "PCBID SerialNo",
      "Enable System", "Free Play", "LAN Install", "Monitor", "Cab Type"
    ];
    final kw = widget.searchKeyword;
    final hasMatch = kw.isEmpty ||
        labels.any((l) => l.toLowerCase().contains(kw.toLowerCase()));
    if (!hasMatch) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Board Settings",
          icon: FluentIcons.settings,
          visible: kw.isEmpty,
        ),
        SettingItem(
          label: "Keychip ID",
          searchKeyword: kw,
          error: _keychipIdError,
          child: TextBox(
            controller: _keychipIdController,
            onChanged: (_) => _validateAll(),
          ),
        ),
        SettingItem(
          label: "Subnet Mask",
          searchKeyword: kw,
          error: _keychipSubnetError,
          child: TextBox(
            controller: _keychipSubnetController,
            onChanged: (_) => _validateAll(),
          ),
        ),
        SettingItem(
          label: "PCBID SerialNo",
          searchKeyword: kw,
          error: _pcbidError,
          child: TextBox(
            controller: _pcbidController,
            onChanged: (_) => _validateAll(),
          ),
        ),
        SwitchSettingItem(
          label: "Enable System",
          value: _systemEnable,
          onChanged: (v) => setState(() => _systemEnable = v),
          searchKeyword: kw,
        ),
        if (_systemEnable) ...[
          SwitchSettingItem(
            label: "Free Play",
            value: _freeplay,
            onChanged: (v) => setState(() => _freeplay = v),
            searchKeyword: kw,
          ),
          SettingItem(
            label: "LAN Install",
            searchKeyword: kw,
            child: ComboBox<int>(
              value: _dipsw1,
              items: const [
                ComboBoxItem(value: 1, child: Text("Server (1)")),
                ComboBoxItem(value: 0, child: Text("Client (0)")),
              ],
              onChanged: (v) => setState(() => _dipsw1 = v!),
            ),
          ),
          SettingItem(
            label: "Monitor",
            searchKeyword: kw,
            child: ComboBox<int>(
              value: _dipsw2,
              items: const [
                ComboBoxItem(value: 0, child: Text("120 FPS")),
                ComboBoxItem(value: 1, child: Text("60 FPS")),
              ],
              onChanged: (v) => setState(() => _dipsw2 = v!),
            ),
          ),
          SettingItem(
            label: "Cab Type",
            searchKeyword: kw,
            child: ComboBox<int>(
              value: _dipsw3,
              items: const [
                ComboBoxItem(value: 0, child: Text("SP")),
                ComboBoxItem(value: 1, child: Text("CVT")),
              ],
              onChanged: (v) => setState(() => _dipsw3 = v!),
            ),
          ),
        ],
      ],
    );
  }
}
