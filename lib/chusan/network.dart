import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as p;
import '../shared/ini_reader.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/setting_item.dart';

class NetworkConfig extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;

  const NetworkConfig({
    super.key,
    required this.projectPath,
    this.searchKeyword = "",
  });

  @override
  State<NetworkConfig> createState() => NetworkConfigState();
}

class NetworkConfigState extends State<NetworkConfig> {
  final TextEditingController _dnsDefaultController = TextEditingController();

  bool _isLoading = true;
  bool _netenvEnable = false;
  double _netenvAddrSuffix = 11.0;
  String _selectedDns = "Custom";

  static const Map<String, String> _dnsPresets = {
    "Local": "127.0.0.1",
    "AquaDX": "aquadx.hydev.org",
    "RIN-NET": "aqua.naominet.live",
    "Yuzu-net": "aime.yuzunet.cn",
    "Custom": "",
  };

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _dnsDefaultController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final ini = await IniReader.load(widget.projectPath);
      if (ini == null) return;

      final dns = ini.section('dns');
      if (dns != null) {
        final val = dns.getString('default');
        _dnsDefaultController.text = val;
        _selectedDns = "Custom";
        _dnsPresets.forEach((name, preset) {
          if (val == preset && name != "Custom") _selectedDns = name;
        });
      }

      final netenv = ini.section('netenv');
      if (netenv != null) {
        _netenvEnable = netenv.getBool('enable');
        _netenvAddrSuffix = netenv.getInt('addrSuffix', 11).toDouble();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, Map<String, String>> getConfigData() {
    return {
      'dns': {
        'default': _dnsDefaultController.text,
      },
      'netenv': {
        'enable': _netenvEnable ? '1' : '0',
        'addrSuffix': _netenvAddrSuffix.toInt().toString(),
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    const searchTargets = [
      "Network Settings", "Server Address", "Status",
      "Enable NetEnv", "IP Suffix"
    ];
    final kw = widget.searchKeyword;
    final hasMatch = kw.isEmpty ||
        searchTargets.any((l) => l.toLowerCase().contains(kw.toLowerCase()));
    if (!hasMatch) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Network Settings",
          icon: FluentIcons.network_tower,
          visible: kw.isEmpty,
        ),
        SettingItem(
          label: "Server Address",
          searchKeyword: kw,
          child: Row(
            children: [
              SizedBox(
                width: 150,
                child: ComboBox<String>(
                  value: _selectedDns,
                  items: _dnsPresets.keys
                      .map((e) => ComboBoxItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedDns = v!;
                    if (v != "Custom") {
                      _dnsDefaultController.text = _dnsPresets[v]!;
                    }
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextBox(
                  controller: _dnsDefaultController,
                  placeholder: "127.0.0.1",
                  enabled: _selectedDns == "Custom",
                ),
              ),
            ],
          ),
        ),
        SettingItem(
          label: "Status",
          searchKeyword: kw,
          child: ToggleSwitch(
            checked: _netenvEnable,
            onChanged: (v) => setState(() => _netenvEnable = v),
            content: const Text("Enable NetEnv"),
          ),
        ),
        SettingItem(
          label: "IP Suffix: ${_netenvAddrSuffix.toInt()}",
          searchKeyword: kw,
          child: Slider(
            value: _netenvAddrSuffix,
            min: 2,
            max: 254,
            onChanged:
                _netenvEnable ? (v) => setState(() => _netenvAddrSuffix = v) : null,
          ),
        ),
      ],
    );
  }
}
