import 'package:flutter_test/flutter_test.dart';
import 'package:tirage_equipes/utils/wheel_math.dart';

void main() {
  test('index cohérent après rotation cible', () {
    const n = 8;
    for (var winner = 0; winner < n; winner++) {
      final target = WheelMath.targetRotation(
        segmentCount: n,
        winnerIndex: winner,
        currentRotation: 0,
        extraSpins: 2,
      );
      expect(WheelMath.indexAtPointer(target, n), winner);
    }
  });
}
