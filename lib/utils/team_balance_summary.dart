/// Résumé lisible de la qualité d'un tirage d'équipes (jauge de confiance).
class TeamBalanceSummary {
  const TeamBalanceSummary({
    required this.teamCount,
    required this.participantCount,
    required this.teamSizes,
    required this.minSize,
    required this.maxSize,
    required this.sizesBalanced,
    required this.fgRequested,
    required this.fgWellDistributed,
    required this.fillesTotal,
    required this.garconsTotal,
    required this.sansGenreTotal,
    required this.fPerTeam,
    required this.mPerTeam,
    required this.incompatibilityViolations,
    required this.scorePercent,
  });

  final int teamCount;
  final int participantCount;
  final List<int> teamSizes;
  final int minSize;
  final int maxSize;
  final bool sizesBalanced;
  final bool fgRequested;
  final bool fgWellDistributed;
  final int fillesTotal;
  final int garconsTotal;
  final int sansGenreTotal;
  final List<int> fPerTeam;
  final List<int> mPerTeam;
  final int incompatibilityViolations;
  final int scorePercent;

  factory TeamBalanceSummary.compute({
    required List<List<String>> equipes,
    required Map<String, String?> genreByName,
    required bool fgRequested,
    int incompatibilityViolations = 0,
  }) {
    final sizes = equipes.map((e) => e.length).toList();
    final minS = sizes.isEmpty ? 0 : sizes.reduce((a, b) => a < b ? a : b);
    final maxS = sizes.isEmpty ? 0 : sizes.reduce((a, b) => a > b ? a : b);
    final balanced = maxS - minS <= 1;

    var fTotal = 0;
    var mTotal = 0;
    var unk = 0;
    final fTeams = List<int>.filled(equipes.length, 0);
    final mTeams = List<int>.filled(equipes.length, 0);

    for (var t = 0; t < equipes.length; t++) {
      for (final nom in equipes[t]) {
        final g = genreByName[nom];
        if (g == 'F') {
          fTotal++;
          fTeams[t]++;
        } else if (g == 'M') {
          mTotal++;
          mTeams[t]++;
        } else {
          unk++;
        }
      }
    }

    var fgOk = true;
    if (fgRequested && (fTotal > 0 || mTotal > 0)) {
      if (fTeams.isNotEmpty) {
        final fMin = fTeams.reduce((a, b) => a < b ? a : b);
        final fMax = fTeams.reduce((a, b) => a > b ? a : b);
        if (fMax - fMin > 1) fgOk = false;
      }
      if (mTeams.isNotEmpty) {
        final mMin = mTeams.reduce((a, b) => a < b ? a : b);
        final mMax = mTeams.reduce((a, b) => a > b ? a : b);
        if (mMax - mMin > 1) fgOk = false;
      }
    }

    var score = 100;
    if (!balanced) score -= 15;
    if (fgRequested && !fgOk) score -= 20;
    if (incompatibilityViolations > 0) {
      score -= (incompatibilityViolations * 8).clamp(0, 40);
    }
    if (score < 0) score = 0;

    return TeamBalanceSummary(
      teamCount: equipes.length,
      participantCount: sizes.fold(0, (a, b) => a + b),
      teamSizes: sizes,
      minSize: minS,
      maxSize: maxS,
      sizesBalanced: balanced,
      fgRequested: fgRequested,
      fgWellDistributed: fgOk,
      fillesTotal: fTotal,
      garconsTotal: mTotal,
      sansGenreTotal: unk,
      fPerTeam: fTeams,
      mPerTeam: mTeams,
      incompatibilityViolations: incompatibilityViolations,
      scorePercent: score,
    );
  }

  List<String> get highlights {
    final lines = <String>[];
    lines.add(
      sizesBalanced
          ? 'Effectifs équilibrés ($minSize–$maxSize par équipe)'
          : 'Écarts d\'effectif : $minSize à $maxSize élèves',
    );
    if (fgRequested && (fillesTotal > 0 || garconsTotal > 0)) {
      lines.add(
        fgWellDistributed
            ? 'F/G bien réparti ($fillesTotal F · $garconsTotal G)'
            : 'Répartition F/G à ajuster ($fillesTotal F · $garconsTotal G)',
      );
    } else if (fillesTotal > 0 || garconsTotal > 0) {
      lines.add('$fillesTotal fille(s) · $garconsTotal garçon(s) dans les équipes');
    }
    if (incompatibilityViolations == 0) {
      lines.add('Toutes les contraintes respectées');
    } else {
      lines.add(
        '$incompatibilityViolations contrainte(s) non respectée(s) — répartition au mieux',
      );
    }
    return lines;
  }
}
