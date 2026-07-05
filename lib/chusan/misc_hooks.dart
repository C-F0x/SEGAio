import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as p;
import '../shared/ini_reader.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/setting_item.dart';

class MiscHooksConfig extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;

  const MiscHooksConfig({
    super.key,
    required this.projectPath,
    this.searchKeyword = "",
  });

  @override
  State<MiscHooksConfig> createState() => MiscHooksConfigState();
}

class MiscHooksConfigState extends State<MiscHooksConfig> {
  bool _isLoading = true;
  bool _gfxEnable = true;
  bool _windowed = true;
  bool _framed = false;
  bool _dpiAware = true;
  int _monitorValue = 0;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final ini = await IniReader.load(widget.projectPath);
      if (ini == null) return;

      final gfx = ini.section('gfx');
      if (gfx != null) {
        _gfxEnable = gfx.getBool('enable', true);
        _windowed = gfx.getBool('windowed', true);
        _framed = gfx.getBool('framed');
        _dpiAware = gfx.getBool('dpiAware', true);
        _monitorValue = gfx.getInt('monitor');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, Map<String, String>> getConfigData() {
    return {
      'gfx': {
        'enable': _gfxEnable ? '1' : '0',
        'windowed': _windowed ? '1' : '0',
        'framed': _framed ? '1' : '0',
        'dpiAware': _dpiAware ? '1' : '0',
        'monitor': _monitorValue.toString(),
      },
    };
  }

  Widget _buildSwitchItem(
      String label, bool value, Function(bool) onChanged) {
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
      "Misc. hooks settings", "Enable Graphics Hook", "Windowed Mode",
      "Show Window Frame", "DPI Awareness", "Target Monitor"
    ];
    final kw = widget.searchKeyword;
    final hasMatch = kw.isEmpty ||
        searchTargets.any((l) => l.toLowerCase().contains(kw.toLowerCase()));
    if (!hasMatch) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Misc. hooks settings",
          icon: FluentIcons.video,
          visible: kw.isEmpty,
        ),
        _buildSwitchItem("Enable Graphics Hook", _gfxEnable,
            (v) => setState(() => _gfxEnable = v)),
        _buildSwitchItem("Windowed Mode", _windowed,
            (v) => setState(() => _windowed = v)),
        _buildSwitchItem("Show Window Frame", _framed,
            (v) => setState(() => _framed = v)),
        _buildSwitchItem("DPI Awareness", _dpiAware,
            (v) => setState(() => _dpiAware = v)),
        if (kw.isEmpty ||
            "target monitor".contains(kw.toLowerCase()))
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: InfoLabel(
              label:
                  "Target Monitor (Fullscreen only, 0=Primary)",
              child: SizedBox(
                width: 200,
                child: NumberBox<int>(
                  value: _monitorValue,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _monitorValue = v);
                    }
                  },
                  min: 0,
                  max: 16,
                  mode: SpinButtonPlacementMode.inline,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
