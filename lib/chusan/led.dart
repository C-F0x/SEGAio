import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as p;
import '../shared/ini_reader.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/setting_item.dart';

class LedConfig extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;

  const LedConfig({
    super.key,
    required this.projectPath,
    this.searchKeyword = "",
  });

  @override
  State<LedConfig> createState() => LedConfigState();
}

class LedConfigState extends State<LedConfig> {
  bool _isLoading = true;
  bool _led15093Enable = false;
  bool _cabLedOutputPipe = false;
  bool _cabLedOutputSerial = false;
  bool _controllerLedOutputPipe = false;
  bool _controllerLedOutputSerial = false;
  bool _controllerLedOutputOpeNITHM = false;
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _baudController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _portController.dispose();
    _baudController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final ini = await IniReader.load(widget.projectPath);
      if (ini == null) return;

      final led15093 = ini.section('led15093');
      if (led15093 != null) {
        _led15093Enable = led15093.getBool('enable');
      }

      final led = ini.section('led');
      if (led != null) {
        _cabLedOutputPipe = led.getBool('cabLedOutputPipe');
        _cabLedOutputSerial = led.getBool('cabLedOutputSerial');
        _controllerLedOutputPipe = led.getBool('controllerLedOutputPipe');
        _controllerLedOutputSerial = led.getBool('controllerLedOutputSerial');
        _controllerLedOutputOpeNITHM = led.getBool('controllerLedOutputOpeNITHM');
        _portController.text = led.getString('serialPort');
        _baudController.text = led.getString('serialBaud');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, Map<String, String>> getConfigData() {
    return {
      'led15093': {
        'enable': _led15093Enable ? '1' : '0',
      },
      'led': {
        'cabLedOutputPipe': _cabLedOutputPipe ? '1' : '0',
        'cabLedOutputSerial': _cabLedOutputSerial ? '1' : '0',
        'controllerLedOutputPipe': _controllerLedOutputPipe ? '1' : '0',
        'controllerLedOutputSerial': _controllerLedOutputSerial ? '1' : '0',
        'controllerLedOutputOpeNITHM': _controllerLedOutputOpeNITHM ? '1' : '0',
        'serialPort': _portController.text.isEmpty ? 'COM5' : _portController.text,
        'serialBaud': _baudController.text.isEmpty ? '921600' : _baudController.text,
      },
    };
  }

  Widget _buildSwitchItem(String label, bool value, Function(bool) onChanged) {
    if (widget.searchKeyword.isNotEmpty &&
        !label.toLowerCase().contains(widget.searchKeyword.toLowerCase())) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ToggleSwitch(
        checked: value,
        onChanged: onChanged,
        content: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    const searchTargets = [
      "LED settings", "LED Emulation", "Billboard LED", "Controller LED",
      "Pipe Output", "Serial Output", "OpeNITHM", "Serial Port", "Baud Rate"
    ];
    final kw = widget.searchKeyword;
    final hasMatch = kw.isEmpty ||
        searchTargets.any((l) => l.toLowerCase().contains(kw.toLowerCase()));
    if (!hasMatch) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "LED settings",
          icon: FluentIcons.lightbulb,
          visible: kw.isEmpty,
        ),
        _buildSwitchItem("LED Emulation", _led15093Enable,
            (v) => setState(() => _led15093Enable = v)),
        if (kw.isEmpty ||
            "billboard led".contains(kw.toLowerCase()) ||
            "pipe output".contains(kw.toLowerCase()) ||
            "serial output".contains(kw.toLowerCase()))
          InfoLabel(
            label: "Billboard LED",
            child: Row(
              children: [
                _buildSwitchItem("Pipe Output", _cabLedOutputPipe,
                    (v) => setState(() => _cabLedOutputPipe = v)),
                const SizedBox(width: 20),
                _buildSwitchItem("Serial Output", _cabLedOutputSerial,
                    (v) => setState(() => _cabLedOutputSerial = v)),
              ],
            ),
          ),
        const SizedBox(height: 10),
        if (kw.isEmpty ||
            "controller led".contains(kw.toLowerCase()) ||
            "openithm".contains(kw.toLowerCase()))
          InfoLabel(
            label: "Controller LED",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSwitchItem("Pipe Output", _controllerLedOutputPipe,
                        (v) => setState(() => _controllerLedOutputPipe = v)),
                    const SizedBox(width: 20),
                    _buildSwitchItem(
                        "Serial Output", _controllerLedOutputSerial,
                        (v) => setState(() => _controllerLedOutputSerial = v)),
                  ],
                ),
                _buildSwitchItem("Use OpeNITHM Protocol",
                    _controllerLedOutputOpeNITHM,
                    (v) => setState(() => _controllerLedOutputOpeNITHM = v)),
              ],
            ),
          ),
        if (kw.isEmpty ||
            "serial port".contains(kw.toLowerCase()) ||
            "baud rate".contains(kw.toLowerCase()))
          Row(
            children: [
              Expanded(
                child: InfoLabel(
                  label: "Serial Port",
                  child: TextBox(
                    controller: _portController,
                    placeholder: "COM5",
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: InfoLabel(
                  label: "Baud Rate",
                  child: TextBox(
                    controller: _baudController,
                    placeholder: "921600",
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
