import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import '../shared/app_paths.dart';

class SegatoolsUpdater {
  SegatoolsUpdater._();

  static const _downloadUrl =
      'https://gitea.tendokyu.moe/TeamTofuShop/segatools/releases/download/latest/segatools.zip';

  /// 读取已保存的版本号（从 settings.json）
  static Future<String?> getSavedVersion() async {
    try {
      final f = File(await AppPaths.settingsFile);
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        return data['segatoolsVersion'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// 在线更新，[onProgress] 返回 0-100
  static Future<String?> onlineUpdate(void Function(int pct)? onProgress) async {
    final tempDir = await _tempDir();
    final zipPath = p.join(tempDir, 'segatools.zip');

    // curl --progress-bar 原生输出百分比
    onProgress?.call(0);
    try {
      final proc = await Process.start('curl', [
        '-L', '--progress-bar', '-o', zipPath, _downloadUrl,
      ], workingDirectory: tempDir);

      proc.stderr.transform(utf8.decoder).listen((data) {
        // --progress-bar 输出格式: "############################# 45.0%\r"
        // 用 \r 分割每行，提取数字+% 部分
        for (final line in data.split('\r')) {
          final m = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(line);
          if (m != null) {
            final pct = double.tryParse(m.group(1) ?? '')?.round().clamp(0, 100);
            if (pct != null) onProgress?.call(pct);
          }
        }
      });

      final exit = await proc.exitCode;
      if (exit != 0) throw Exception('curl exit code: $exit');
    } catch (e) {
      throw Exception('Download failed: $e');
    }

    // 校验
    return _processZip(zipPath, tempDir);
  }

  /// 本地更新 — 传入 zip 文件路径
  static Future<String?> localUpdate(String zipPath) async {
    final tempDir = await _tempDir();
    final dest = p.join(tempDir, 'segatools.zip');
    await File(zipPath).copy(dest);
    return _processZip(dest, tempDir);
  }

  /// 重置 — 清除 settings.json 中的版本记录
  static Future<void> reset() async {
    await _updateVersionInSettings(null);
  }

  /// 从 segatools.zip 中读取 varieties 对应的 segatools.ini 模板内容
  static Future<String?> getTemplateIni(String variety) async {
    try {
      final zipPath = p.join(AppPaths.dataDir, 'segatools.zip');
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) return null;
      final outerBytes = await zipFile.readAsBytes();
      final outerArchive = ZipDecoder().decodeBytes(outerBytes);
      // 外层找到 {variety}.zip
      final innerEntry = outerArchive.firstWhere(
        (e) => e.name == '$variety.zip' && e.isFile,
      );
      final innerBytes = innerEntry.content as List<int>;
      final innerArchive = ZipDecoder().decodeBytes(innerBytes);
      // 内层找 segatools.ini
      for (final entry in innerArchive) {
        if (entry.name == 'segatools.ini' || entry.name.endsWith('/segatools.ini')) {
          return utf8.decode(entry.content as List<int>);
        }
      }
    } catch (_) {}
    return null;
  }

  // ── 内部 ──

  /// 校验 zip 并持久化，返回版本号或 null
  static Future<String?> _processZip(String zipPath, String tempDir) async {
    try {
      // 读 zip
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // ① 检查根目录条目数（21）
      final rootEntries = <String>{};
      for (final f in archive) {
        final top = f.name.split('/').first;
        rootEntries.add(top);
      }
      if (rootEntries.length != 21) {
        throw Exception('Invalid zip: ${rootEntries.length} root entries (expected 21)');
      }

      // ② 读取 README.md 获取版本号
      String? version;
      for (final f in archive) {
        if (f.name == 'README.md' || f.name.endsWith('/README.md')) {
          final content = utf8.decode(f.content as List<int>);
          final re = RegExp(r"Version:\s*['`\x22]?(.+?)['`\x22]?\s*$", multiLine: true);
          final match = re.firstMatch(content);
          if (match != null) version = match.group(1)?.trim();
          break;
        }
      }
      if (version == null || version.isEmpty) {
        throw Exception('Could not extract version from README.md');
      }

      // 通过校验 — 归档到 data/
      final dataDir = await AppPaths.ensureDataDir();
      await File(zipPath).copy(p.join(dataDir, 'segatools.zip'));
      await _updateVersionInSettings(version);

      return version;
    } catch (e) {
      // 清理 temp
      try { await Directory(tempDir).delete(recursive: true); } catch (_) {}
      rethrow;
    }
  }

  /// 写入/清除 settings.json 中的 segatoolsVersion
  static Future<void> _updateVersionInSettings(String? version) async {
    try {
      final settingsFile = File(await AppPaths.settingsFile);
      Map<String, dynamic> data = {};
      if (await settingsFile.exists()) {
        data = jsonDecode(await settingsFile.readAsString()) as Map<String, dynamic>;
      }
      if (version != null) {
        data['segatoolsVersion'] = version;
      } else {
        data.remove('segatoolsVersion');
      }
      await settingsFile.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  static Future<String> _tempDir() async {
    final dir = Directory(p.join(
      Platform.environment['TEMP'] ?? Platform.environment['TMP'] ?? '.',
      'segaio_update_${DateTime.now().millisecondsSinceEpoch}',
    ));
    await dir.create(recursive: true);
    return dir.path;
  }
}
