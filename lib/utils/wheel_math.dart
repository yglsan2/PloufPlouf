import 'dart:math';

/// Calculs pour aligner la roue sur l'index gagnant (pointeur en haut).
class WheelMath {
  WheelMath._();

  static const twoPi = 2 * pi;

  /// Rotation finale (radians) pour que [winnerIndex] soit sous le pointeur.
  static double targetRotation({
    required int segmentCount,
    required int winnerIndex,
    required double currentRotation,
    int extraSpins = 4,
  }) {
    if (segmentCount <= 0) return currentRotation;
    final slice = twoPi / segmentCount;
    var target = -pi / 2 - (winnerIndex + 0.5) * slice;
    while (target <= currentRotation) {
      target += twoPi;
    }
    return target + extraSpins * twoPi;
  }

  /// Index du segment sous le pointeur (haut de l'écran).
  static int indexAtPointer(double rotation, int segmentCount) {
    if (segmentCount <= 0) return 0;
    final slice = twoPi / segmentCount;
    var local = (-pi / 2 - rotation) % twoPi;
    if (local < 0) local += twoPi;
    return (local / slice).floor().clamp(0, segmentCount - 1);
  }
}
