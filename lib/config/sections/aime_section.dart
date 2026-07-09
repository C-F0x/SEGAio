import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import '../../shared/ini_reader.dart';
import '../../shared/vk.dart';
import '../section_widget.dart';
import '../setting_field.dart';

class AimeSection extends StatefulWidget {
  final String projectPath;
  final String searchKeyword;
  final bool isGlobalRelative;
  const AimeSection({super.key, required this.projectPath, this.searchKeyword = '', required this.isGlobalRelative});
  @override
  State<AimeSection> createState() => _AimeSectionState();
}

class _AimeSectionState extends State<AimeSection> implements ConfigSection {
  final _pathCtrl = TextEditingController();
  final _scanCtrl = TextEditingController();
  bool _loading = true, _enable = false, _highBaud = false;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _pathCtrl.dispose(); _scanCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ini = await IniReader.load(widget.projectPath);
      final aime = ini?.section('aime');
      if (aime != null) {
        _enable = aime.getBool('enable');
        _highBaud = aime.getBool('highBaud');
        _pathCtrl.text = aime.getString('aimePath');
        _scanCtrl.text = aime.getString('scan');
      }
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  void reloadData() => _load();

  void _showCreateCardDialog() {
    final nameCtrl = TextEditingController();
    final cardCtrl = TextEditingController();
    final pathCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) {
        final valid = RegExp(r'^\d{20}$').hasMatch(cardCtrl.text);
        final ready = nameCtrl.text.isNotEmpty && valid && pathCtrl.text.isNotEmpty;
        return ContentDialog(
          title: const Text('Create Card File'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            InfoLabel(label: 'FILE NAME', child: TextBox(controller: nameCtrl, placeholder: 'e.g. card',
              suffix: const Padding(padding: EdgeInsets.only(right: 8), child: Text('.txt', style: TextStyle(color: Colors.grey))))),
            const SizedBox(height: 12),
            InfoLabel(label: 'CARD NUMBER (20 DIGITS)', child: TextBox(controller: cardCtrl, placeholder: '20-digit numeric',
              maxLength: 20, onChanged: (_) => setSt(() {}))),
            const SizedBox(height: 12),
            InfoLabel(label: 'SAVE TO', child: Row(children: [
              Expanded(child: TextBox(controller: pathCtrl, placeholder: 'Select folder', onChanged: (_) => setSt(() {}))),
              const SizedBox(width: 8),
              Button(child: const Icon(FluentIcons.folder_search), onPressed: () async {
                final r = await FilePicker.getDirectoryPath();
                if (r != null) setSt(() => pathCtrl.text = widget.isGlobalRelative ? p.relative(r, from: widget.projectPath) : p.normalize(r));
              }),
            ])),
          ]),
          actions: [
            Button(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
            FilledButton(onPressed: ready ? () async {
              final base = widget.isGlobalRelative ? p.normalize(p.join(widget.projectPath, pathCtrl.text)) : pathCtrl.text;
              final fp = p.join(base, '${nameCtrl.text}.txt');
              await File(fp).parent.create(recursive: true);
              await File(fp).writeAsString(cardCtrl.text);
              setState(() => _pathCtrl.text = widget.isGlobalRelative ? p.relative(fp, from: widget.projectPath) : fp);
              if (ctx.mounted) Navigator.pop(ctx);
            } : null, child: const Text('Create')),
          ],
        );
      },
    ));
  }

  @override
  Map<String, Map<String, String>> getConfigData() => {
    'aime': { 'enable': _enable ? '1' : '0', 'aimePath': _pathCtrl.text, 'highBaud': _highBaud ? '1' : '0', 'scan': _scanCtrl.text },
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final kw = widget.searchKeyword;
    if (kw.isNotEmpty && !'Aime Card Reader'.toLowerCase().contains(kw.toLowerCase()) && !'Scan Key'.toLowerCase().contains(kw.toLowerCase())) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SwitchField(section: 'aime', field: 'enable', label: 'Enable Aime Reader', value: _enable, onChanged: (v) => setState(() => _enable = v), searchKeyword: kw),
      SwitchField(section: 'aime', field: 'highBaud', label: 'High Baud Rate', value: _highBaud, onChanged: (v) => setState(() => _highBaud = v), searchKeyword: kw),
      SettingField(section: 'aime', field: 'aimePath', label: 'Aime Card Path', searchKeyword: kw,
        child: Row(children: [
          Expanded(child: TextBox(controller: _pathCtrl)),
          const SizedBox(width: 4), Button(child: const Icon(FluentIcons.add), onPressed: _showCreateCardDialog),
          const SizedBox(width: 4), Button(child: const Icon(FluentIcons.file_system), onPressed: () async {
            final r = await FilePicker.pickFiles();
            if (r != null) setState(() => _pathCtrl.text = widget.isGlobalRelative ? p.relative(r.files.single.path!, from: widget.projectPath) : p.normalize(r.files.single.path!));
          }),
        ]),
      ),
      SettingField(section: 'aime', field: 'scan', label: 'Scan Key', searchKeyword: kw,
        child: Row(children: [
          Expanded(child: TextBox(controller: _scanCtrl, readOnly: true)),
          _KeyBadge(VKMapper.parse(_scanCtrl.text)),
          Button(child: const Icon(FluentIcons.keyboard_classic), onPressed: () => VKMapper.scan(context, (hex) => setState(() => _scanCtrl.text = hex))),
        ]),
      ),
    ]);
  }
}

class _KeyBadge extends StatelessWidget {
  final String name;
  const _KeyBadge(this.name);
  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    return Container(margin: const EdgeInsets.symmetric(horizontal: 8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: t.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: t.accentColor.withOpacity(0.3))),
      child: Text(name, style: TextStyle(color: t.accentColor, fontWeight: FontWeight.bold)));
  }
}
