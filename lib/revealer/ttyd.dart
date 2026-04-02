import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;

class TtydPage extends StatelessWidget {
  final List<String> lines;

  const TtydPage({super.key, this.lines = const []});

  static List<String> _mockLines() => List.generate(64, (i) {
    final addr    = (i * 16).toRadixString(16).padLeft(4, '0').toUpperCase();
    final hexLine = List.filled(16, '00').join(' ');
    return '$addr | $hexLine';
  });

  @override
  Widget build(BuildContext context) {
    final theme  = FluentTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final display = lines.isEmpty ? _mockLines() : lines;
    final content = display.join('\n');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                FluentIcons.command_prompt,
                size:  10,
                color: isDark ? Colors.grey[100] : Colors.grey[120],
              ),
              const SizedBox(width: 10),
              Text(
                'DEBUG TERMINAL – HEX MIRROR',
                style: TextStyle(
                  fontSize:      9,
                  fontWeight:    FontWeight.w600,
                  color:         isDark ? Colors.grey[100] : Colors.grey[120],
                  letterSpacing: 0.5,
                  fontFamily:    'Segoe UI',
                ),
              ),
              const Spacer(),
              Text(
                'LINES: ${display.length}',
                style: TextStyle(
                  fontSize:   9,
                  color:      isDark ? Colors.grey[120] : Colors.grey[140],
                  fontFamily: 'Consolas',
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: material.SingleChildScrollView(
            padding:  const EdgeInsets.all(16),
            physics:  const material.BouncingScrollPhysics(),
            child: material.SelectableText(
              content,
              style: TextStyle(
                color:         isDark
                    ? const Color(0xFFD1D1D1)
                    : const Color(0xFF454545),
                fontFamily:    'Consolas',
                fontSize:      12,
                height:        1.5,
                letterSpacing: 1.0,
                fontWeight:    FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}