import 'package:flutter_test/flutter_test.dart';
import 'package:tirage_equipes/utils/team_balance_summary.dart';

void main() {
  test('score élevé si équipes équilibrées', () {
    final summary = TeamBalanceSummary.compute(
      equipes: [
        ['A', 'B'],
        ['C', 'D'],
        ['E', 'F'],
      ],
      genreByName: {
        'A': 'F',
        'B': 'M',
        'C': 'F',
        'D': 'M',
        'E': 'F',
        'F': 'M',
      },
      fgRequested: true,
      incompatibilityViolations: 0,
    );
    expect(summary.sizesBalanced, isTrue);
    expect(summary.fgWellDistributed, isTrue);
    expect(summary.scorePercent, greaterThanOrEqualTo(85));
  });

  test('score réduit si violations', () {
    final summary = TeamBalanceSummary.compute(
      equipes: [
        ['A', 'B', 'C'],
        ['D'],
      ],
      genreByName: {},
      fgRequested: false,
      incompatibilityViolations: 3,
    );
    expect(summary.scorePercent, lessThan(85));
  });
}
