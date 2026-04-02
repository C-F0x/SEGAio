import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

typedef NativeCallback = ffi.Void Function(ffi.Pointer<Utf8> jsonResponse);

typedef _RevealerRegisterCallbackC = ffi.Void Function(
    ffi.Pointer<ffi.NativeFunction<NativeCallback>> cb,
    );
typedef _RevealerRegisterCallbackDart = void Function(
    ffi.Pointer<ffi.NativeFunction<NativeCallback>> cb,
    );

typedef _RevealerStartC = ffi.Int32 Function(ffi.Pointer<Utf8> configJson);
typedef _RevealerStartDart = int Function(ffi.Pointer<Utf8> configJson);

typedef _RevealerStopC = ffi.Int32 Function();
typedef _RevealerStopDart = int Function();

class RevealerFfi {
    RevealerFfi._internal() {
    _loadLibrary();
  }
  static final RevealerFfi instance = RevealerFfi._internal();

  late ffi.DynamicLibrary _lib;
  late _RevealerRegisterCallbackDart _registerCallback;
  late _RevealerStartDart _start;
  late _RevealerStopDart _stop;

  void _loadLibrary() {
    try {
            _lib = ffi.DynamicLibrary.open('revealer.dll');

      _registerCallback = _lib
          .lookup<ffi.NativeFunction<_RevealerRegisterCallbackC>>(
          'revealer_register_callback')
          .asFunction();

      _start = _lib
          .lookup<ffi.NativeFunction<_RevealerStartC>>('revealer_start')
          .asFunction();

      _stop = _lib
          .lookup<ffi.NativeFunction<_RevealerStopC>>('revealer_stop')
          .asFunction();

      debugPrint('[FFI] Native library loaded successfully.');
    } catch (e) {
      debugPrint('[FFI] Failed to load native library: $e');
      rethrow;
    }
  }

      void registerCallback(ffi.Pointer<ffi.NativeFunction<NativeCallback>> callbackPtr) {
    _registerCallback(callbackPtr);
  }

      int start(String configJson) {
    final ptr = configJson.toNativeUtf8();
    try {
      return _start(ptr);
    } finally {
            malloc.free(ptr);
    }
  }

    int stop() {
    return _stop();
  }
}