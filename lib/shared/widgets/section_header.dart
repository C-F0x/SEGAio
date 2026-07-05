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
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: FluentTheme.of(context).accentColor),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
