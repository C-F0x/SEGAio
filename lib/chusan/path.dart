import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import '../shared/ini_reader.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/setting_item.dart';

class PathConfig extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  final bool isGlobalRelative;

  const PathConfig({
    super.key,
    required this.projectPath,
    this.searchKeyword = "",
    required this.isGlobalRelative,
  });

  @override
  State<PathConfig> createState() => PathConfigState();
}

class PathConfigState extends State<PathConfig> {
  final TextEditingController _amfsController = TextEditingController();
  final TextEditingController _optionController = TextEditingController();
  final TextEditingController _appdataController = TextEditingController();

  bool _isLoading = true;
  String? _amfsError, _optionError;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _amfsController.dispose();
    _optionController.dispose();
    _appdataController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final ini = await IniReader.load(widget.projectPath);
      if (ini != null) {
        final vfs = ini.section('vfs');
        if (vfs != null) {
          _amfsController.text = vfs.getString('amfs');
          _optionController.text = vfs.getString('option');
          _appdataController.text = vfs.getString('appdata');
        }
      }
      _validateAll();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _validateAll() {
    setState(() {
      _amfsError = _checkDirContent(_amfsController.text, ['ICF1', 'ICF2']);
      _optionError = _checkDirContent(_optionController.text, ['A001']);
    });
  }

  String? _checkDirContent(String pathStr, List<String> items) {
    if (pathStr.isEmpty) return "Can't be Blank";
    String fullPath = pathStr;
    if (!p.isAbsolute(pathStr)) {
      fullPath = p.normalize(p.join(widget.projectPath, pathStr));
    }
    final dir = Directory(fullPath);
    if (!dir.existsSync()) return "Directory does not exist";
    try {
      final entities =
          dir.listSync().map((e) => p.basename(e.path).toLowerCase()).toList();
      for (var item in items) {
        if (!entities.contains(item.toLowerCase())) {
          return "Core folders/files not found: $item";
        }
      }
    } catch (e) {
      return "Read failed";
    }
    return null;
  }

  String _formatPath(String pickedPath) {
    if (widget.isGlobalRelative) {
      return p.relative(pickedPath, from: widget.projectPath);
    } else {
      return p.normalize(pickedPath);
    }
  }

  Map<String, Map<String, String>> getConfigData() {
    return {
      'vfs': {
        'amfs': _amfsController.text,
        'option': _optionController.text,
        'appdata': _appdataController.text,
      },
    };
  }

  Widget _buildFolderPicker(TextEditingController controller) {
    return Button(
      child: const Icon(FluentIcons.folder_search),
      onPressed: () async {
        String? selected = await FilePicker.platform.getDirectoryPath();
        if (selected != null) {
          controller.text = _formatPath(selected);
          _validateAll();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    const searchTargets = [
      "Path settings",
      "AMFS Path",
      "Option Path",
      "AppData Path",
    ];
    final kw = widget.searchKeyword;
    final hasMatch = kw.isEmpty ||
        searchTargets.any((l) => l.toLowerCase().contains(kw.toLowerCase()));
    if (!hasMatch) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Path settings",
          icon: FluentIcons.folder_open,
          visible: kw.isEmpty,
        ),
        SettingItem(
          label: "AMFS Path",
          searchKeyword: kw,
          error: _amfsError,
          child: Row(children: [
            Expanded(
                child: TextBox(
                    controller: _amfsController,
                    onChanged: (_) => _validateAll())),
            const SizedBox(width: 8),
            _buildFolderPicker(_amfsController),
          ]),
        ),
        SettingItem(
          label: "Option Path",
          searchKeyword: kw,
          error: _optionError,
          child: Row(children: [
            Expanded(
                child: TextBox(
                    controller: _optionController,
                    onChanged: (_) => _validateAll())),
            const SizedBox(width: 8),
            _buildFolderPicker(_optionController),
          ]),
        ),
        SettingItem(
          label: "AppData Path",
          searchKeyword: kw,
          child: Row(children: [
            Expanded(
                child: TextBox(
                    controller: _appdataController,
                    onChanged: (_) => _validateAll())),
            const SizedBox(width: 8),
            _buildFolderPicker(_appdataController),
          ]),
        ),
      ],
    );
  }
}
