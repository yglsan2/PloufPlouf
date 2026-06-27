import 'package:flutter_test/flutter_test.dart';
import 'package:tirage_equipes/data/team_name_themes.dart';

void main() {
  test('17 thèmes avec 10 noms uniques chacun', () {
    expect(teamNameThemes.length, 17);
    for (final theme in teamNameThemes) {
      expect(theme.noms.length, 10, reason: theme.label);
      expect(theme.noms.toSet().length, 10, reason: theme.label);
      expect(theme.emoji.isNotEmpty, isTrue, reason: theme.label);
    }
  });

  test('pool aléatoire exclut les numéros', () {
    final pool = buildRandomTeamNamePool();
    expect(pool.any((n) => n.startsWith('Équipe ')), isFalse);
    expect(pool.length, greaterThan(50));
  });
}
