import 'dart:ffi' as ffi;
import 'dart:convert';
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
typedef _FreeC = ffi.Void Function(ffi.Pointer<Utf8> ptr);
typedef _FreeDart = void Function(ffi.Pointer<Utf8> ptr);

class RevealerFfi {
  RevealerFfi._internal() {
    _loadLibrary();
  }
  static final RevealerFfi instance = RevealerFfi._internal();

  late ffi.DynamicLibrary _lib;
  late _RevealerRegisterCallbackDart _registerCallback;
  late _RevealerStartDart _start;
  late _RevealerStopDart _stop;
  late _FreeDart _freeString;

  ffi.NativeCallable<NativeCallback>? _currCallable;

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

      _freeString = _lib
          .lookup<ffi.NativeFunction<_FreeC>>('revealer_free_string')
          .asFunction();

      debugPrint('[FFI] Native library loaded successfully.');
    } catch (e) {
      debugPrint('[FFI] Failed to load native library: $e');
      rethrow;
    }
  }

  int start(Map config, Function(Map data) onData) {
    _currCallable?.close();
    _currCallable = ffi.NativeCallable<NativeCallback>.listener((ffi.Pointer<Utf8> jsonPtr) {
      try {
        final jsonString = jsonPtr.toDartString();
        final Map<String, dynamic> data = jsonDecode(jsonString);
        onData(data);
      } catch (e) {
        debugPrint('[FFI] Callback Error: $e');
      } finally {
        _freeString(jsonPtr);
      }
    });

    _registerCallback(_currCallable!.nativeFunction);

    final configStr = jsonEncode(config);
    final ptr = configStr.toNativeUtf8();
    try {
      return _start(ptr);
    } finally {
      malloc.free(ptr);
    }
  }

  int stop() {
    final result = _stop();
    _currCallable?.close();
    _currCallable = null;
    return result;
  }
}