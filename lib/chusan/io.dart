import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import '../shared/ini_reader.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/setting_item.dart';

class IoConfig extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  final bool isGlobalRelative;

  const IoConfig({
    super.key,
    required this.projectPath,
    this.searchKeyword = "",
    required this.isGlobalRelative,
  });

  @override
  State<IoConfig> createState() => IoConfigState();
}

class IoConfigState extends State<IoConfig> {
  final TextEditingController _aimeioPathController = TextEditingController();
  final TextEditingController _chuniioPathController = TextEditingController();
  final TextEditingController _chuniioPath32Controller =
      TextEditingController();
  final TextEditingController _chuniioPath64Controller =
      TextEditingController();

  bool _isLoading = true;
  bool _isDualDll = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _aimeioPathController.dispose();
    _chuniioPathController.dispose();
    _chuniioPath32Controller.dispose();
    _chuniioPath64Controller.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final ini = await IniReader.load(widget.projectPath);
      if (ini == null) return;

      final aimeio = ini.section('aimeio');
      if (aimeio != null) {
        _aimeioPathController.text = aimeio.getString('path');
      }

      final chuniio = ini.section('chuniio');
      if (chuniio != null) {
        final pathVal = chuniio.getString('path');
        final path32 = chuniio.getString('path32');
        final path64 = chuniio.getString('path64');

        if (pathVal.isNotEmpty) {
          _chuniioPathController.text = pathVal;
        }
        if (path32.isNotEmpty) {
          _chuniioPath32Controller.text = path32;
        }
        if (path64.isNotEmpty) {
          _chuniioPath64Controller.text = path64;
        }
        _isDualDll = path32.isNotEmpty || path64.isNotEmpty;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, Map<String, String>> getConfigData() {
    final Map<String, String> chuniioData = {};
    if (_isDualDll) {
      chuniioData['path32'] = _chuniioPath32Controller.text;
      chuniioData['path64'] = _chuniioPath64Controller.text;
    } else {
      chuniioData['path'] = _chuniioPathController.text;
    }
    return {
      'aimeio': {'path': _aimeioPathController.text},
      'chuniio': chuniioData,
    };
  }

  Future<void> _pickDll(TextEditingController controller) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dll'],
    );
    if (result != null) {
      setState(() {
        String pickedPath = result.files.single.path!;
        controller.text = widget.isGlobalRelative
            ? p.relative(pickedPath, from: widget.projectPath)
            : p.normalize(pickedPath);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    const labels = [
      "Custom IO settings", "AimeIO DLL Path", "Dual DLL Mode",
      "chu2to3 DLL Path", "x86 DLL Path", "x64 DLL Path"
    ];
    final kw = widget.searchKeyword;
    final hasMatch = kw.isEmpty ||
        labels.any((l) => l.toLowerCase().contains(kw.toLowerCase()));
    if (!hasMatch) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Custom IO settings",
          icon: FluentIcons.game,
          visible: kw.isEmpty,
        ),
        SettingItem(
          label: "AimeIO DLL Path [aimeio]",
          searchKeyword: kw,
          child: Row(children: [
            Expanded(
                child: TextBox(
                    controller: _aimeioPathController,
                    placeholder: "aimeio.dll")),
            const SizedBox(width: 8),
            Button(
              child: const Icon(FluentIcons.file_system),
              onPressed: () => _pickDll(_aimeioPathController),
            ),
          ]),
        ),
        SettingItem(
          label: "Dual DLL Mode",
          searchKeyword: kw,
          child: ToggleSwitch(
            checked: _isDualDll,
            onChanged: (v) => setState(() => _isDualDll = v),
            content: Text(_isDualDll ? "Dual DLL" : "Single DLL"),
          ),
        ),
        if (!_isDualDll)
          SettingItem(
            label: "chu2to3 Chuniio DLL Path",
            searchKeyword: kw,
            child: Row(children: [
              Expanded(
                  child: TextBox(
                      controller: _chuniioPathController,
                      placeholder: "chuniio.dll")),
              const SizedBox(width: 8),
              Button(
                child: const Icon(FluentIcons.file_system),
                onPressed: () => _pickDll(_chuniioPathController),
              ),
            ]),
          )
        else ...[
          SettingItem(
            label: "x86 Chuniio DLL Path",
            searchKeyword: kw,
            child: Row(children: [
              Expanded(
                  child: TextBox(
                      controller: _chuniioPath32Controller,
                      placeholder: "chuniio_x86.dll")),
              const SizedBox(width: 8),
              Button(
                child: const Icon(FluentIcons.file_system),
                onPressed: () => _pickDll(_chuniioPath32Controller),
              ),
            ]),
          ),
          SettingItem(
            label: "x64 Chuniio DLL Path",
            searchKeyword: kw,
            child: Row(children: [
              Expanded(
                  child: TextBox(
                      controller: _chuniioPath64Controller,
                      placeholder: "chuniio_x64.dll")),
              const SizedBox(width: 8),
              Button(
                child: const Icon(FluentIcons.file_system),
                onPressed: () => _pickDll(_chuniioPath64Controller),
              ),
            ]),
          ),
        ],
      ],
    );
  }
}
