import 'dart:async';
import 'dart:typed_data';
import 'package:fluent_ui/fluent_ui.dart';

import 'inject.dart';
import 'option.dart';
import 'ttyd.dart';
import 'fallback.dart';

import 'chusan/chusan.dart';
import 'mu3/mu3.dart';
import 'mai2/mai2.dart';

class RevealerPage extends StatefulWidget {
  const RevealerPage({super.key});

  @override
  State<RevealerPage> createState() => _RevealerPageState();
}

class _RevealerPageState extends State<RevealerPage> {
    RevealerConfig _config = const RevealerConfig(
    majorType: 'Chusan',
    minorType: 'Rustnithm',
  );

    Uint8List? _chusanRaw;
  Uint8List? _mu3Raw;
  Uint8List? _mai2Raw;

  static const int _kMaxHexLines = 256;
  final List<String> _hexLines = [];

  StreamSubscription<RevealerPatch>? _patchSub;

  @override
  void initState() {
    super.initState();
            _patchSub = GoRevealerBridge.instance.patches.listen(_applyPatch);
  }

  @override
  void dispose() {
    _patchSub?.cancel();
    GoRevealerBridge.instance.stop();
    super.dispose();
  }

    void _onConfigChange(RevealerConfig config) {
    setState(() {
      _config = config;
    });

        if (GoRevealerBridge.instance.isRunning) {
      GoRevealerBridge.instance.start(config);
    }
  }

    void _onStart(RevealerConfig config) {
    setState(() => _config = config);

        GoRevealerBridge.instance.start(config);
  }

    void _onStop() {
    GoRevealerBridge.instance.stop();
        setState(() {
      _chusanRaw = null;
      _mu3Raw = null;
      _mai2Raw = null;
    });
  }

  void _applyPatch(RevealerPatch patch) {
        setState(() {
      if (patch.chusanRaw != null) _chusanRaw = patch.chusanRaw;
      if (patch.mu3Raw    != null) _mu3Raw    = patch.mu3Raw;
      if (patch.mai2Raw   != null) _mai2Raw   = patch.mai2Raw;

      if (patch.hexLine != null) {
        _hexLines.add(patch.hexLine!);
        if (_hexLines.length > _kMaxHexLines) _hexLines.removeAt(0);
      }
    });
  }

  Widget _buildContentView() {
        if (_config.minorType == 'Custom' && _config.sharedMemName == '114514') {
      return const FallBackPage();
    }

        if (_config.debugLevel >= 1) {
      return TtydPage(lines: List.unmodifiable(_hexLines));
    }

        switch (_config.majorType) {
      case 'Chusan':
        return ChusanPage(rawData: _chusanRaw);
      case 'Mu3':
        return Mu3Page(rawData: _mu3Raw);
      case 'Mai2':
        return Mai2Page(rawData: _mai2Raw);
      default:
        return const FallBackPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return ScaffoldPage(
      header: PageHeader(
        title: RevealerOptionBar(
          onConfigChange: _onConfigChange,
          onStart:        _onStart,
          onStop:         _onStop,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          children: [
            const Divider(),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.resources.surfaceStrokeColorDefault,
                    width: 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildContentView(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}