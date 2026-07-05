import 'package:fluent_ui/fluent_ui.dart';

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
    if (keyword.isEmpty ||
        !text.toLowerCase().contains(keyword.toLowerCase())) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    final accent = FluentTheme.of(context).accentColor;
    final spans = <TextSpan>[];
    int start = 0;

    int index;
    while ((index = lowerText.indexOf(lowerKeyword, start)) != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + keyword.length),
        style: TextStyle(color: accent, fontWeight: FontWeight.bold),
      ));
      start = index + keyword.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: style ?? DefaultTextStyle.of(context).style,
        children: spans,
      ),
    );
  }
}
