import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'inject.dart';

class RevealerOptionBar extends StatefulWidget {
  const RevealerOptionBar({
    super.key,
    required this.onConfigChange,
    required this.onStart,
    required this.onStop,
  });

  final ValueChanged<RevealerConfig> onConfigChange;
  final ValueChanged<RevealerConfig> onStart;
  final VoidCallback                 onStop;

  @override
  State<RevealerOptionBar> createState() => _RevealerOptionBarState();
}

class _RevealerOptionBarState extends State<RevealerOptionBar> {
  static const Map<String, List<String>> _catalogue = {
    'Chusan': ['Rustnithm', 'Laverita', 'YubiDeck', 'Tasoller', 'Tasoller+', 'CUSTOM'],
    'Mu3':    ['Yuangeki', 'Ontroller', 'CUSTOM'],
    'Mai2':   ['ADX', 'NDX', 'Maitroller', 'CUSTOM'],
  };

  static const _debugColors = [
    Color(0xFFADD8E6),
    Color(0xFFE6BBAD),
    Color(0xFFFFD500),
  ];

  String _major      = 'Chusan';
  String _minor      = 'Rustnithm';
  bool   _running    = false;
  int    _debugLevel = 0;

  final TextEditingController _freqCtrl   = TextEditingController(text: '100');
  final TextEditingController _customCtrl = TextEditingController();

  bool get _isCustom => _minor == 'CUSTOM';
  bool get _isLocked => _running;

  RevealerConfig _buildConfig() {
    final int hz = int.tryParse(_freqCtrl.text) ?? 100;
    final int safeHz = hz > 0 ? hz : 1;

    return RevealerConfig(
      majorType:      _major,
      minorType:      _minor,
      rawSharedMem:   _isCustom ? _customCtrl.text.trim() : '',
      pollIntervalMs: (1000 / safeHz).round(),
      debugLevel:     _debugLevel,
    );
  }

  void _validateFreq() {
    final int? val = int.tryParse(_freqCtrl.text);
    if (val == null || val < 1 || val > 100) {
      _freqCtrl.text = '10';
    }
  }

  void _triggerUpdate() {
    _validateFreq();
    setState(() {});
    widget.onConfigChange(_buildConfig());
  }

  void _setMajor(String v) {
    _major = v;
    _minor = _catalogue[v]!.first;
    _triggerUpdate();
  }

  void _setMinor(String v) {
    _minor = v;
    _triggerUpdate();
  }

  void _cycleDebug() {
    _debugLevel = (_debugLevel + 1) % 3;
    _triggerUpdate();
  }

  void _onToggle(bool value) {
    _validateFreq();
    setState(() => _running = value);
    if (value) {
      widget.onStart(_buildConfig());
    } else {
      widget.onStop();
    }
  }

  @override
  void dispose() {
    _freqCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Tooltip(
          message: _isLocked
              ? 'Unlock to change debug mode'
              : ['Transferred', 'Read Only', 'Read & Write'][_debugLevel],
          child: GestureDetector(
            onTap: _isLocked ? null : _cycleDebug,
            child: MouseRegion(
              cursor: _isLocked ? SystemMouseCursors.basic : SystemMouseCursors.click,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _debugColors[_debugLevel].withValues(alpha: _isLocked ? 0.5 : 1.0),
                ),
                child: const Text('Revealer'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),

        SizedBox(
          width: 100,
          child: ComboBox<String>(
            value: _major,
            items: _catalogue.keys
                .map((e) => ComboBoxItem(value: e, child: Text(e)))
                .toList(),
            onChanged: _isLocked ? null : (v) { if (v != null) _setMajor(v); },
          ),
        ),
        const SizedBox(width: 12),

        SizedBox(
          width: 130,
          child: ComboBox<String>(
            value: _minor,
            items: _catalogue[_major]!
                .map((e) => ComboBoxItem(value: e, child: Text(e)))
                .toList(),
            onChanged: _isLocked ? null : (v) { if (v != null) _setMinor(v); },
          ),
        ),
        const SizedBox(width: 12),

        if (_isCustom) ...[
          SizedBox(
            width: 316,
            child: TextBox(
              enabled:     !_isLocked,
              controller:  _customCtrl,
              placeholder: 'Enter Shared Memory Name…',
              onChanged:   (_) => widget.onConfigChange(_buildConfig()),
              onSubmitted: (_) => _triggerUpdate(),
            ),
          ),
          const SizedBox(width: 12),
        ],

        const Spacer(),

        Tooltip(
          message: 'Sampling Frequency (1-100 Hz)',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                child: TextBox(
                  controller:  _freqCtrl,
                  enabled:     !_isLocked,
                  padding:     const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  textAlign:   TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  placeholder: '10',
                  onSubmitted: (_) => _triggerUpdate(),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'HZ',
                style: TextStyle(
                  fontSize:      11,
                  fontWeight:    FontWeight.w600,
                  letterSpacing: 0.8,
                  color: FluentTheme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.40),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        ToggleSwitch(
          checked:   _running,
          onChanged: _onToggle,
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}