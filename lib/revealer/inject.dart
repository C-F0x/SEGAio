import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import '../shared/bridge/revealer_ffi.dart';


class ChusanData {
  final List<int> slider;
  final List<int> air;
  final Uint8List card;

  const ChusanData({
    required this.slider,
    required this.air,
    required this.card,
  });

  static ChusanData get zero => ChusanData(
    slider: List.filled(32, 0),
    air:    List.filled(6,  0),
    card:   Uint8List(10),
  );
}

class Mu3Data {
  final int        stick;
  final List<bool> buttons;

  const Mu3Data({required this.stick, required this.buttons});

  static Mu3Data get zero =>
      Mu3Data(stick: 0, buttons: List.filled(9, false));
}

class Mai2Data {
  final List<bool> a;
  final List<bool> b;
  final List<bool> c;
  final List<bool> d;
  final List<bool> e;

  const Mai2Data({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.e,
  });

  static Mai2Data get zero => Mai2Data(
    a: List.filled(8, false),
    b: List.filled(8, false),
    c: List.filled(2, false),
    d: List.filled(8, false),
    e: List.filled(8, false),
  );
}


class ChusanGoInject {
  static const int kSize = 48;
  final Uint8List raw;
  const ChusanGoInject(this.raw);

  ChusanData inject() {
    if (raw.length < kSize) return ChusanData.zero;
    return ChusanData(
      slider: raw.sublist(0,  32),
      air:    raw.sublist(32, 38),
      card:   raw.sublist(38, 48),
    );
  }
}

class Mu3GoInject {
  static const int kSize = 4;
  final Uint8List raw;
  const Mu3GoInject(this.raw);

  Mu3Data inject() {
    if (raw.length < kSize) return Mu3Data.zero;
    final bd      = raw.buffer.asByteData(raw.offsetInBytes, kSize);
    final stick   = bd.getInt16(0,  Endian.little);
    final btnMask = bd.getUint16(2, Endian.little);
    return Mu3Data(
      stick:   stick,
      buttons: List.generate(9, (i) => (btnMask >> i) & 1 == 1),
    );
  }
}

class Mai2GoInject {
  static const int kSize = 5;
  final Uint8List raw;
  const Mai2GoInject(this.raw);

  Mai2Data inject() {
    if (raw.length < kSize) return Mai2Data.zero;
    List<bool> b8(int byte) => List.generate(8, (i) => (byte >> i) & 1 == 1);
    return Mai2Data(
      a: b8(raw[0]),
      b: b8(raw[1]),
      c: [(raw[2] & 1) == 1, (raw[2] >> 1 & 1) == 1],
      d: b8(raw[3]),
      e: b8(raw[4]),
    );
  }
}


class RevealerPatch {
  final Uint8List? chusanRaw;
  final Uint8List? mu3Raw;
  final Uint8List? mai2Raw;
  final String?    hexLine;

  const RevealerPatch({
    this.chusanRaw,
    this.mu3Raw,
    this.mai2Raw,
    this.hexLine,
  });

  factory RevealerPatch.fromJson(Map<String, dynamic> j) {
    Uint8List? dec(String k) {
      final v = j[k];
      if (v == null || (v as String).isEmpty) return null;
      try {
        return base64Decode(v);
      } catch (e) {
        debugPrint('[Patch] base64 decode error for key $k: $e');
        return null;
      }
    }
    return RevealerPatch(
      chusanRaw: dec('chusan_raw'),
      mu3Raw:    dec('mu3_raw'),
      mai2Raw:   dec('mai2_raw'),
      hexLine:   j['hex_line'] as String?,
    );
  }
}

class RevealerConfig {
  final String majorType;
  final String minorType;
  final String sharedMemName;
  final int    pollIntervalMs;
  final int    debugLevel;

  const RevealerConfig({
    required this.majorType,
    required this.minorType,
    this.sharedMemName  = '',
    this.pollIntervalMs = 10,
    this.debugLevel     = 0,
  });

  Map<String, dynamic> toJson() => {
    'major':           majorType,
    'minor':           minorType,
    'shared_mem_name': sharedMemName,
    'poll_ms':         pollIntervalMs,
    'debug':           debugLevel,
  };

  String toJsonString() => jsonEncode(toJson());
}


class GoRevealerBridge {
  GoRevealerBridge._internal() {
    _init();
  }
  static final GoRevealerBridge instance = GoRevealerBridge._internal();

  final StreamController<RevealerPatch> _ctrl = StreamController<RevealerPatch>.broadcast();
  Stream<RevealerPatch> get patches => _ctrl.stream;

  bool _running = false;
  bool get isRunning => _running;

    late ffi.NativeCallable<NativeCallback> _nativeCallable;

  void _init() {
        _nativeCallable = ffi.NativeCallable<NativeCallback>.listener(_onNativePatch);
    RevealerFfi.instance.registerCallback(_nativeCallable.nativeFunction);
  }

  static void _onNativePatch(ffi.Pointer<Utf8> jsonPtr) {
    try {
      final jsonStr = jsonPtr.toDartString();
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      instance._ctrl.add(RevealerPatch.fromJson(map));
    } catch (e) {
      debugPrint('[Bridge] _onNativePatch error: $e');
    }
  }

  Future<void> start(RevealerConfig config) async {
    if (_running) await stop();
    _running = true;

        final result = RevealerFfi.instance.start(config.toJsonString());
    if (result != 0) {
      _running = false;
      debugPrint('[Bridge] start failed with code: $result');
    } else {
      debugPrint('[Bridge] start ${config.toJsonString()}');
    }
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;

    RevealerFfi.instance.stop();
    debugPrint('[Bridge] stop');
  }

  void injectRaw(String jsonPatch) {
    try {
      _ctrl.add(RevealerPatch.fromJson(
          jsonDecode(jsonPatch) as Map<String, dynamic>));
    } catch (e) {
      debugPrint('[Bridge] bad patch JSON: $e');
    }
  }

  void dispose() {
    stop();
    _ctrl.close();
  }
}