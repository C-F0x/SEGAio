import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../shared/bridge/revealer_ffi.dart';
import 'shmem_ptr.dart'; // 导入解耦的映射表

// --- 数据模型 ---

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

// --- 注入处理器 ---

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

// --- 通讯协议 ---

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
  final String rawSharedMem; // 改名以避免与 Getter 冲突
  final int    pollIntervalMs;
  final int    debugLevel;

  const RevealerConfig({
    required this.majorType,
    required this.minorType,
    this.rawSharedMem  = '', // UI 传进来的自定义名称
    this.pollIntervalMs = 10,
    this.debugLevel     = 0,
  });

  // 统一计算逻辑：如果是 CUSTOM 则用 UI 传的值，否则去映射表查
  String get effectiveSharedMem =>
      minorType == 'CUSTOM' ? rawSharedMem : ShmemPtr.get(majorType, minorType);

  // FFI 传输：使用计算后的有效 ID，并保持 Key 为 sharedMem
  Map<String, dynamic> toJson() => {
    'majorType':       majorType,
    'minorType':       minorType,
    'sharedMem':       effectiveSharedMem,
    'pollMs':          pollIntervalMs,
    'debugLevel':      debugLevel,
  };

  // 控制台打印：同样使用计算后的名称
  String toJsonString() => jsonEncode({
    'major':           majorType,
    'minor':           minorType,
    'shmem':           effectiveSharedMem,
    'poll_ms':         pollIntervalMs,
    'debug':           debugLevel,
  });
}

// --- 桥接单例 ---

class GoRevealerBridge {
  GoRevealerBridge._internal();
  static final GoRevealerBridge instance = GoRevealerBridge._internal();

  final StreamController<RevealerPatch> _ctrl = StreamController<RevealerPatch>.broadcast();
  Stream<RevealerPatch> get patches => _ctrl.stream;

  bool _running = false;
  bool get isRunning => _running;

  Future<void> start(RevealerConfig config) async {
    if (_running) await stop();

    // 传入根据映射表生成的动态 config
    final result = RevealerFfi.instance.start(config.toJson(), (Map data) {
      try {
        instance._ctrl.add(RevealerPatch.fromJson(data.cast<String, dynamic>()));
      } catch (e) {
        debugPrint('[Bridge] Callback process error: $e');
      }
    });

    if (result != 0) {
      _running = false;
      debugPrint('[Bridge] start failed with code: $result');
    } else {
      _running = true;
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