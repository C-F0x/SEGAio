import 'dart:convert';
import 'dart:io';
import 'project.dart';
import 'app_paths.dart';

class JsonDbService {
  static Future<File> _getProjectFile() async {
    final path = await AppPaths.projectsFile;
    return File(path);
  }

  static Future<List<Project>> loadProjects() async {
    try {
      final file = await _getProjectFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      List<Project> projects = jsonList.map((e) => Project.fromJson(e)).toList();
      projects.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
      return projects;
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveProjects(List<Project> projects) async {
    try {
      final file = await _getProjectFile();
      projects.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
      const encoder = JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(projects.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }
}