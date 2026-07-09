import 'package:fluent_ui/fluent_ui.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool visible;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.accentColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.typography.subtitle?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
