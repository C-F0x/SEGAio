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

class KeyBindingItem extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String searchKeyword;
  final String Function(String hex) keyNameResolver;

  const KeyBindingItem({
    super.key,
    required this.label,
    required this.controller,
    this.searchKeyword = '',
    required this.keyNameResolver,
  });

  bool get _visible {
    if (searchKeyword.isEmpty) return true;
    return label.toLowerCase().contains(searchKeyword.toLowerCase()) ||
        keyNameResolver(controller.text)
            .toLowerCase()
            .contains(searchKeyword.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final keyName = keyNameResolver(controller.text);
    final hasKey =
        controller.text.isNotEmpty && controller.text != "0x00";
    final theme = FluentTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: HighlightedText(
              text: label,
              keyword: searchKeyword,
            ),
          ),
          Expanded(
            flex: 7,
            child: Row(
              children: [
                Expanded(
                  child: TextBox(
                    controller: controller,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 80,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: hasKey
                        ? theme.accentColor.withOpacity(0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: theme.resources.surfaceStrokeColorDefault,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    keyName,
                    style: TextStyle(
                      color: hasKey
                          ? theme.accentColor
                          : theme.typography.caption?.color,
                      fontWeight: hasKey ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Button(
                  child: const Icon(FluentIcons.keyboard_classic),
                  onPressed: () => {}, // override via builder pattern
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
