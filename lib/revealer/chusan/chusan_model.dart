import 'dart:typed_data';
import 'dart:convert';

class ChusanData {
  final List<int> slider;
  final List<bool> air;
  final Uint8List card;
  final bool test;
  final bool service;

  const ChusanData({
    required this.slider,
    required this.air,
    required this.card,
    required this.test,
    required this.service,
  });

    factory ChusanData.zero() => ChusanData(
    slider: List.filled(32, 0),
    air: List.filled(6, false),
    card: Uint8List(10),
    test: false,
    service: false,
  );

              factory ChusanData.fromRaw(Uint8List raw) {
    if (raw.length < 34) return ChusanData.zero();

        final systemByte = raw[0];
    final test = (systemByte & 0x01) != 0;
    final service = (systemByte & 0x02) != 0;

        final airByte = raw[1];
    final air = List.generate(6, (i) => (airByte & (1 << i)) != 0);

        final slider = List<int>.from(raw.sublist(2, 34));

        Uint8List card = Uint8List(10);
    if (raw.length >= 44) {
      card = raw.sublist(34, 44);
    }

    return ChusanData(
      slider: slider,
      air: air,
      card: card,
      test: test,
      service: service,
    );
  }

    factory ChusanData.fromBase64(String? base64str) {
    if (base64str == null || base64str.isEmpty) return ChusanData.zero();
    try {
      return ChusanData.fromRaw(base64.decode(base64str));
    } catch (_) {
      return ChusanData.zero();
    }
  }
}