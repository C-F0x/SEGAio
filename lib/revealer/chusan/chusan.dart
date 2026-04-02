import 'package:flutter/material.dart';
import 'dart:typed_data';
// 确保指向正确的路径
import '../inject.dart';

class ChusanPage extends StatelessWidget {
  final Uint8List? rawData;
  const ChusanPage({super.key, this.rawData});

  static String _formatCard(Uint8List card) {
    if (card.isEmpty) return '00000\n00000\n00000\n00000';
    final hex = card
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join();
    // 20位Hex，每5位一行，正好4行
    return List.generate(4, (i) {
      final start = i * 5;
      if (start + 5 > hex.length) return hex.substring(start);
      return hex.substring(start, start + 5);
    }).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 拿到数据：通过 Inject 层解析
    final data = ChusanGoInject(
      rawData ?? Uint8List(ChusanGoInject.kSize),
    ).inject();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            flex: 40,
            child: _TopSection(data: data, isDark: isDark),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 60,
            child: _SliderSection(slider: data.slider, isDark: isDark),
          ),
        ],
      ),
    );
  }
}

class _TopSection extends StatelessWidget {
  final ChusanData data;
  final bool       isDark;
  const _TopSection({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    // TODO: 目前 inject.dart 的 ChusanData 尚未包含系统按钮状态
    // 如果后续在 inject.dart 增加了 test/service 字段，可以在此处对接
    const sideLabels = ['COIN', 'SERV', 'TEST', 'CODE'];

    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Column(
            children: sideLabels.map((label) {
              return Expanded(
                child: _Cell(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: base,
                  isDark: isDark,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: List.generate(6, (i) {
              final logicNum = 6 - i; // 从上往下 6 -> 1
              // inject.dart 中 air 是 List<int>
              final active   = data.air[logicNum - 1] > 0;
              return Expanded(
                child: _Cell(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: active ? Colors.cyanAccent : base,
                  isDark: isDark,
                  child: Text(
                    'AIR $logicNum',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: active
                          ? Colors.black
                          : (isDark ? Colors.white24 : Colors.black26),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(width: 12),
        _AccessCodePanel(
          code:   ChusanPage._formatCard(data.card),
          isDark: isDark,
        ),
      ],
    );
  }
}

class _SliderSection extends StatelessWidget {
  final List<int> slider;
  final bool      isDark;
  const _SliderSection({required this.slider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return Column(
      children: List.generate(2, (row) {
        return Expanded(
          child: Row(
            children: List.generate(16, (col) {
              // 计算 1-32 的逻辑索引
              final logicIndex = (15 - col) * 2 + (row + 1);
              final active     = slider[logicIndex - 1] > 0;
              return Expanded(
                child: _Cell(
                  margin: const EdgeInsets.all(1.5),
                  radius: 2,
                  color: active ? Colors.amberAccent : base,
                  isDark: isDark,
                  child: FittedBox(
                    child: Text(
                      '$logicIndex',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: active
                            ? Colors.black
                            : (isDark ? Colors.white24 : Colors.black26),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _Cell extends StatelessWidget {
  final Widget    child;
  final Color     color;
  final bool      isDark;
  final EdgeInsets margin;
  final double    radius;

  const _Cell({
    required this.child,
    required this.color,
    required this.isDark,
    this.margin = EdgeInsets.zero,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:     margin,
      width:      double.infinity,
      decoration: BoxDecoration(
        color:        color,
        borderRadius: BorderRadius.circular(radius),
        border:       Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Center(child: child),
    );
  }
}

class _AccessCodePanel extends StatelessWidget {
  final String code;
  final bool   isDark;
  const _AccessCodePanel({required this.code, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
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
            code,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}