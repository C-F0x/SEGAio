import 'package:fluent_ui/fluent_ui.dart';
import 'field_tooltips.dart';

/// 带浮标提示的设置项组件
/// 鼠标悬停在 label 上时显示上游 INI 注解
class SettingField extends StatelessWidget {
  final String section;      // INI section name
  final String field;        // INI key name
  final String label;        // UI display label
  final Widget child;        // input control
  final String? error;
  final String searchKeyword;
  final double labelFlex;
  final double childFlex;

  const SettingField({
    super.key,
    required this.section,
    required this.field,
    required this.label,
    required this.child,
    this.error,
    this.searchKeyword = '',
    this.labelFlex = 3,
    this.childFlex = 7,
  });

  String get _tooltip => fieldTooltips['$section.$field'] ?? '';

  bool get _visible {
    if (searchKeyword.isEmpty) return true;
    return label.toLowerCase().contains(searchKeyword.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final labelWidget = _buildLabel(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(flex: labelFlex.toInt(), child: labelWidget),
              const SizedBox(width: 16),
              Expanded(
                flex: childFlex.toInt(),
                child: Align(alignment: Alignment.centerLeft, child: child),
              ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                error!,
                style: TextStyle(color: Colors.red.normal, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    final text = HighlightedText(
      text: label,
      keyword: searchKeyword,
    );

    if (_tooltip.isEmpty) return text;

    return Tooltip(
      message: _tooltip,
      child: text,
    );
  }
}

/// 搜索高亮文本（复用逻辑，内嵌于此避免跨文件依赖）
class HighlightedText extends StatelessWidget {
  final String text;
  final String keyword;
  final TextStyle? style;

  const HighlightedText({
    super.key,
    required this.text,
    required this.keyword,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (keyword.isEmpty || !text.toLowerCase().contains(keyword.toLowerCase())) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    final accent = FluentTheme.of(context).accentColor;
    final spans = <TextSpan>[];
    int start = 0;

    int index;
    while ((index = lowerText.indexOf(lowerKeyword, start)) != -1) {
      if (index > start) spans.add(TextSpan(text: text.substring(start, index)));
      spans.add(TextSpan(
        text: text.substring(index, index + keyword.length),
        style: TextStyle(color: accent, fontWeight: FontWeight.bold),
      ));
      start = index + keyword.length;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));

    return RichText(
      text: TextSpan(
        style: style ?? DefaultTextStyle.of(context).style,
        children: spans,
      ),
    );
  }
}

/// 开关类型的快捷 SettingField
class SwitchField extends StatelessWidget {
  final String section;
  final String field;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String searchKeyword;

  const SwitchField({
    super.key,
    required this.section,
    required this.field,
    required this.label,
    required this.value,
    required this.onChanged,
    this.searchKeyword = '',
  });

  @override
  Widget build(BuildContext context) {
    return SettingField(
      section: section,
      field: field,
      label: label,
      searchKeyword: searchKeyword,
      child: ToggleSwitch(checked: value, onChanged: onChanged),
    );
  }
}
