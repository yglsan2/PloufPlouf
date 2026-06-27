// Génère les fichiers WAV dans assets/sounds/ (exécuter : dart run tool/generate_sounds.dart)
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final dir = Directory('assets/sounds');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  _write('tick.wav', _tick());
  _write('plouf.wav', _plouf());
  _write('spin.wav', _spin());
  _write('win.wav', _win());
  _write('teams.wav', _teams());
  stdout.writeln('Sons générés dans assets/sounds/');
}

void _write(String name, Float32List samples) {
  File('assets/sounds/$name').writeAsBytesSync(_encodeWav(samples, 44100));
}

Float32List _tick() {
  return _mix([
    _tone(740, 0.07, vol: 0.35),
    _tone(988, 0.05, delay: 0.02, vol: 0.2),
  ]);
}

Float32List _plouf() {
  return _mix([
    _noise(0.18, vol: 0.45, lowPass: 0.25),
    _tone(180, 0.22, vol: 0.55),
    _tone(120, 0.35, vol: 0.35, slide: -80),
    ..._bubbles(),
  ]);
}

List<Float32List> _bubbles() => [
      _tone(420, 0.06, delay: 0.12, vol: 0.15),
      _tone(520, 0.05, delay: 0.18, vol: 0.12),
      _tone(610, 0.04, delay: 0.24, vol: 0.1),
    ];

Float32List _spin() {
  return _mix([
    _sweep(280, 520, 0.35, vol: 0.28),
    _tone(440, 0.08, vol: 0.12),
  ]);
}

Float32List _win() {
  return _mix([
    _tone(523.25, 0.12, vol: 0.4), // C5
    _tone(659.25, 0.12, delay: 0.1, vol: 0.4), // E5
    _tone(783.99, 0.12, delay: 0.2, vol: 0.4), // G5
    _tone(1046.5, 0.25, delay: 0.32, vol: 0.45), // C6
  ]);
}

Float32List _teams() {
  return _mix([
    _tone(392, 0.15, vol: 0.35), // G4
    _tone(523.25, 0.15, delay: 0.12, vol: 0.38),
    _tone(659.25, 0.15, delay: 0.24, vol: 0.38),
    _tone(783.99, 0.35, delay: 0.36, vol: 0.42),
    _tone(1046.5, 0.4, delay: 0.5, vol: 0.35),
  ]);
}

Float32List _mix(List<Float32List> parts) {
  var maxLen = 0;
  for (final p in parts) {
    if (p.length > maxLen) maxLen = p.length;
  }
  final out = Float32List(maxLen);
  for (final p in parts) {
    for (var i = 0; i < p.length; i++) {
      out[i] += p[i];
    }
  }
  for (var i = 0; i < out.length; i++) {
    out[i] = out[i].clamp(-1.0, 1.0);
  }
  return out;
}

Float32List _tone(
  double freq,
  double duration, {
  double delay = 0,
  double vol = 0.5,
  double slide = 0,
}) {
  const rate = 44100;
  final start = (delay * rate).round();
  final n = (duration * rate).round();
  final out = Float32List(start + n);
  for (var i = 0; i < n; i++) {
    final t = i / rate;
    final f = freq + slide * t;
    final attack = min(1.0, t * 60);
    final release = min(1.0, (duration - t) * 12);
    final env = attack * release;
    out[start + i] = sin(2 * pi * f * t) * vol * env;
  }
  return out;
}

Float32List _sweep(double f0, double f1, double duration, {double vol = 0.4}) {
  const rate = 44100;
  final n = (duration * rate).round();
  final out = Float32List(n);
  for (var i = 0; i < n; i++) {
    final t = i / n;
    final freq = f0 + (f1 - f0) * t;
    final env = sin(pi * t);
    out[i] = sin(2 * pi * freq * (i / rate)) * vol * env;
  }
  return out;
}

Float32List _noise(double duration, {double vol = 0.3, double lowPass = 0.3}) {
  const rate = 44100;
  final n = (duration * rate).round();
  final out = Float32List(n);
  final rand = Random(42);
  var prev = 0.0;
  for (var i = 0; i < n; i++) {
    final raw = (rand.nextDouble() * 2 - 1) * vol;
    prev = prev * lowPass + raw * (1 - lowPass);
    final t = i / n;
    final env = min(1.0, t * 30) * min(1.0, (1 - t) * 8);
    out[i] = prev * env;
  }
  return out;
}

Uint8List _encodeWav(Float32List samples, int sampleRate) {
  final pcm = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i] * 32767).round().clamp(-32768, 32767);
    pcm.setInt16(i * 2, v, Endian.little);
  }
  final dataSize = pcm.lengthInBytes;
  final header = ByteData(44);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  header.setUint32(4, 36 + dataSize, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, 1, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  header.setUint32(40, dataSize, Endian.little);

  return Uint8List.fromList([...header.buffer.asUint8List(), ...pcm.buffer.asUint8List()]);
}
