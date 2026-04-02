import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../inject.dart';

class Mu3Page extends StatelessWidget {
  final Uint8List? rawData;
  const Mu3Page({super.key, this.rawData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = Mu3GoInject(
      rawData ?? Uint8List(Mu3GoInject.kSize),
    ).inject();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SizedBox(
            height: 100,
            child: Row(
              children: [
                _SideButtons(isDark: isDark),
                const Expanded(child: SizedBox()),
                _AccessCodePanel(isDark: isDark),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                _StickBar(value: data.stick, isDark: isDark),
                const Spacer(flex: 1),
                _ButtonLayout(buttons: data.buttons, isDark: isDark),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SideButtons extends StatelessWidget {
  final bool isDark;
  const _SideButtons({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const labels   = ['COIN', 'SERV', 'TEST', 'CODE'];
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return SizedBox(
      width: 70,
      child: Column(
        children: labels.map((l) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color:        baseColor,
                borderRadius: BorderRadius.circular(4),
                border:       Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Center(
                child: Text(
                  l,
                  style: TextStyle(
                    fontSize:   10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


class _AccessCodePanel extends StatelessWidget {
  final bool isDark;
  const _AccessCodePanel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'ACCESS CODE',
            style: TextStyle(
              fontSize: 8,
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '00000\n00000\n00000\n00000',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize:   12,
              fontFamily: 'monospace',
              color:  isDark ? Colors.white24 : Colors.black38,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StickBar extends StatelessWidget {
  final int  value;
  final bool isDark;
  const _StickBar({required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  double.infinity,
      height: 40,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Center(
        child: Text(
          'STICK / MENU 0 : $value',
          style: TextStyle(
            fontSize:      13,
            fontFamily:    'Consolas',
            fontWeight:    FontWeight.bold,
            letterSpacing: 1.5,
            color: isDark ? Colors.white30 : Colors.black26,
          ),
        ),
      ),
    );
  }
}


class _ButtonLayout extends StatelessWidget {
  final List<bool> buttons;
  final bool       isDark;
  const _ButtonLayout({required this.buttons, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RectButton(label: 'L', active: buttons[0], isDark: isDark),
        const SizedBox(width: 40),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _SqButton(label: '7', active: buttons[7], isDark: isDark),
                const SizedBox(width: 140),
                _SqButton(label: '8', active: buttons[8], isDark: isDark),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(
                6,
                    (i) => _SqButton(
                  label:  '${i + 1}',
                  active: buttons[i + 1],
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 40),
        _RectButton(label: 'R', active: buttons[6], isDark: isDark),
      ],
    );
  }
}

class _SqButton extends StatelessWidget {
  final String label;
  final bool   active;
  final bool   isDark;
  const _SqButton({
    required this.label,
    required this.active,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  75,
      height: 75,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: active
            ? Colors.blueAccent
            : (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize:   22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
        ),
      ),
    );
  }
}

class _RectButton extends StatelessWidget {
  final String label;
  final bool   active;
  final bool   isDark;
  const _RectButton({
    required this.label,
    required this.active,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  75,
      height: 170,
      decoration: BoxDecoration(
        color: active
            ? Colors.redAccent.withValues(alpha: 0.7)
            : (isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize:   32,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
        ),
      ),
    );
  }
}