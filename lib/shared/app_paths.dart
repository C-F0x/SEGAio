import 'dart:io';
import 'package:path/path.dart' as p;

/// 应用数据存储路径 — 位于 exe 所在目录下的 data/ 子目录。
/// 这使得应用可以便携使用（安装到任意目录即可运行）。
class AppPaths {
  AppPaths._();

  /// 获取可执行文件所在目录
  static String get exeDir {
    final exePath = Platform.resolvedExecutable;
    return p.dirname(exePath);
  }

  /// 数据目录: {exeDir}/data/
  static String get dataDir {
    final dir = p.join(exeDir, 'data');
    return dir;
  }

  /// 确保数据目录存在并返回
  static Future<String> ensureDataDir() async {
    final dir = Directory(dataDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dataDir;
  }

  /// projects.json 文件路径
  static Future<String> get projectsFile async {
    final dir = await ensureDataDir();
    return p.join(dir, 'projects.json');
  }

  /// settings.json 文件路径
  static Future<String> get settingsFile async {
    final dir = await ensureDataDir();
    return p.join(dir, 'settings.json');
  }
}
