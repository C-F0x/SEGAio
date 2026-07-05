import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import '../shared/ini_reader.dart';
import '../shared/vk.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/setting_item.dart';

class DeviceConfig extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  final bool isGlobalRelative;

  const DeviceConfig({
    super.key,
    required this.projectPath,
    this.searchKeyword = "",
    required this.isGlobalRelative,
  });

  @override
  State<DeviceConfig> createState() => DeviceConfigState();
}

class DeviceConfigState extends State<DeviceConfig> {
  final TextEditingController _aimePathController = TextEditingController();
  final TextEditingController _scanController = TextEditingController();
  bool _isLoading = true;
  bool _aimeEnable = false;
  bool _vfdEnable = false;
  bool _highBaud = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _aimePathController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final ini = await IniReader.load(widget.projectPath);
      if (ini == null) return;
      final aime = ini.section('aime');
      if (aime != null) {
        _aimeEnable = aime.getBool('enable');
        _highBaud = aime.getBool('highBaud');
        _aimePathController.text = aime.getString('aimePath');
        _scanController.text = aime.getString('scan');
      }
      final vfd = ini.section('vfd');
      if (vfd != null) {
        _vfdEnable = vfd.getBool('enable');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateTxtDialog() {
    final nameController = TextEditingController();
    final cardController = TextEditingController();
    final pathController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final bool isCardValid =
              RegExp(r'^\d{20}$').hasMatch(cardController.text);
          final bool isReady = nameController.text.isNotEmpty &&
              isCardValid &&
              pathController.text.isNotEmpty;

          return ContentDialog(
            title: const Text('Create Card File'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InfoLabel(
                  label: 'FILE NAME',
                  child: TextBox(
                    controller: nameController,
                    placeholder: 'e.g. card',
                    suffix: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text('.txt',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                InfoLabel(
                  label: 'CARD NUMBER (20 DIGITS)',
                  child: TextBox(
                    controller: cardController,
                    placeholder: '20-digit numeric only',
                    maxLength: 20,
                    unfocusedColor: !isCardValid && cardController.text.isNotEmpty
                        ? Colors.red
                        : null,
                    suffix: !isCardValid && cardController.text.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(FluentIcons.error,
                                color: Colors.red, size: 14),
                          )
                        : null,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                InfoLabel(
                  label: 'SAVE TO',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextBox(
                          controller: pathController,
                          placeholder: 'Select target folder',
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Button(
                        child: const Icon(FluentIcons.folder_search),
                        onPressed: () async {
                          String? result =
                              await FilePicker.platform.getDirectoryPath();
                          if (result != null) {
                            setDialogState(() {
                              pathController.text = widget.isGlobalRelative
                                  ? p.relative(result, from: widget.projectPath)
                                  : p.normalize(result);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Button(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              FilledButton(
                onPressed: isReady
                    ? () async {
                        try {
                          String baseDir = pathController.text;
                          if (widget.isGlobalRelative) {
                            baseDir = p.normalize(
                                p.join(widget.projectPath, pathController.text));
                          }
                          final fullPath =
                              p.join(baseDir, "${nameController.text}.txt");
                          final file = File(fullPath);
                          if (!await file.parent.exists()) {
                            await file.parent.create(recursive: true);
                          }
                          await file.writeAsString(cardController.text);

                          setState(() {
                            _aimePathController.text = widget.isGlobalRelative
                                ? p.relative(fullPath, from: widget.projectPath)
                                : fullPath;
                          });
                          if (context.mounted) Navigator.pop(context);
                        } catch (_) {}
                      }
                    : null,
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, Map<String, String>> getConfigData() {
    return {
      'aime': {
        'enable': _aimeEnable ? '1' : '0',
        'aimePath': _aimePathController.text,
        'highBaud': _highBaud ? '1' : '0',
        'scan': _scanController.text,
      },
      'vfd': {
        'enable': _vfdEnable ? '1' : '0',
      },
    };
  }

  Widget _buildKeyDisplay(String name) {
    final theme = FluentTheme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.accentColor.withOpacity(0.3)),
      ),
      child: Text(name,
          style: TextStyle(
              color: theme.accentColor, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    const labels = [
      "Device settings", "Enable Aime Reader", "High Baud Rate",
      "Aime Path", "Scan Key", "Enable VFD"
    ];
    final kw = widget.searchKeyword;
    final hasMatch = kw.isEmpty ||
        labels.any((l) => l.toLowerCase().contains(kw.toLowerCase()));
    if (!hasMatch) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Device settings",
          icon: FluentIcons.business_card,
          visible: kw.isEmpty,
        ),
        SwitchSettingItem(
          label: "Enable Aime Reader",
          value: _aimeEnable,
          onChanged: (v) => setState(() => _aimeEnable = v),
          searchKeyword: kw,
        ),
        SwitchSettingItem(
          label: "High Baud Rate",
          value: _highBaud,
          onChanged: (v) => setState(() => _highBaud = v),
          searchKeyword: kw,
        ),
        SettingItem(
          label: "Aime Path",
          searchKeyword: kw,
          child: Row(children: [
            Expanded(child: TextBox(controller: _aimePathController)),
            const SizedBox(width: 8),
            Button(
              child: const Icon(FluentIcons.add),
              onPressed: _showCreateTxtDialog,
            ),
            const SizedBox(width: 8),
            Button(
              child: const Icon(FluentIcons.file_system),
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();
                if (result != null) {
                  setState(() {
                    String pickedPath = result.files.single.path!;
                    _aimePathController.text = widget.isGlobalRelative
                        ? p.relative(pickedPath, from: widget.projectPath)
                        : p.normalize(pickedPath);
                  });
                }
              },
            ),
          ]),
        ),
        SettingItem(
          label: "Scan Key",
          searchKeyword: kw,
          child: Row(children: [
            Expanded(
              child: TextBox(
                controller: _scanController,
                readOnly: true,
              ),
            ),
            _buildKeyDisplay(VKMapper.parse(_scanController.text)),
            Button(
              child: const Icon(FluentIcons.keyboard_classic),
              onPressed: () => VKMapper.scan(context, (hex) {
                setState(() => _scanController.text = hex);
              }),
            ),
          ]),
        ),
        SwitchSettingItem(
          label: "Enable VFD",
          value: _vfdEnable,
          onChanged: (v) => setState(() => _vfdEnable = v),
          searchKeyword: kw,
        ),
      ],
    );
  }
}
