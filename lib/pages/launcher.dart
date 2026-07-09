import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as p;
import '../shared/project.dart';
import '../shared/database.dart';
import '../shared/launch_scripts.dart';

class LauncherPage extends StatefulWidget {
  final Function(int tabIndex)? onNavigate;
  const LauncherPage({super.key, this.onNavigate});

  @override
  State<LauncherPage> createState() => LauncherPageState();
}

class LauncherPageState extends State<LauncherPage> {
  List<Project> _projects = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final loaded = await JsonDbService.loadProjects();
    if (!mounted) return;
    setState(() => _projects = loaded);
  }

  Future<void> _launchGame(Project project) async {
    final batContent = LaunchScripts.getBatContent(project.type, project.path);
    final batPath = p.join(project.path, 'launch.bat');
    await File(batPath).writeAsString(batContent);
    await Process.start('cmd.exe', ['/c', batPath],
      workingDirectory: project.path,
      mode: ProcessStartMode.normal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      header: PageHeader(title: const Text('Launcher')),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      content: _projects.isEmpty
          ? Center(
              child: Text('No configs found. Create one in Config Management first.',
                  style: TextStyle(color: theme.typography.body?.color?.withOpacity(0.6))))
          : ListView.builder(
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                final project = _projects[index];
                final batContent = LaunchScripts.getBatContent(project.type, project.path);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text('${project.name} (${project.type})',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: IconButton(
                            icon: const Icon(FluentIcons.send, size: 18),
                            onPressed: () => _launchGame(project),
                          ),
                        ),
                        const Divider(size: 1),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            batContent.replaceAll('\r\n', '\n'),
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
