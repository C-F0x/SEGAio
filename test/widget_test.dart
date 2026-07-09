import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;

import 'package:segaio/main.dart';

void main() {
  testWidgets('App can be instantiated', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(
      initialThemeMode: ThemeMode.system,
      initialWindowEffect: flutter_acrylic.WindowEffect.mica,
      initialLocale: Locale('zh'),
    ));
  });
}
