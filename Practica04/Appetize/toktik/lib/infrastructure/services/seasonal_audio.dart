import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Una melodía original generada en memoria: no requiere assets ni descargas.
class SeasonalAudio {
  final AudioPlayer _player = AudioPlayer();
  Future<void> play(List<double> notes) async {
    const rate = 22050;
    const duration = 0.16;
    final samplesPerNote = (rate * duration).round();
    final count = samplesPerNote * notes.length;
    final data = ByteData(44 + count * 2);
    void ascii(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        data.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    data.setUint32(4, 36 + count * 2, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, rate, Endian.little);
    data.setUint32(28, rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    data.setUint32(40, count * 2, Endian.little);
    for (var i = 0; i < count; i++) {
      final local = i % samplesPerNote;
      final envelope = sin(pi * local / samplesPerNote);
      final value =
          (sin(2 * pi * notes[i ~/ samplesPerNote] * local / rate) *
                  envelope *
                  6000)
              .round();
      data.setInt16(44 + i * 2, value, Endian.little);
    }
    await _player.stop();
    await _player.play(
      BytesSource(data.buffer.asUint8List(), mimeType: 'audio/wav'),
      ctx: AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
          .build(),
    );
  }

  Future<void> stop() => _player.stop();
  Future<void> dispose() => _player.dispose();
}
