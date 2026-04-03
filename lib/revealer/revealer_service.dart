import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../shared/bridge/revealer_ffi.dart';
import 'shmem_ptr.dart';

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

  String get sharedMemName => ShmemPtr.get(majorType, minorType);

  Map<String, dynamic> toJson() => {
    'majorType': majorType,
    'minorType': minorType,
    'sharedMemName': sharedMemName,
    'pollMs': pollMs,
    'debugLevel': debugLevel,
  };

  String toJsonString() => jsonEncode({
    'major': majorType,
    'minor': minorType,
    'shmem': sharedMemName,
    'poll_ms': pollMs,
    'debug': debugLevel,
  });
}

class RevealerPatch {
  final String? chusanRaw;
  final String? hexLine;

  RevealerPatch({this.chusanRaw, this.hexLine});

  factory RevealerPatch.fromJson(Map<String, dynamic> json) {
    return RevealerPatch(
      chusanRaw: json['chusan_raw'],
      hexLine: json['hex_line'],
    );
  }
}

class GoRevealerBridge {
  GoRevealerBridge._internal();
  static final GoRevealerBridge instance = GoRevealerBridge._internal();

  final _ffi = RevealerFfi.instance;
  final _ctrl = StreamController<RevealerPatch>.broadcast();

  Stream<RevealerPatch> get patches => _ctrl.stream;

  bool _running = false;
  bool get isRunning => _running;

  Future<void> start(RevealerConfig config) async {
    if (_running) await stop();

    final result = _ffi.start(config.toJson(), (Map data) {
      try {
        final patch = RevealerPatch.fromJson(data.cast<String, dynamic>());
        _ctrl.add(patch);
      } catch (e) {
        debugPrint('[Bridge] Callback parse error: $e');
      }
    });

    if (result != 0) {
      _running = false;
      debugPrint('[Bridge] Failed to start Go loop: $result');
    } else {
      _running = true;
      debugPrint('[Bridge] start ${config.toJsonString()}');
    }
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _ffi.stop();
    debugPrint('[Bridge] stop');
  }

  void injectRaw(String jsonPatch) {
    try {
      final map = jsonDecode(jsonPatch);
      _ctrl.add(RevealerPatch.fromJson(map));
    } catch (e) {
      debugPrint('[Bridge] Manual inject error: $e');
    }
  }

  void dispose() {
    stop();
    _ctrl.close();
  }
}