import 'dart:async';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import '../shared/app_paths.dart';
import '../services/segatools_updater.dart';
import '../l10n/generated/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onThemeModeChange;
  final Function(Locale) onLocaleChange;
  final flutter_acrylic.WindowEffect currentWindowEffect;
  final Function(flutter_acrylic.WindowEffect) onWindowEffectChange;

  const SettingsPage({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChange,
    required this.onLocaleChange,
    required this.currentWindowEffect,
    required this.onWindowEffectChange,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // segatools 版本
  String? _segatoolsVersion;
  bool _segatoolsExpanded = false;
  bool _updating = false;
  int _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadSegatoolsVersion();
  }

  Future<void> _loadSegatoolsVersion() async {
    final v = await SegatoolsUpdater.getSavedVersion();
    if (mounted) setState(() => _segatoolsVersion = v);
  }

  Future<void> _openAppDataDir() async {
    try {
      final path = await AppPaths.ensureDataDir();
      await Process.run('explorer.exe', [path]);
    } catch (e) {
      if (mounted) displayInfoBar(context, builder: (c, close) => InfoBar(
        title: const Text('Error'), content: Text(e.toString()), severity: InfoBarSeverity.error));
    }
  }

  // ── segatools 操作 ──

  Future<void> _onlineUpdate() async {
    setState(() { _updating = true; _downloadProgress = 0; });
    try {
      final v = await SegatoolsUpdater.onlineUpdate((pct) {
        if (mounted) setState(() => _downloadProgress = pct);
      });
      if (mounted) {
        setState(() { _segatoolsVersion = v; _updating = false; });
        displayInfoBar(context, builder: (c, close) => InfoBar(
          title: const Text('Updated'), content: Text('segatools v$v'), severity: InfoBarSeverity.success));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _updating = false);
        displayInfoBar(context, builder: (c, close) => InfoBar(
          title: const Text('Update failed'), content: Text('$e'), severity: InfoBarSeverity.error));
      }
    }
  }

  Future<void> _localUpdate() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom, allowedExtensions: ['zip']);
    if (result == null || result.files.single.path == null) return;

    setState(() => _updating = true);
    try {
      final v = await SegatoolsUpdater.localUpdate(result.files.single.path!);
      if (mounted) {
        setState(() { _segatoolsVersion = v; _updating = false; });
        displayInfoBar(context, builder: (c, close) => InfoBar(
          title: const Text('Updated'), content: Text('segatools v$v'), severity: InfoBarSeverity.success));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _updating = false);
        displayInfoBar(context, builder: (c, close) => InfoBar(
          title: const Text('Invalid file'), content: Text('$e'), severity: InfoBarSeverity.error));
      }
    }
  }

  Future<void> _resetSegatools() async {
    await SegatoolsUpdater.reset();
    if (mounted) setState(() { _segatoolsVersion = null; _segatoolsExpanded = false; });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);
    final theme = FluentTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final svgColor = isDark ? Colors.white : Colors.black;

    return ScaffoldPage(
      header: PageHeader(title: Text(loc.settings)),
      content: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: ListView(
          children: [
            // ── About ──
            _SectionHeader(text: loc.about),
            const SizedBox(height: 4),
            Card(
              borderRadius: BorderRadius.circular(8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: Image.asset('assets/app.webp', width: 48, height: 48,
                        errorBuilder: (c, e, s) => const Icon(FluentIcons.app_icon_default, size: 48))),
                    const SizedBox(width: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('SEGAio', style: theme.typography.title?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${loc.version} 26.03.10', style: theme.typography.body),
                    ]),
                  ]),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text('Tools for SEGA-related I/O, based on Dniel97-segatools'),
                ),
                const Divider(),
                ListTile(
                  leading: SvgPicture.asset('assets/gitea.svg', width: 20, height: 20,
                    colorFilter: ColorFilter.mode(svgColor, BlendMode.srcIn),
                    placeholderBuilder: (c) => const Icon(FluentIcons.link, size: 20)),
                  title: const Text("Gitea"),
                  subtitle: const Text("https://gitea.tendokyu.moe/TeamTofuShop/segatools"),
                  trailing: const Icon(FluentIcons.open_in_new_window, size: 12),
                  onPressed: () => launchUrl(Uri.parse('https://gitea.tendokyu.moe/TeamTofuShop/segatools')),
                ),
                ListTile(
                  leading: SvgPicture.asset('assets/github.svg', width: 20, height: 20,
                    colorFilter: ColorFilter.mode(svgColor, BlendMode.srcIn),
                    placeholderBuilder: (c) => const Icon(FluentIcons.git_graph, size: 20)),
                  title: Text(loc.githubRepo),
                  subtitle: Text(loc.githubSub),
                  trailing: const Icon(FluentIcons.open_in_new_window, size: 12),
                  onPressed: () => launchUrl(Uri.parse('https://github.com/C-F0x/SEGAIO')),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Appearance ──
            _SectionHeader(text: loc.appearance),
            const SizedBox(height: 4),
            Card(
              borderRadius: BorderRadius.circular(8),child: Column(children: [
              ListTile(
                leading: const Icon(FluentIcons.color),
                title: Text(loc.themeMode),
                trailing: SizedBox(width: 160, child: ComboBox<ThemeMode>(
                  value: widget.currentThemeMode,
                  items: [
                    ComboBoxItem(value: ThemeMode.system, child: Text(loc.systemMode)),
                    ComboBoxItem(value: ThemeMode.light, child: Text(loc.lightMode)),
                    ComboBoxItem(value: ThemeMode.dark, child: Text(loc.darkMode)),
                  ],
                  onChanged: (mode) => widget.onThemeModeChange(mode!),
                )),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(FluentIcons.locale_language),
                title: Text(loc.language),
                trailing: SizedBox(width: 160, child: ComboBox<Locale>(
                  value: currentLocale,
                  items: const [
                    ComboBoxItem(value: Locale('zh'), child: Text('简体中文')),
                    ComboBoxItem(value: Locale('zh', 'TW'), child: Text('繁体中文')),
                    ComboBoxItem(value: Locale('en'), child: Text('English')),
                  ],
                  onChanged: (locale) { if (locale != null) widget.onLocaleChange(locale); },
                )),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(FluentIcons.cube_shape),
                title: const Text('材质'),
                trailing: SizedBox(width: 160, child: ComboBox<flutter_acrylic.WindowEffect>(
                  value: widget.currentWindowEffect,
                  items: const [
                    ComboBoxItem(value: flutter_acrylic.WindowEffect.acrylic, child: Text('亚克力')),
                    ComboBoxItem(value: flutter_acrylic.WindowEffect.mica, child: Text('云母')),
                    ComboBoxItem(value: flutter_acrylic.WindowEffect.tabbed, child: Text('云母 Alt / Tabbed')),
                  ],
                  onChanged: (effect) { if (effect != null) widget.onWindowEffectChange(effect); },
                )),
              ),
            ])),
            const SizedBox(height: 24),

            // ── Data Management ──
            _SectionHeader(text: loc.dataManagement),
            const SizedBox(height: 4),
            Card(
              borderRadius: BorderRadius.circular(8),child: ListTile(
              leading: const Icon(FluentIcons.folder_search),
              title: const Text('数据存储'),
              subtitle: const Text('应用运行数据、配置缓存及 segatools 存档'),
              trailing: HyperlinkButton(
                onPressed: _openAppDataDir,
                child: const Text('打开文件夹'),
              ),
            )),
            const SizedBox(height: 24),

            // ── Segatools Version ──
            _SectionHeader(text: 'segatools版本'),
            const SizedBox(height: 4),
            Card(
              borderRadius: BorderRadius.circular(8),child: Column(children: [
              ListTile(
                title: Row(children: [
                  const Icon(FluentIcons.save, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _updating
                        ? Row(children: [
                            Expanded(child: ProgressBar(value: _downloadProgress.toDouble())),
                            const SizedBox(width: 12),
                            Text('$_downloadProgress%', style: const TextStyle(fontSize: 12)),
                          ])
                        : Text(_segatoolsVersion ?? '无数据'),
                  ),
                ]),
                trailing: IconButton(
                  icon: Icon(_segatoolsExpanded ? FluentIcons.chevron_up : FluentIcons.chevron_down),
                  onPressed: () => setState(() => _segatoolsExpanded = !_segatoolsExpanded),
                ),
              ),
              if (_segatoolsExpanded) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: FilledButton(
                        onPressed: _updating ? null : _onlineUpdate,
                        child: _updating ? const SizedBox(width: 16, height: 16, child: ProgressRing(strokeWidth: 2)) : const Text('⬇ 在线更新'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: Button(
                        onPressed: _updating ? null : _localUpdate,
                        child: const Text('📂 本地更新'),
                      )),
                      const SizedBox(width: 12),
                      Button(
                        onPressed: _updating ? null : _resetSegatools,
                        child: const Text('↺ 重置'),
                      ),
                    ]),
                  ]),
                ),
              ],
            ])),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 4, start: 4),
      child: Text(text, style: FluentTheme.of(context).typography.subtitle?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}
