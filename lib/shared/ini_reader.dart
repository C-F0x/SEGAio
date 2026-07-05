import 'dart:io';
import 'package:path/path.dart' as p;

class IniSection {
  final String name;
  final Map<String, String> values;

  const IniSection({required this.name, required this.values});

  bool getBool(String key, [bool fallback = false]) {
    final v = values[key];
    if (v == null) return fallback;
    return v == '1';
  }

  int getInt(String key, [int fallback = 0]) {
    final v = values[key];
    if (v == null) return fallback;
    return int.tryParse(v) ?? fallback;
  }

  String getString(String key, [String fallback = '']) {
    return values[key] ?? fallback;
  }
}

class IniFile {
  final List<IniSection> sections;

  const IniFile({required this.sections});

  IniSection? section(String name) {
    final lower = name.toLowerCase();
    for (final s in sections) {
      if (s.name.toLowerCase() == lower) return s;
    }
    return null;
  }
}

class IniReader {
  static Future<IniFile?> load(String projectPath) async {
    try {
      final file = File(p.join(projectPath, 'segatools.ini'));
      if (!await file.exists()) return null;
      final lines = await file.readAsLines();
      return _parse(lines);
    } catch (_) {
      return null;
    }
  }

  static Future<IniFile?> loadFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final lines = await file.readAsLines();
      return _parse(lines);
    } catch (_) {
      return null;
    }
  }

  static IniFile _parse(List<String> lines) {
    final List<IniSection> sections = [];
    String currentName = '';
    Map<String, String> currentValues = {};

    for (var line in lines) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith(';') || t.startsWith('#')) continue;
      if (t.startsWith('[') && t.endsWith(']')) {
        if (currentName.isNotEmpty) {
          sections.add(IniSection(name: currentName, values: Map.from(currentValues)));
        }
        currentName = t.substring(1, t.length - 1);
        currentValues = {};
        continue;
      }
      final parts = t.split('=');
      if (parts.length < 2) continue;
      final k = parts[0].trim();
      final v = parts.sublist(1).join('=').trim();
      currentValues[k] = v;
    }
    if (currentName.isNotEmpty) {
      sections.add(IniSection(name: currentName, values: Map.from(currentValues)));
    }
    return IniFile(sections: sections);
  }
}
