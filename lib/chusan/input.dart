import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as p;
import '../shared/ini_reader.dart';
import '../shared/vk.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/setting_item.dart';

class InputConfig extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;

  const InputConfig({
    super.key,
    required this.projectPath,
    this.searchKeyword = "",
  });

  @override
  State<InputConfig> createState() => InputConfigState();
}

class InputConfigState extends State<InputConfig> {
  final Map<String, TextEditingController> _io3Controllers = {
    'test': TextEditingController(),
    'service': TextEditingController(),
    'coin': TextEditingController(),
    'ir': TextEditingController(),
  };

  final Map<String, TextEditingController> _irControllers =
      Map.fromIterable(List.generate(6, (i) => 'ir${i + 1}'),
          value: (_) => TextEditingController());

  final Map<String, TextEditingController> _sliderControllers =
      Map.fromIterable(List.generate(32, (i) => 'cell${i + 1}'),
          value: (_) => TextEditingController());

  bool _isLoading = true;
  bool _keyboardBind = false;
  bool _sliderEmulation = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    for (final c in _io3Controllers.values) {
      c.dispose();
    }
    for (final c in _irControllers.values) {
      c.dispose();
    }
    for (final c in _sliderControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final ini = await IniReader.load(widget.projectPath);
      if (ini == null) return;

      final io3 = ini.section('io3');
      if (io3 != null) {
        for (final e in _io3Controllers.entries) {
          final val = io3.getString(e.key);
          if (val.isNotEmpty) e.value.text = val;
        }
      }

      final ir = ini.section('ir');
      if (ir != null) {
        for (final e in _irControllers.entries) {
          final val = ir.getString(e.key);
          if (val.isNotEmpty) {
            e.value.text = val;
            if (val != "0x00") _keyboardBind = true;
          }
        }
      }

      final slider = ini.section('slider');
      if (slider != null) {
        _sliderEmulation = slider.getBool('enable');
        for (final e in _sliderControllers.entries) {
          final val = slider.getString(e.key);
          if (val.isNotEmpty) {
            e.value.text = val;
            if (val != "0x00") _keyboardBind = true;
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, Map<String, String>> getConfigData() {
    final result = <String, Map<String, String>>{};
    result['io3'] =
        _io3Controllers.map((k, v) => MapEntry(k, v.text));
    if (_keyboardBind) {
      result['ir'] = _irControllers.map((k, v) => MapEntry(k, v.text));
    }
    final sliderData = <String, String>{
      'enable': _sliderEmulation ? '1' : '0',
    };
    if (_keyboardBind) {
      sliderData.addAll(
          _sliderControllers.map((k, v) => MapEntry(k, v.text)));
    }
    result['slider'] = sliderData;
    return result;
  }

  Widget _buildClickableBlock({
    required String label,
    required TextEditingController controller,
    required Color activeColor,
  }) {
    String keyName = VKMapper.parse(controller.text);
    bool hasKey = controller.text.isNotEmpty && controller.text != "0x00";
    final theme = FluentTheme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => VKMapper.scan(context, (hex) {
          setState(() => controller.text = hex);
        }),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: hasKey
                  ? activeColor
                  : theme.micaBackgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: hasKey
                    ? theme.accentColor
                    : theme.resources.surfaceStrokeColorDefault,
                width: 0.5,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: hasKey ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                    if (hasKey)
                      FittedBox(
                        fit: BoxFit.contain,
                        child: Text(
                          keyName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIo3Item(
      String label, TextEditingController controller) {
    String keyName = VKMapper.parse(controller.text);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label)),
          Expanded(
            flex: 7,
            child: Row(
              children: [
                Expanded(
                    child: TextBox(controller: controller, readOnly: true)),
                const SizedBox(width: 8),
                Container(
                  width: 80,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: FluentTheme.of(context)
                          .resources
                          .surfaceStrokeColorDefault,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(keyName,
                      style: TextStyle(
                          color: FluentTheme.of(context).accentColor,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Button(
                  child: const Icon(FluentIcons.keyboard_classic),
                  onPressed: () => VKMapper.scan(context, (hex) {
                    setState(() => controller.text = hex);
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    const searchTargets = [
      "Input", "io3", "test", "service", "coin",
      "ir", "slider", "cell", "air", "emulation", "keyboard"
    ];
    final kw = widget.searchKeyword;
    final hasMatch = kw.isEmpty ||
        searchTargets.any((t) => t.toLowerCase().contains(kw.toLowerCase()));
    if (!hasMatch) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Input settings",
          icon: FluentIcons.button_control,
          visible: kw.isEmpty,
        ),
        ..._io3Controllers.entries
            .where((e) =>
                kw.isEmpty || e.key.toLowerCase().contains(kw.toLowerCase()))
            .map((e) => _buildIo3Item(e.key.toUpperCase(), e.value)),
        const SizedBox(height: 16),
        Row(
          children: [
            ToggleSwitch(
              checked: _sliderEmulation,
              onChanged: (v) => setState(() => _sliderEmulation = v),
              content: const Text("Slider Emulation"),
            ),
            const SizedBox(width: 24),
            ToggleSwitch(
              checked: _keyboardBind,
              onChanged: (v) {
                setState(() {
                  _keyboardBind = v;
                  if (!v) {
                    for (var c in _irControllers.values) {
                      c.clear();
                    }
                    for (var c in _sliderControllers.values) {
                      c.clear();
                    }
                  }
                });
              },
              content: const Text("KeyBoard Bind"),
            ),
          ],
        ),
        if (_keyboardBind)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 15,
                  child: Column(
                    children: [
                      SectionHeader(
                          title: "[ir]",
                          icon: FluentIcons.hands_free,
                          visible: kw.isEmpty),
                      SizedBox(
                        height: 360,
                        child: Column(
                          children: List.generate(6, (index) {
                            int num = 6 - index;
                            return _buildClickableBlock(
                              label: "AIR $num",
                              controller: _irControllers['ir$num']!,
                              activeColor:
                                  const Color(0xFF00FFFF).withOpacity(0.6),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 85,
                  child: Column(
                    children: [
                      SectionHeader(
                          title: "[slider]",
                          icon: FluentIcons.touch,
                          visible: kw.isEmpty),
                      SizedBox(
                        height: 360,
                        child: Column(
                          children: List.generate(2, (row) {
                            return Expanded(
                              child: Row(
                                children: List.generate(16, (col) {
                                  int cellNum =
                                      (15 - col) * 2 + (row + 1);
                                  return _buildClickableBlock(
                                    label: "$cellNum",
                                    controller:
                                        _sliderControllers['cell$cellNum']!,
                                    activeColor: const Color(0xFFFFBF00)
                                        .withOpacity(0.6),
                                  );
                                }),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
