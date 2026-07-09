import 'dart:convert';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';

import 'shared/app_paths.dart';

import 'pages/launcher.dart';
import 'pages/settings.dart';
import 'pages/config.dart';
import 'revealer/init.dart';
import 'l10n/generated/app_localizations.dart';

/// 自定义滚动行为 — 禁用所有滚动条渲染
class _NoScrollbarBehavior extends FluentScrollBehavior {
  const _NoScrollbarBehavior();
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await flutter_acrylic.Window.initialize();
  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(const Size(720, 480));

  final saved = await _loadSettings();
  final themeMode = saved.$1;
  final windowEffect = saved.$2;
  final locale = saved.$3;
  final isDark = themeMode == ThemeMode.system
      ? PlatformDispatcher.instance.platformBrightness == Brightness.dark
      : themeMode == ThemeMode.dark;

  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setBackgroundColor(Colors.transparent);
    await windowManager.show();
    await flutter_acrylic.Window.setEffect(
      effect: windowEffect,
      dark: isDark,
    );
  });

  runApp(MyApp(
    initialThemeMode: themeMode,
    initialWindowEffect: windowEffect,
    initialLocale: locale,
  ));
}

Future<(ThemeMode, flutter_acrylic.WindowEffect, Locale)> _loadSettings() async {
  try {
    final file = File(await AppPaths.settingsFile);
    if (await file.exists()) {
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final themeMode = ThemeMode.values.firstWhere(
            (e) => e.toString() == 'ThemeMode.${data['themeMode']}',
        orElse: () => ThemeMode.system,
      );
      final effect = flutter_acrylic.WindowEffect.values.firstWhere(
            (e) => e.name == data['windowEffect'],
        orElse: () => flutter_acrylic.WindowEffect.mica,
      );
      Locale? locale;
      final langStr = data['language'] as String?;
      if (langStr != null) {
        final parts = langStr.split('_');
        locale = Locale(parts.first, parts.length > 1 ? parts.last : null);
      }
      return (themeMode, effect, locale ?? const Locale('zh'));
    }
  } catch (_) {}
  return (ThemeMode.system, flutter_acrylic.WindowEffect.mica, const Locale('zh'));
}

Future<void> _saveSettings({
  required ThemeMode themeMode,
  required flutter_acrylic.WindowEffect windowEffect,
  required Locale locale,
}) async {
  try {
    final file = File(await AppPaths.settingsFile);
    final langStr = locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    await file.writeAsString(jsonEncode({
      'themeMode': themeMode.name,
      'windowEffect': windowEffect.name,
      'language': langStr,
    }));
  } catch (_) {}
}

const Color _fluentAccent = Color(0xFF0078D4);

FluentThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return FluentThemeData(
    brightness: brightness,
    accentColor: _fluentAccent.toAccentColor(),
    scaffoldBackgroundColor: Colors.transparent,
    cardColor: Color(isDark ? 0x10FFFFFF : 0x30FFFFFF),
    navigationPaneTheme: NavigationPaneThemeData(
      backgroundColor: Colors.transparent,
    ),
  );
}

class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final flutter_acrylic.WindowEffect initialWindowEffect;
  final Locale initialLocale;
  const MyApp({
    super.key,
    required this.initialThemeMode,
    required this.initialWindowEffect,
    required this.initialLocale,
  });
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;
  late ThemeMode _themeMode;
  late flutter_acrylic.WindowEffect _windowEffect;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    _themeMode = widget.initialThemeMode;
    _windowEffect = widget.initialWindowEffect;
  }

  void setLocale(Locale locale) async {
    setState(() => _locale = locale);
    _saveSettings(themeMode: _themeMode, windowEffect: _windowEffect, locale: locale);
  }

  void setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    await _applyWindowEffect();
    _saveSettings(themeMode: _themeMode, windowEffect: _windowEffect, locale: _locale);
  }

  void setWindowEffect(flutter_acrylic.WindowEffect effect) async {
    setState(() => _windowEffect = effect);
    await _applyWindowEffect();
    _saveSettings(themeMode: _themeMode, windowEffect: _windowEffect, locale: _locale);
  }

  Future<void> _applyWindowEffect() async {
    final isDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            PlatformDispatcher.instance.platformBrightness == Brightness.dark);
    await flutter_acrylic.Window.setEffect(
      effect: _windowEffect,
      dark: isDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      scrollBehavior: const _NoScrollbarBehavior(),
      home: MainNavigation(
        onLocaleChange: setLocale,
        currentThemeMode: _themeMode,
        onThemeModeChange: setThemeMode,
        currentWindowEffect: _windowEffect,
        onWindowEffectChange: setWindowEffect,
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onThemeModeChange;
  final flutter_acrylic.WindowEffect currentWindowEffect;
  final Function(flutter_acrylic.WindowEffect) onWindowEffectChange;

  const MainNavigation({
    super.key,
    required this.onLocaleChange,
    required this.currentThemeMode,
    required this.onThemeModeChange,
    required this.currentWindowEffect,
    required this.onWindowEffectChange,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 3;

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return NavigationView(
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: _navigateTo,
        displayMode: PaneDisplayMode.auto,
        toggleable: true,
        size: const NavigationPaneSize(
          openMaxWidth: 150,
          openMinWidth: 50,
        ),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.home),
            title: const Text('Launcher'),
            body: LauncherPage(onNavigate: (i) => _navigateTo(i)),
          ),
          PaneItem(
            key: const ValueKey('config'),
            icon: const Icon(FluentIcons.page_list),
            title: Text(loc.manageConfig),
            body: ConfigPage(title: loc.manageConfig),
          ),
          PaneItem(
            key: const ValueKey('revealer'),
            icon: const Icon(FluentIcons.view_all),
            title: const Text('Revealer'),
            body: const RevealerPage(),
          ),
        ],
        footerItems: [
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: Text(loc.settings),
            body: SettingsPage(
              currentThemeMode: widget.currentThemeMode,
              onThemeModeChange: widget.onThemeModeChange,
              onLocaleChange: widget.onLocaleChange,
              currentWindowEffect: widget.currentWindowEffect,
              onWindowEffectChange: widget.onWindowEffectChange,
            ),
          ),
          PaneItemSeparator(),
        ],
      ),
    );
  }
}
