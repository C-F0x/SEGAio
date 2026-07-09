import 'package:fluent_ui/fluent_ui.dart';
import 'highlighted_text.dart';

class SettingItem extends StatelessWidget {
  final String label;
  final Widget child;
  final String? error;
  final String searchKeyword;
  final double labelFlex;
  final double childFlex;

  const SettingItem({
    super.key,
    required this.label,
    required this.child,
    this.error,
    this.searchKeyword = '',
    this.labelFlex = 3,
    this.childFlex = 7,
  });

  bool get _visible {
    if (searchKeyword.isEmpty) return true;
    return label.toLowerCase().contains(searchKeyword.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: labelFlex.toInt(),
                child: HighlightedText(
                  text: label,
                  keyword: searchKeyword,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: childFlex.toInt(),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: child,
                ),
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
}

class SwitchSettingItem extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String searchKeyword;

  const SwitchSettingItem({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.searchKeyword = '',
  });

  @override
  Widget build(BuildContext context) {
    return SettingItem(
      label: label,
      searchKeyword: searchKeyword,
      child: ToggleSwitch(
        checked: value,
        onChanged: onChanged,
      ),
    );
  }
}
