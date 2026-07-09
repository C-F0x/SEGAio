import 'package:fluent_ui/fluent_ui.dart';

/// 每个 INI section 的抽象接口
/// 所有 section widget 的 state 都应混入此类
abstract class ConfigSection {
  /// 返回 section 名称 → { key → value } 的映射用于写入 INI
  Map<String, Map<String, String>> getConfigData();

  /// 强制重新加载 INI 数据
  void reloadData();
}
