import 'dart:async';

import 'package:flutter/services.dart';

import '../services/plouf_sound_service.dart';

/// Retours sonores et haptiques — sons désactivables dans les paramètres.
class SoundFeedback {
  SoundFeedback._();

  static void tick() {
    HapticFeedback.selectionClick();
    unawaited(PloufSoundService.instance.play(PloufSound.tick));
  }

  static void spin() {
    HapticFeedback.lightImpact();
    unawaited(PloufSoundService.instance.play(PloufSound.spin));
  }

  static void win() {
    HapticFeedback.mediumImpact();
    unawaited(PloufSoundService.instance.play(PloufSound.win));
  }

  static void plouf() {
    HapticFeedback.heavyImpact();
    unawaited(PloufSoundService.instance.play(PloufSound.plouf));
  }

  static void teamsReady() {
    HapticFeedback.mediumImpact();
    unawaited(PloufSoundService.instance.play(PloufSound.teams));
  }
}
