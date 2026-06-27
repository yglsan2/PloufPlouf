import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'sound_preferences_service.dart';

enum PloufSound {
  tick('sounds/tick.wav'),
  plouf('sounds/plouf.wav'),
  spin('sounds/spin.wav'),
  win('sounds/win.wav'),
  teams('sounds/teams.wav');

  const PloufSound(this.asset);
  final String asset;
}

/// Lecture des effets sonores PloufPlouf (assets WAV).
class PloufSoundService {
  PloufSoundService._();
  static final PloufSoundService instance = PloufSoundService._();

  AudioPlayer? _player;
  AudioPlayer? _overlayPlayer;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    try {
      _player = AudioPlayer();
      _overlayPlayer = AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.stop);
      await _overlayPlayer!.setReleaseMode(ReleaseMode.stop);
      await _player!.setVolume(0.85);
      await _overlayPlayer!.setVolume(0.85);
      _ready = true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('PloufSoundService: audio indisponible ($e)');
        debugPrint('$st');
      }
      _ready = false;
    }
  }

  Future<void> dispose() async {
    await _player?.dispose();
    await _overlayPlayer?.dispose();
    _player = null;
    _overlayPlayer = null;
    _ready = false;
  }

  Future<void> play(PloufSound sound) async {
    if (!_ready || !SoundPreferencesService.instance.enabled) return;
    final player = _player;
    if (player == null) return;
    try {
      await player.stop();
      await player.play(AssetSource(sound.asset));
    } catch (_) {}
  }

  Future<void> playOverlay(PloufSound sound) async {
    if (!_ready || !SoundPreferencesService.instance.enabled) return;
    final player = _overlayPlayer;
    if (player == null) return;
    try {
      await player.play(AssetSource(sound.asset));
    } catch (_) {}
  }

  /// Aperçu depuis les paramètres (joue même si les sons sont coupés).
  Future<void> preview(PloufSound sound) async {
    if (!_ready) await init();
    if (!_ready) return;
    final player = _player;
    if (player == null) return;
    try {
      await player.stop();
      await player.play(AssetSource(sound.asset));
    } catch (_) {}
  }
}
