import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import '../shared/bridge/revealer_ffi.dart';

class RevealerConfig {
  final String majorType;
  final String minorType;
  final int pollMs;
  final int debugLevel;

  const RevealerConfig({
    required this.majorType,
    required this.minorType,
    this.pollMs = 10,
    this.debugLevel = 0,
  });

  Map<String, dynamic> toJson() => {
    'majorType': majorType,
    'minorType': minorType,
    'pollMs': pollMs,
    'debugLevel': debugLevel,
  };

  String toJsonString() => jsonEncode(toJson());
}

class RevealerPatch {
  final String? chusanRaw;   final String? hexLine;   
  RevealerPatch({this.chusanRaw, this.hexLine});

  factory RevealerPatch.fromJson(Map<String, dynamic> json) {
    return RevealerPatch(
      chusanRaw: json['chusan_raw'],
      hexLine: json['hex_line'],
    );
  }
}

class GoRevealerBridge {
  GoRevealerBridge._internal() {
    _init();
  }
  static final GoRevealerBridge instance = GoRevealerBridge._internal();

  final _ffi = RevealerFfi.instance;
  final _ctrl = StreamController<RevealerPatch>.broadcast();

    Stream<RevealerPatch> get patches => _ctrl.stream;

  bool _running = false;
  bool get isRunning => _running;

    late ffi.NativeCallable<NativeCallback> _nativeCallable;

  void _init() {
        _nativeCallable = ffi.NativeCallable<NativeCallback>.listener(_onNativePatch);
    _ffi.registerCallback(_nativeCallable.nativeFunction);
  }

    static void _onNativePatch(ffi.Pointer<Utf8> jsonPtr) {
    try {
      final jsonStr = jsonPtr.toDartString();
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      final patch = RevealerPatch.fromJson(map);

            instance._ctrl.add(patch);
    } catch (e) {
      debugPrint('[Bridge] Error parsing native patch: $e');
    }
  }

    Future<void> start(RevealerConfig config) async {
    if (_running) await stop();

    _running = true;
    final jsonConfig = config.toJsonString();

        final result = _ffi.start(jsonConfig);

    if (result != 0) {
      _running = false;
      debugPrint('[Bridge] Failed to start Go loop: $result');
    } else {
      debugPrint('[Bridge] Started: ${config.majorType} - ${config.minorType}');
    }
  }

    Future<void> stop() async {
    if (!_running) return;

    _ffi.stop();
    _running = false;
    debugPrint('[Bridge] Stopped');
  }

    void injectRaw(String jsonPatch) {
    try {
      final map = jsonDecode(jsonPatch);
      _ctrl.add(RevealerPatch.fromJson(map));
    } catch (e) {
      debugPrint('[Bridge] Manual inject error: $e');
    }
  }
}