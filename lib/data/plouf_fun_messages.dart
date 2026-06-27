import 'dart:math';

/// Messages fun affichés pendant la roue et le countdown.
class PloufFunMessages {
  PloufFunMessages._();

  static const _spinning = [
    'La roue décide…',
    'Suspense en classe !',
    'Qui sera le/la chanceux·se ?',
    'Les dés sont jetés…',
    'PloufPlouf réfléchit…',
  ];

  static const _winners = [
    'C\'est lui/elle !',
    'PloufPlouf ! On a un gagnant !',
    'La roue a parlé !',
    'Bravo !',
    'Tadaaa !',
  ];

  static String spinning(Random random) =>
      _spinning[random.nextInt(_spinning.length)];

  static String winner(Random random) =>
      _winners[random.nextInt(_winners.length)];
}
