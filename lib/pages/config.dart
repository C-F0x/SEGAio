import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../shared/project.dart';
import '../shared/database.dart';
import '../shared/ini_reader.dart';
import '../services/segatools_updater.dart';
import 'modify.dart';
import 'dialogs.dart';
import 'import_dialog.dart';

class ConfigPage extends StatefulWidget {
  final String title;
  final Function(Project)? onProjectCreated;

  const ConfigPage({
    super.key,
    required this.title,
    this.onProjectCreated,
  });

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  List<Project> _projects = [];
  Project? _selectedProject;
  bool _isSaving = false;
  String _searchKeyword = "";
  final GlobalKey<ModifyPageState> _modifyKey = GlobalKey<ModifyPageState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLoad() async {
    final loaded = await JsonDbService.loadProjects();
    if (!mounted) return;
    setState(() => _projects = loaded);
  }

  Future<void> _handleGlobalSave() async {
    setState(() => _isSaving = true);
    try {
      final bool ok = await _modifyKey.currentState?.triggerSaveAll() ?? false;
      if (mounted && ok) {
        displayInfoBar(context, builder: (c, close) => const InfoBar(
          title: Text('Saved'),
          content: Text('Synced'),
          severity: InfoBarSeverity.success,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleToggleRelative(Project project) async {
    final toRelative = !project.isGlobalRelative;
    final iniPath = p.join(project.path, 'segatools.ini');
    final iniFile = File(iniPath);

    if (await iniFile.exists()) {
      final ini = await IniReader.load(project.path);
      if (ini != null) {
        final buffer = StringBuffer();
        for (final section in ini.sections) {
          buffer.writeln('[${section.name}]');
          for (final entry in section.values.entries) {
            var value = entry.value;
            final converted = _convertPath(value, project.path, toRelative);
            if (converted != value) {
              debugPrint('[Toggle] ${section.name}.${entry.key}: $value → $converted');
              value = converted;
            }
            buffer.writeln('${entry.key}=$value');
          }
          buffer.writeln();
        }
        await iniFile.writeAsString(buffer.toString().trimRight() + '\n');
      }
    }

    project.isGlobalRelative = toRelative;
    await JsonDbService.saveProjects(_projects);
    if (mounted) setState(() {});
  }

  /// 将路径在绝对/相对之间转换。非路径值原样返回。
  String _convertPath(String value, String projectPath, bool toRelative) {
    if (toRelative) {
      // 绝对 → 相对
      if (p.isAbsolute(value)) {
        return p.relative(value, from: projectPath);
      }
    } else {
      // 相对 → 绝对
      if (!p.isAbsolute(value) &&
          (value.contains('\\') || value.contains('/'))) {
        final abs = p.normalize(p.join(projectPath, value));
        if (abs != value) return abs;
      }
    }
    return value;
  }

  Future<void> _handleResetSetup(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('Reset to Default'),
        content: const Text('This will OVERWRITE segatools.ini with the default template. Continue?'),
        actions: [
          Button(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx, false)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Overwrite')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final template = await SegatoolsUpdater.getTemplateIni(project.type);
      if (template == null) throw Exception('Template not found in segatools.zip for ${project.type}');
      final iniFile = File(p.join(project.path, 'segatools.ini'));
      await iniFile.writeAsString(template);
      if (mounted) {
        displayInfoBar(context, builder: (c, close) => const InfoBar(
          title: Text('Reset'),
          content: Text('segatools.ini has been reset to default template.'),
          severity: InfoBarSeverity.success,
        ));
        _modifyKey.currentState?.reloadData();
      }
    } catch (e) {
      if (mounted) displayInfoBar(context, builder: (c, close) => InfoBar(
        title: Text('Failed'), content: Text(e.toString()), severity: InfoBarSeverity.error));
    }
  }

  Future<void> _openFolder(String path) async {
    final Uri uri = Uri.file(path);
    if (!await launchUrl(uri)) {
      if (mounted) {
        displayInfoBar(context, builder: (c, close) => const InfoBar(
          title: Text('Unable to open the path'),
          severity: InfoBarSeverity.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    if (_selectedProject != null) {
      return ScaffoldPage(
        header: PageHeader(
          leading: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: IconButton(
              icon: const Icon(FluentIcons.back),
              onPressed: () => setState(() {
                _selectedProject = null;
                _searchKeyword = "";
                _searchController.clear();
              }),
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _selectedProject!.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200, minWidth: 80),
                  child: TextBox(
                    controller: _searchController,
                    placeholder: 'Search...',
                    suffix: _searchKeyword.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(FluentIcons.search, size: 14))
                        : IconButton(
                            icon: const Icon(FluentIcons.clear, size: 10),
                            onPressed: () => setState(() {
                              _searchController.clear();
                              _searchKeyword = "";
                            }),
                          ),
                    onChanged: (v) => setState(() => _searchKeyword = v),
                  ),
                ),
              ),
            ],
          ),
          commandBar: CommandBar(
            mainAxisAlignment: MainAxisAlignment.end,
            primaryItems: [
              CommandBarButton(
                icon: const Icon(FluentIcons.refresh),
                label: const Text('RELOAD'),
                onPressed: () => _modifyKey.currentState?.reloadData(),
              ),
              const CommandBarSeparator(),
              CommandBarButton(
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: ProgressRing(strokeWidth: 2))
                    : const Icon(FluentIcons.save),
                label: const Text('SAVE'),
                onPressed: _isSaving ? null : _handleGlobalSave,
              ),
            ],
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(8),
                  child: ModifyPage(
                    key: _modifyKey,
                    projectPath: _selectedProject!.path,
                    configData: _selectedProject!.toJson(),
                    searchKeyword: _searchKeyword,
                    isGlobalRelative: _selectedProject!.isGlobalRelative,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildBottomBar(_selectedProject!, theme),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    }

    return ScaffoldPage(
      header: PageHeader(
        title: Text(widget.title),
        commandBar: FilledButton(
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FluentIcons.add),
              SizedBox(width: 8),
              Text('Create'),
            ],
          ),
          onPressed: () => ImportDialog.show(
            context: context,
            currentProjects: _projects,
            onSuccess: (newProject) async {
              setState(() => _projects.add(newProject));
              await JsonDbService.saveProjects(_projects);
              if (widget.onProjectCreated != null) {
                widget.onProjectCreated!(newProject);
              }
            },
          ),
        ),
      ),
      content: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        itemCount: _projects.length,
        itemBuilder: (context, index) {
          final item = _projects[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Card(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(8),
              child: ListTile(
                onPressed: () => setState(() => _selectedProject = item),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${item.type.toUpperCase()} | ${item.path}",
                  style: theme.typography.caption,
                ),
                trailing: SizedBox(
                  width: 32,
                  child: Builder(
                    builder: (context) {
                      final flyoutController = FlyoutController();
                      return FlyoutTarget(
                        controller: flyoutController,
                        child: IconButton(
                          icon: const Icon(FluentIcons.more, size: 16),
                          onPressed: () {
                            flyoutController.showFlyout<void>(
                              builder: (context) => MenuFlyout(
                                items: [
                                  MenuFlyoutItem(
                                    text: const Text('删除'),
                                    onPressed: () {
                                      ProjectDialogs.confirmDelete(
                                        context: context,
                                        project: item,
                                        onConfirm: (deleteIni) async {
                                          if (deleteIni) {
                                            final iniFile = File(p.join(item.path, 'segatools.ini'));
                                            if (await iniFile.exists()) await iniFile.delete();
                                          }
                                          setState(() => _projects.removeWhere((p) => p.id == item.id));
                                          await JsonDbService.saveProjects(_projects);
                                        },
                                      );
                                    },
                                  ),
                                  MenuFlyoutItem(
                                    text: const Text('重设为默认值'),
                                    onPressed: () {
                                      _handleResetSetup(item);
                                    },
                                  ),
                                  MenuFlyoutItem(
                                    text: Text(item.isGlobalRelative ? '切换为绝对路径' : '切换为相对路径'),
                                    onPressed: () {
                                      _handleToggleRelative(item);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(Project project, FluentThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Tooltip(
              message: 'Click to Open With File Explorer',
              child: GestureDetector(
                onTap: () => _openFolder(project.path),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons.folder_open,
                        size: 14,
                        color: theme.typography.body?.color
                            ?.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          project.path,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.accentColor,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Text(
            "Created at : ${project.createdAt}",
            style: TextStyle(
              fontSize: 12,
              color: theme.typography.body?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
