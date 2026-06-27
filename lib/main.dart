import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:share_plus/share_plus.dart';

import 'app_version.dart';
import 'data/team_name_themes.dart';
import 'export_equipes.dart';
import 'import_fichier.dart';
import 'services/pick_fairness_service.dart';
import 'services/plouf_sound_service.dart';
import 'services/sound_preferences_service.dart';
import 'utils/sound_feedback.dart';
import 'utils/team_balance_summary.dart';
import 'widgets/name_wheel_tab.dart';
import 'widgets/plouf_countdown_overlay.dart';
import 'widgets/settings_sheet.dart';
import 'widgets/team_balance_summary_card.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PickFairnessService.init();
  await SoundPreferencesService.init();
  await PloufSoundService.instance.init();
  runApp(const PloufPloufApp());
}

class PloufPloufApp extends StatelessWidget {
  const PloufPloufApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PloufPlouf',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        // Scroll tactile fluide (glissement au doigt) sur mobile
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            scrollbars: true,
            overscroll: true,
          ),
          child: child!,
        );
      },
      home: const TirageEquipesPage(),
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E3A5F),
      brightness: brightness,
      primary: const Color(0xFF1E3A5F),
      secondary: const Color(0xFF3B5998),
      surface: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: colorScheme.primary, size: 26),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.3 : 0.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          minimumSize: const Size(72, 48), // 48dp min pour cible tactile (Material)
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48), // Cible tactile 48dp minimum
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minVerticalPadding: 8, // Hauteur minimale pour le doigt
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        indicatorSize: TabBarIndicatorSize.label,
        labelPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: const TextStyle(fontSize: 15),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// Genre pour la répartition équilibrée : F = fille, M = garçon, null = non précisé
class Eleve {
  String prenom;
  String nom;
  bool participe;
  bool volontaire;
  String? genre; // "F" = fille, "M" = garçon, null = non précisé

  Eleve({
    this.prenom = '',
    this.nom = '',
    this.participe = false,
    this.volontaire = false,
    this.genre,
  });

  /// Nom affiché (prénom + nom). Vide si les deux sont vides.
  String get displayName {
    final p = (prenom).trim();
    final n = (nom).trim();
    if (p.isEmpty && n.isEmpty) return '';
    if (p.isEmpty) return n;
    if (n.isEmpty) return p;
    return '$p $n';
  }
}

class TirageEquipesPage extends StatefulWidget {
  const TirageEquipesPage({super.key});

  @override
  State<TirageEquipesPage> createState() => _TirageEquipesPageState();
}

class _TirageEquipesPageState extends State<TirageEquipesPage> {
  static const int maxEleves = 50;
  static const int initialElevesCount = 15;

  final List<Eleve> _eleves = List.generate(
    initialElevesCount,
    (i) => Eleve(nom: 'Élève ${i + 1}'),
  );
  /// _incompatibles[i] = ensemble des indices j tels que i et j ne doivent pas être dans la même équipe
  final List<Set<int>> _incompatibles = List.generate(initialElevesCount, (_) => {});
  /// _choixEtreAvec[i] = indice de la personne avec qui i souhaite être (null = pas de choix)
  final List<int?> _choixEtreAvec = List.filled(initialElevesCount, null);
  /// _exclusion[i] = indice de la personne que i exclut (null = pas d'exclusion)
  final List<int?> _exclusion = List.filled(initialElevesCount, null);

  List<List<String>> _equipesResultat = [];
  List<String> _nomsEquipesAffiches = []; // noms affichés (modifiables)
  List<String> _tirageResultat = [];
  int _nbGagnantsTirage = 1;
  int _themeNomsEquipes = 0; // index dans teamNameThemes
  bool _nomsEquipesAleatoire = false;
  List<String> _nomsEquipesAleatoiresCourants = [];
  /// Répartir filles et garçons équitablement dans les équipes
  bool _repartirFillesGarcons = false;
  /// Tirage semi-choisi : null | 'choix' (chacun choisit 1) | 'exclusion' (chacun exclut 1) | 'vote' (vote discret)
  String? _modeSemiChoisi;
  /// Dernier tirage sauvegardé (pour revanche et "éviter de répéter")
  ({List<List<String>> equipes, List<String> nomsEquipes})? _dernierTirage;
  /// Éviter de remettre ensemble les coéquipiers du dernier tirage
  bool _eviterRepeterEquipes = false;
  /// Paires (i,j) qui étaient dans la même équipe au dernier tirage (clé "i,j" avec i<j)
  final Set<String> _memeEquipeDerniereFois = {};
  /// Historique des tirages (pour prise en compte sur plusieurs parties)
  final List<({List<List<String>> equipes, List<String> nomsEquipes})> _historiqueEquipes = [];
  final Random _random = Random();
  /// Clé pour scroller vers la section Résultat après un tirage
  final GlobalKey _resultSectionKey = GlobalKey();
  /// Si true, les lignes remplies (prénom ou nom) sont cochées automatiquement pour la participation.
  bool _cocherIdentitesAuto = false;
  /// Compteur pour réinitialiser le zoom de la grille après chaque tirage (évite le zoom bloqué).
  int _grilleZoomKey = 0;
  /// Si true, les options avancées (incompatibilités, semi-choisi, etc.) sont affichées.
  bool _optionsSpecialesVisibles = false;
  /// Favoriser les élèves moins souvent tirés (roue + tirage au sort).
  bool _favoriserEquite = true;
  /// Violations d'incompatibilités du dernier tirage (pour la jauge).
  int _lastIncompatibilityViolations = 0;

  @override
  void initState() {
    super.initState();
    PickFairnessService.instance.addListener(_onFairnessUpdate);
  }

  @override
  void dispose() {
    PickFairnessService.instance.removeListener(_onFairnessUpdate);
    super.dispose();
  }

  void _onFairnessUpdate() {
    if (mounted) setState(() {});
  }

  List<String> get _nomsPresents => [
        for (var i = 0; i < _eleves.length; i++)
          if (_eleves[i].participe) _nomAffiche(i),
      ];

  Map<String, String?> _genreParNom() => {
        for (var i = 0; i < _eleves.length; i++) _nomAffiche(i): _eleves[i].genre,
      };

  TeamBalanceSummary? get _balanceSummary {
    if (_equipesResultat.isEmpty) return null;
    return TeamBalanceSummary.compute(
      equipes: _equipesResultat,
      genreByName: _genreParNom(),
      fgRequested: _repartirFillesGarcons,
      incompatibilityViolations: _lastIncompatibilityViolations,
    );
  }

  Future<void> _lancerEquipesAvecCountdown(int nbEquipes) async {
    await PloufCountdownOverlay.show(context);
    if (!mounted) return;
    _faireEquipes(nbEquipes);
  }

  Future<void> _lancerTirageAvecCountdown(int nbGagnants) async {
    await PloufCountdownOverlay.show(context);
    if (!mounted) return;
    _faireTirage(nbGagnants);
  }

  Future<void> _partagerEquipes() async {
    if (_equipesResultat.isEmpty) return;
    await Share.share(
      buildEquipesShareText(_equipesResultat, _nomsEquipesAffiches),
      subject: 'Équipes PloufPlouf',
    );
  }

  List<String> _genererNomsAleatoires() {
    final pool = buildRandomTeamNamePool()..shuffle(_random);
    return pool.take(10).toList();
  }
  final GlobalKey<_TirageNumberFieldState> _tirageNumberKey =
      GlobalKey<_TirageNumberFieldState>();

  bool _estIncompatibleAvecEquipe(int idx, List<int> teamIndices) {
    for (final q in teamIndices) {
      if (_incompatibles[idx].contains(q)) {
        return true;
      }
      if (_modeSemiChoisi == 'exclusion' &&
          (_exclusion[idx] == q || _exclusion[q] == idx)) {
        return true;
      }
      if (_eviterRepeterEquipes && _memeEquipeDerniereFois.isNotEmpty) {
        final a = idx < q ? idx : q;
        final b = idx < q ? q : idx;
        if (_memeEquipeDerniereFois.contains('$a,$b')) return true;
      }
    }
    return false;
  }

  /// Nom affiché pour l'élève d'indice i (jamais vide : "Élève N" si prénom+nom vides).
  String _nomAffiche(int i) {
    final d = _eleves[i].displayName;
    return d.isEmpty ? 'Élève ${i + 1}' : d;
  }

  /// True si la ligne est vide ou contient uniquement le libellé par défaut "Élève N".
  bool _isLigneVideOuDefaut(int i) {
    final e = _eleves[i];
    final p = e.prenom.trim();
    final n = e.nom.trim();
    if (p.isNotEmpty) return false;
    if (n.isEmpty) return true;
    return RegExp(r'^Élève \d+$').hasMatch(n);
  }

  /// True si le nom est le libellé par défaut "Élève N" (à ne pas pré-remplir dans le champ Nom).
  static bool _isNomDefaut(String nom) {
    final n = nom.trim();
    return n.isNotEmpty && RegExp(r'^Élève \d+$').hasMatch(n);
  }

  /// Construit _memeEquipeDerniereFois à partir du dernier tirage (et historique) pour les participants actuels.
  void _construireMemeEquipeDerniereFois(List<int> participantIndices) {
    _memeEquipeDerniereFois.clear();
    final nomsToIndex = <String, int>{};
    for (final i in participantIndices) {
      nomsToIndex[_nomAffiche(i)] = i;
    }
    void addPairsFromDraw(List<List<String>> equipes) {
      for (final equipe in equipes) {
        final indices = <int>[];
        for (final nom in equipe) {
          final idx = nomsToIndex[nom];
          if (idx != null) indices.add(idx);
        }
        for (var i = 0; i < indices.length; i++) {
          for (var j = i + 1; j < indices.length; j++) {
            final a = indices[i] < indices[j] ? indices[i] : indices[j];
            final b = indices[i] < indices[j] ? indices[j] : indices[i];
            _memeEquipeDerniereFois.add('$a,$b');
          }
        }
      }
    }
    if (_dernierTirage != null) addPairsFromDraw(_dernierTirage!.equipes);
  }

  void _faireEquipes(int nbEquipes) {
    final participantIndices = [
      for (var i = 0; i < _eleves.length; i++)
        if (_eleves[i].participe) i
    ];
    if (participantIndices.length < nbEquipes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Il faut au moins $nbEquipes participants (${participantIndices.length} cochés).',
          ),
        ),
      );
      return;
    }
    if (_eviterRepeterEquipes && _dernierTirage != null) {
      _construireMemeEquipeDerniereFois(participantIndices);
    } else {
      _memeEquipeDerniereFois.clear();
    }
    final equipesIndices = List.generate(nbEquipes, (_) => <int>[]);
    var violations = 0;
    final assigne = <int>{};

    if (_repartirFillesGarcons) {
      final filles = [
        for (final i in participantIndices)
          if (_eleves[i].genre == 'F') i
      ];
      final garcons = [
        for (final i in participantIndices)
          if (_eleves[i].genre == 'M') i
      ];
      final autres = [
        for (final i in participantIndices)
          if (_eleves[i].genre != 'F' && _eleves[i].genre != 'M') i
      ];
      filles.shuffle(_random);
      garcons.shuffle(_random);
      autres.shuffle(_random);
      for (var i = 0; i < filles.length; i++) {
        equipesIndices[i % nbEquipes].add(filles[i]);
      }
      for (var i = 0; i < garcons.length; i++) {
        equipesIndices[i % nbEquipes].add(garcons[i]);
      }
      for (var i = 0; i < autres.length; i++) {
        equipesIndices[i % nbEquipes].add(autres[i]);
      }
      violations = _corrigerIncompatiblesDansEquipes(equipesIndices, nbEquipes);
    } else if (_modeSemiChoisi == 'choix' || _modeSemiChoisi == 'vote') {
      participantIndices.shuffle(_random);
      for (final idx in participantIndices) {
        if (assigne.contains(idx)) continue;
        final j = _choixEtreAvec[idx];
        int? teamChoice = -1;
        if (j != null && !assigne.contains(j)) {
          for (var t = 0; t < nbEquipes; t++) {
            if (!_estIncompatibleAvecEquipe(idx, equipesIndices[t]) &&
                !_estIncompatibleAvecEquipe(j, equipesIndices[t])) {
              teamChoice = t;
              break;
            }
          }
          if (teamChoice != null && teamChoice >= 0) {
            equipesIndices[teamChoice].add(idx);
            equipesIndices[teamChoice].add(j);
            assigne.add(idx);
            assigne.add(j);
            continue;
          }
        }
        if (j != null && assigne.contains(j)) {
          for (var t = 0; t < nbEquipes; t++) {
            if (equipesIndices[t].contains(j) &&
                !_estIncompatibleAvecEquipe(idx, equipesIndices[t])) {
              teamChoice = t;
              break;
            }
          }
        }
        if (teamChoice != null && teamChoice >= 0) {
          equipesIndices[teamChoice].add(idx);
          assigne.add(idx);
          continue;
        }
        var bestTeam = -1;
        var bestSize = -1;
        for (var t = 0; t < nbEquipes; t++) {
          if (!_estIncompatibleAvecEquipe(idx, equipesIndices[t])) {
            final size = equipesIndices[t].length;
            if (bestTeam == -1 || size < bestSize) {
              bestTeam = t;
              bestSize = size;
            }
          }
        }
        if (bestTeam == -1) {
          bestTeam = 0;
          for (var t = 1; t < nbEquipes; t++) {
            if (equipesIndices[t].length < equipesIndices[bestTeam].length) {
              bestTeam = t;
            }
          }
          violations++;
        }
        equipesIndices[bestTeam].add(idx);
        assigne.add(idx);
      }
    } else {
      participantIndices.shuffle(_random);
      for (final idx in participantIndices) {
        var bestTeam = -1;
        var bestSize = -1;
        for (var t = 0; t < nbEquipes; t++) {
          if (!_estIncompatibleAvecEquipe(idx, equipesIndices[t])) {
            final size = equipesIndices[t].length;
            if (bestTeam == -1 || size < bestSize) {
              bestTeam = t;
              bestSize = size;
            }
          }
        }
        if (bestTeam == -1) {
          bestTeam = 0;
          for (var t = 1; t < nbEquipes; t++) {
            if (equipesIndices[t].length < equipesIndices[bestTeam].length) {
              bestTeam = t;
            }
          }
          violations++;
        }
        equipesIndices[bestTeam].add(idx);
      }
    }

    final equipes = equipesIndices
        .map((indices) =>
            indices.map((i) => _nomAffiche(i)).toList())
        .toList();
    setState(() {
      _equipesResultat = equipes;
      _lastIncompatibilityViolations = violations;
      if (_nomsEquipesAleatoire) {
        _nomsEquipesAleatoiresCourants = _genererNomsAleatoires();
      }
      _nomsEquipesAffiches = List.generate(nbEquipes, (i) => _nomEquipe(i + 1));
      _dernierTirage = (
        equipes: equipes.map((e) => List<String>.from(e)).toList(),
        nomsEquipes: List<String>.from(_nomsEquipesAffiches),
      );
      if (_historiqueEquipes.length >= 20) _historiqueEquipes.removeAt(0);
      _historiqueEquipes.add(_dernierTirage!);
      _grilleZoomKey++; // Réinitialise le zoom de la grille pour éviter qu'il reste bloqué
    });
    SoundFeedback.teamsReady();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nbEquipes équipes constituées !'),
        duration: const Duration(seconds: 2),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
    if (violations > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de respecter toutes les incompatibilités pour $violations personne(s). Elles ont été réparties au mieux.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Tente de corriger les incompatibilités par échanges entre équipes. Retourne le nombre de violations restantes.
  int _corrigerIncompatiblesDansEquipes(
    List<List<int>> equipesIndices,
    int nbEquipes,
  ) {
    var violations = 0;
    for (var t = 0; t < nbEquipes; t++) {
      final team = equipesIndices[t];
      for (var i = 0; i < team.length; i++) {
        for (var j = i + 1; j < team.length; j++) {
          final a = team[i];
          final b = team[j];
          final a2 = a < b ? a : b;
          final b2 = a < b ? b : a;
          final incompatible = _incompatibles[a].contains(b) ||
              (_modeSemiChoisi == 'exclusion' &&
                  (_exclusion[a] == b || _exclusion[b] == a)) ||
              (_eviterRepeterEquipes &&
                  _memeEquipeDerniereFois.contains('$a2,$b2'));
          if (incompatible) {
            var swapped = false;
            for (var t2 = 0; t2 < nbEquipes && !swapped; t2++) {
              if (t2 == t) continue;
              for (var k = 0; k < equipesIndices[t2].length && !swapped; k++) {
                final c = equipesIndices[t2][k];
                final teamT2 = equipesIndices[t2];
                final cOkDansT = team.every((q) => q == a || !_incompatibles[c].contains(q));
                final aOkDansT2 = teamT2.every((q) => q == c || !_incompatibles[a].contains(q));
                if (!_incompatibles[a].contains(c) &&
                    !_incompatibles[b].contains(c) &&
                    cOkDansT &&
                    aOkDansT2) {
                  team[i] = c;
                  equipesIndices[t2][k] = a;
                  swapped = true;
                }
              }
            }
            if (!swapped) violations++;
          }
        }
      }
    }
    return violations;
  }

  void _revanche() {
    if (_dernierTirage == null) return;
    _rejouerAvecTirage(_dernierTirage!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mêmes équipes qu\'au dernier tirage : c\'est parti pour la revanche !'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _rejouerAvecTirage(({List<List<String>> equipes, List<String> nomsEquipes}) tirage) {
    setState(() {
      _equipesResultat = tirage.equipes
          .map((e) => List<String>.from(e))
          .toList();
      _nomsEquipesAffiches = List<String>.from(tirage.nomsEquipes);
    });
  }

  void _ouvrirHistoriqueEquipes() {
    if (_historiqueEquipes.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Anciens tirages',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _historiqueEquipes.length,
                itemBuilder: (context, i) {
                  final h = _historiqueEquipes[_historiqueEquipes.length - 1 - i];
                  final nbEquipes = h.equipes.length;
                  final nbParticipant = h.equipes.fold<int>(0, (s, e) => s + e.length);
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('${_historiqueEquipes.length - i}'),
                    ),
                    title: Text('$nbEquipes équipes, $nbParticipant participants'),
                    subtitle: Text(
                      h.nomsEquipes.take(3).join(', ') +
                          (h.nomsEquipes.length > 3 ? '…' : ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _rejouerAvecTirage(h);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Équipes restaurées. C\'est parti !'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text('Rejouer'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _faireTirage(int nbGagnants) {
    final volontaires = [
      for (var i = 0; i < _eleves.length; i++)
        if (_eleves[i].volontaire) _nomAffiche(i)
    ];
    if (volontaires.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun volontaire coché.')),
      );
      return;
    }
    if (nbGagnants > volontaires.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vous demandez $nbGagnants gagnant(s) pour ${volontaires.length} volontaire(s).',
          ),
        ),
      );
      return;
    }
    final shuffled = List<String>.from(volontaires);
    PickFairnessService.instance.beginSession();
    final picks = PickFairnessService.instance.pickMany(
      shuffled,
      nbGagnants,
      _random,
      favorEquity: _favoriserEquite,
    );
    PickFairnessService.instance.recordPicks(picks);
    setState(() {
      _tirageResultat = picks;
      _grilleZoomKey++; // Réinitialise le zoom pour éviter qu'il reste bloqué
    });
    SoundFeedback.win();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        top: true,
        child: Scaffold(
        appBar: AppBar(
          toolbarHeight: MediaQuery.sizeOf(context).width < 600 ? 56 : 72,
          titleSpacing: 16,
          title: Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8, left: 0, right: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _PloufLogoWidget(
                        width: 30,
                        height: 38,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Text('PloufPlouf'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Exporter la liste d\'élèves (Pronote / Ecole Directe)',
              onPressed: _ouvrirExportListeEleves,
            ),
            IconButton(
              icon: const Icon(Icons.upload_file_rounded),
              tooltip: 'Importer une liste d\'élèves',
              onPressed: _ouvrirImportDialog,
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              tooltip: 'Paramètres (sons, etc.)',
              onPressed: () => SettingsSheet.show(context),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              tooltip: 'À propos — Créateur et licence',
              onPressed: _ouvrirAPropos,
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Équipes', icon: Icon(Icons.groups_rounded)),
              Tab(text: 'Tirage', icon: Icon(Icons.shuffle_rounded)),
              Tab(text: 'Roue', icon: Icon(Icons.casino_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildEquipesTab(),
            _buildTirageTab(),
            NameWheelTab(
              names: _nomsPresents,
              favorEquity: _favoriserEquite,
              onFavorEquityChanged: (v) => setState(() => _favoriserEquite = v),
            ),
          ],
        ),
        ),
      ),
    );
  }

  static const double _horizontalPadding = 16.0;

  /// Padding adapté à l'écran (responsive) et aux zones sûres (encoche, barre de navigation).
  EdgeInsets _contentPadding(BuildContext context) {
    final mq = MediaQuery.paddingOf(context);
    final w = MediaQuery.sizeOf(context).width;
    final horizontal = w < 400 ? 12.0 : _horizontalPadding;
    return EdgeInsets.fromLTRB(
      horizontal + mq.left,
      16 + mq.top,
      horizontal + mq.right,
      16 + mq.bottom,
    );
  }

  Widget _buildContentFrame(BuildContext context, {required Widget child}) {
    return Padding(
      padding: _contentPadding(context),
      child: child,
    );
  }

  /// Indice d'équipe (0-based) pour l'élève i si un tirage est en cours, sinon null.
  int? _indiceEquipePourEleve(int i) {
    if (_equipesResultat.isEmpty) return null;
    final nom = _nomAffiche(i);
    for (var t = 0; t < _equipesResultat.length; t++) {
      if (_equipesResultat[t].contains(nom)) return t;
    }
    return null;
  }

  /// Grille d'élèves avec zoom et pan (2 à plusieurs colonnes selon la largeur).
  /// Prénom L1, nom L2 ; case colorée par équipe si tirage fait.
  /// Optimisée tactile : zones de toucher ≥ 48dp, pinch-zoom et pan au doigt.
  Widget _buildElevesGrille({
    required BuildContext context,
    required bool isParticipation,
  }) {
    final size = MediaQuery.sizeOf(context);
    final mq = MediaQuery.paddingOf(context);
    final width = size.width - 2 * _horizontalPadding - mq.left - mq.right;
    const double minCellWidth = 140.0;
    final int crossAxisCount = (width / minCellWidth).floor().clamp(2, 8);
    const double childAspectRatio = 1.35;
    final double cellHeight = (width / crossAxisCount) / childAspectRatio;
    final int rowCount = (_eleves.length / crossAxisCount).ceil();
    final double gridHeight = (rowCount * cellHeight) + (rowCount - 1) * 6 + 12;
    final double viewerHeight = (size.height * 0.55).clamp(240.0, 600.0);
    final theme = Theme.of(context);
    final isNarrow = size.width < 600;
    final checkboxSize = isNarrow ? 32.0 : 24.0; // Plus grand sur mobile pour le doigt
    final checkboxTapSize = 48.0; // Zone de toucher minimale (Material)

    return SizedBox(
      height: viewerHeight,
      child: InteractiveViewer(
        key: ValueKey('grille_$_grilleZoomKey'),
        minScale: 0.4,
        maxScale: 4.0,
        panEnabled: true,
        scaleEnabled: true,
        constrained: false,
        child: SizedBox(
          width: width,
          height: gridHeight,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _eleves.length,
            itemBuilder: (context, i) {
              final e = _eleves[i];
              final equipeIdx = _indiceEquipePourEleve(i);
              final isAbsent = isParticipation && !e.participe;
              final teamColor = equipeIdx != null
                  ? _teamBackgroundColor(context, equipeIdx + 1)
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
              final fairness = isParticipation && e.participe
                  ? PickFairnessService.instance.fairnessTier(_nomAffiche(i))
                  : null;
              return Tooltip(
                message: isAbsent
                    ? '${_nomAffiche(i)} — absent aujourd\'hui'
                    : _nomAffiche(i),
                preferBelow: false,
                verticalOffset: 20,
                child: Material(
                  color: teamColor,
                  borderRadius: BorderRadius.circular(12),
                  child: Opacity(
                    opacity: isAbsent ? 0.42 : 1.0,
                    child: InkWell(
                    onTap: () => _editerNom(context, i),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 8 : 6,
                      vertical: isNarrow ? 8 : 4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: checkboxTapSize,
                          width: checkboxTapSize,
                          child: Center(
                            child: SizedBox(
                              height: checkboxSize,
                              width: checkboxSize,
                              child: Checkbox(
                                value: isParticipation ? e.participe : e.volontaire,
                                onChanged: (v) => setState(() {
                                  if (isParticipation) {
                                    e.participe = v ?? false;
                                  } else {
                                    e.volontaire = v ?? false;
                                  }
                                }),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isNarrow ? 6 : 4),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                e.prenom.trim().isEmpty ? '—' : e.prenom.trim(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                e.nom.trim().isEmpty ? '—' : e.nom.trim(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        if (e.genre != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              e.genre == 'F' ? 'F' : 'G',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        if (fairness != null && fairness == 0)
                          Tooltip(
                            message: 'Jamais tiré — prioritaire si équité activée',
                            child: Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: theme.colorScheme.tertiary,
                            ),
                          )
                        else if (fairness != null && fairness >= 3)
                          Tooltip(
                            message: 'Pas tiré depuis plusieurs séances',
                            child: Icon(
                              Icons.bolt_rounded,
                              size: 16,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: Icon(
                            Icons.person_remove_rounded,
                            size: isNarrow ? 22 : 18,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => _supprimerEleve(i),
                          tooltip: 'Supprimer cet élève',
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.padded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _ajouterEleve() {
    if (_eleves.length >= maxEleves) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $maxEleves élèves.'),
        ),
      );
      return;
    }
    setState(() {
      _eleves.add(Eleve(nom: 'Nouvel élève'));
      _incompatibles.add({});
      _choixEtreAvec.add(null);
      _exclusion.add(null);
    });
  }

  void _supprimerEleve(int index) {
    if (_eleves.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Il doit rester au moins un élève dans la liste.'),
        ),
      );
      return;
    }
    setState(() {
      _eleves.removeAt(index);
      _incompatibles.removeAt(index);
      _choixEtreAvec.removeAt(index);
      _exclusion.removeAt(index);
      for (var i = 0; i < _incompatibles.length; i++) {
        _incompatibles[i].remove(index);
        _incompatibles[i] = _incompatibles[i]
            .where((j) => j != index)
            .map((j) => j > index ? j - 1 : j)
            .toSet();
        if (_choixEtreAvec[i] == index) {
          _choixEtreAvec[i] = null;
        } else if (_choixEtreAvec[i] != null && _choixEtreAvec[i]! > index) {
          _choixEtreAvec[i] = _choixEtreAvec[i]! - 1;
        }
        if (_exclusion[i] == index) {
          _exclusion[i] = null;
        } else if (_exclusion[i] != null && _exclusion[i]! > index) {
          _exclusion[i] = _exclusion[i]! - 1;
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Élève supprimé de la liste.')),
    );
  }

  /// Valide les noms : garde uniquement les lignes vraiment remplies (exclut "Élève x"), les coche pour le tirage.
  void _validerNomsEntres() {
    final toKeep = <int>[];
    for (var i = 0; i < _eleves.length; i++) {
      if (!_isLigneVideOuDefaut(i)) toKeep.add(i);
    }
    if (toKeep.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun nom renseigné. Remplissez au moins prénom ou nom.'),
        ),
      );
      return;
    }
    if (toKeep.length == _eleves.length) {
      setState(() {
        for (final i in toKeep) {
          _eleves[i].participe = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${toKeep.length} participant(s) validé(s) pour le tirage.',
          ),
        ),
      );
      return;
    }
    setState(() {
      final newEleves = toKeep.map((i) => _eleves[i]).toList();
      for (final e in newEleves) {
        e.participe = true;
      }
      final oldToNew = <int, int>{};
      for (var k = 0; k < toKeep.length; k++) {
        oldToNew[toKeep[k]] = k;
      }
      final newIncompatibles = List.generate(newEleves.length, (_) => <int>{});
      for (var i = 0; i < _eleves.length; i++) {
        final ni = oldToNew[i];
        if (ni == null) continue;
        for (final j in _incompatibles[i]) {
          final nj = oldToNew[j];
          if (nj != null) newIncompatibles[ni].add(nj);
        }
      }
      final newChoix = List<int?>.filled(newEleves.length, null);
      final newExclusion = List<int?>.filled(newEleves.length, null);
      for (var i = 0; i < _eleves.length; i++) {
        final ni = oldToNew[i];
        if (ni == null) continue;
        if (_choixEtreAvec[i] != null) {
          final nj = oldToNew[_choixEtreAvec[i]!];
          if (nj != null) newChoix[ni] = nj;
        }
        if (_exclusion[i] != null) {
          final nj = oldToNew[_exclusion[i]!];
          if (nj != null) newExclusion[ni] = nj;
        }
      }
      _eleves
        ..clear()
        ..addAll(newEleves);
      _incompatibles
        ..clear()
        ..addAll(newIncompatibles);
      _choixEtreAvec
        ..clear()
        ..addAll(newChoix);
      _exclusion
        ..clear()
        ..addAll(newExclusion);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${toKeep.length} élève(s) conservé(s) et cochés pour le tirage. '
          'Lignes vides supprimées.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildEquipesTab() {
    final nbParticipant = _eleves.where((e) => e.participe).length;
    final nbAbsent = _eleves.length - nbParticipant;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      child: _buildContentFrame(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SectionHeader(
                    icon: Icons.how_to_reg_rounded,
                    title: 'Présents / Absents',
                    subtitle: nbAbsent > 0
                        ? '$nbParticipant présent(s) · $nbAbsent absent(s) — les absents ne sont pas tirés'
                        : 'Tous présents ($nbParticipant) — décochez les absents du jour',
                  ),
                ),
                if (nbAbsent > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Chip(
                      avatar: Icon(
                        Icons.person_off_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      label: Text('$nbAbsent absent(s)'),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withValues(alpha: 0.5),
                    ),
                  )
                else
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${_eleves.length} élève${_eleves.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final boutons = [
                  Tooltip(
                    message: 'Marquer toute la classe présente aujourd\'hui',
                    child: FilledButton.tonalIcon(
                      onPressed: () => setState(() {
                        for (final e in _eleves) {
                          e.participe = true;
                        }
                      }),
                      icon: const Icon(Icons.groups_rounded, size: 20),
                      label: const Text('Tous présents'),
                    ),
                  ),
                  Tooltip(
                    message: 'Marquer toute la classe absente (ex. avant l\'appel)',
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() {
                        for (final e in _eleves) {
                          e.participe = false;
                        }
                      }),
                      icon: const Icon(Icons.person_off_rounded, size: 20),
                      label: const Text('Tous absents'),
                    ),
                  ),
                  Tooltip(
                    message: 'Ajouter un nouvel élève à la liste (max $maxEleves)',
                    child: OutlinedButton.icon(
                      onPressed: _ajouterEleve,
                      icon: const Icon(Icons.person_add_rounded, size: 20),
                      label: const Text('Ajouter un élève'),
                    ),
                  ),
                ];
                if (constraints.maxWidth > 400) {
                  return Row(
                    children: [
                      Expanded(child: boutons[0]),
                      const SizedBox(width: 8),
                      Expanded(child: boutons[1]),
                      const SizedBox(width: 8),
                      Expanded(child: boutons[2]),
                    ],
                  );
                }
                return Wrap(spacing: 8, runSpacing: 8, children: boutons);
              },
            ),
            const SizedBox(height: 8),
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              child: SwitchListTile(
                value: _cocherIdentitesAuto,
                onChanged: (v) => setState(() {
                  _cocherIdentitesAuto = v;
                  if (v) {
                    for (var i = 0; i < _eleves.length; i++) {
                      if (!_isLigneVideOuDefaut(i)) _eleves[i].participe = true;
                    }
                  }
                }),
                title: const Text('Cocher les identités automatiquement'),
                subtitle: const Text(
                  'Les lignes avec un prénom ou un nom saisi sont cochées pour le tirage',
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pincez pour zoomer, glissez pour déplacer. Vue de toute la classe.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _buildElevesGrille(context: context, isParticipation: true),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _validerNomsEntres,
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text('Valider les noms entrés'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              icon: Icons.face_rounded,
              title: 'Noms des équipes',
              subtitle: 'Choisissez un thème (optionnel)',
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final chips = <Widget>[
                  ...List.generate(teamNameThemes.length, (i) {
                    final theme = teamNameThemes[i];
                    final selected = !_nomsEquipesAleatoire && _themeNomsEquipes == i;
                    return FilterChip(
                      avatar: Text(theme.emoji, style: const TextStyle(fontSize: 16)),
                      label: Text(theme.label),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        _nomsEquipesAleatoire = false;
                        _themeNomsEquipes = i;
                      }),
                      showCheckmark: true,
                    );
                  }),
                  FilterChip(
                    avatar: Icon(
                      Icons.shuffle_rounded,
                      size: 18,
                      color: _nomsEquipesAleatoire
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    label: const Text('Choix tout aléatoire'),
                    selected: _nomsEquipesAleatoire,
                    onSelected: (v) => setState(() {
                      _nomsEquipesAleatoire = v == true;
                      if (_nomsEquipesAleatoire) {
                        _nomsEquipesAleatoiresCourants = _genererNomsAleatoires();
                      }
                    }),
                    showCheckmark: true,
                  ),
                ];
                return Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  runAlignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: chips,
                );
              },
            ),
            if (!_nomsEquipesAleatoire) ...[
              const SizedBox(height: 8),
              Text(
                teamNameThemes[_themeNomsEquipes].description ??
                    'Ex. ${teamNameThemes[_themeNomsEquipes].noms.take(4).join(', ')}…',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SectionHeader(
                    icon: Icons.groups_rounded,
                    title: 'Lancer le tirage',
                    subtitle: nbParticipant < 2
                        ? 'Cochez au moins 2 participants ci-dessus'
                        : 'Choisissez le nombre d\'équipes',
                  ),
                ),
                if (nbParticipant >= 2)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Chip(
                      avatar: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        '$nbParticipant — prêt',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (nbParticipant < 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Cochez au moins 2 élèves dans la liste des participants pour pouvoir lancer un tirage.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final boutons = [2, 3, 4, 5, 6, 7, 8, 9, 10].map((n) {
                  final canLaunch = nbParticipant >= n;
                  return Tooltip(
                    message: canLaunch
                        ? 'Former $n équipes avec les $nbParticipant participants'
                        : 'Cochez au moins $n participants pour former $n équipes',
                    child: FilledButton(
                      onPressed: canLaunch
                          ? () {
                              HapticFeedback.mediumImpact();
                              _lancerEquipesAvecCountdown(n);
                            }
                          : null,
                      child: Text('$n équipes'),
                    ),
                  );
                }).toList();
                final large = constraints.maxWidth > 600;
                if (large) {
                  final gap = const SizedBox(width: 6);
                  final rowChildren = <Widget>[];
                  for (var i = 0; i < boutons.length; i++) {
                    if (i > 0) rowChildren.add(gap);
                    rowChildren.add(Expanded(child: boutons[i]));
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rowChildren,
                  );
                }
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: boutons,
                );
              },
            ),
            if (_equipesResultat.isNotEmpty) ...[
              const SizedBox(height: 32),
              _SectionHeader(
                key: _resultSectionKey,
                icon: Icons.emoji_events_rounded,
                title: 'Résultat',
                subtitle: '$nbParticipant participants',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _ouvrirExportEquipes,
                      icon: const Icon(Icons.save_rounded, size: 20),
                      label: const Text('Enregistrer'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _partagerEquipes,
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: const Text('Partager'),
                    ),
                  ),
                ],
              ),
              if (_balanceSummary != null) ...[
                const SizedBox(height: 12),
                TeamBalanceSummaryCard(summary: _balanceSummary!),
              ],
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  final theme = Theme.of(context);
                  final children = _equipesResultat.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final equipe = entry.value;
                    final color = _teamColor(idx);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        elevation: 0,
                        color: _teamBackgroundColor(context, idx),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border(
                              left: BorderSide(color: color, width: 4),
                            ),
                          ),
                          child: InkWell(
                          onTap: () => _editerNomEquipe(context, idx),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                    children: [
                                      Icon(
                                        Icons.group_rounded,
                                        size: 20,
                                        color: color,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          idx <= _nomsEquipesAffiches.length
                                              ? _nomsEquipesAffiches[idx - 1]
                                              : _nomEquipe(idx),
                                          style: theme
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                color: color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${equipe.length})',
                                        style: theme
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: color),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.edit_rounded,
                                        size: 18,
                                        color: color,
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  equipe.join(', '),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    );
                  }).toList();
                  if (isWide && _equipesResultat.length <= 3) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children
                          .map((c) => Expanded(child: c))
                          .toList(),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildTableauParticipantsEquipes(),
            ],
            const SizedBox(height: 24),
            if (!_optionsSpecialesVisibles)
              OutlinedButton.icon(
                onPressed: () => setState(() => _optionsSpecialesVisibles = true),
                icon: Icon(Icons.tune_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                label: const Text('Afficher les options avancées'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.tune_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                      TextButton.icon(
                        onPressed: () => setState(() => _optionsSpecialesVisibles = false),
                        icon: const Icon(Icons.expand_less_rounded, size: 20),
                        label: const Text('Masquer les options avancées'),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionHeader(
                          icon: Icons.warning_amber_rounded,
                          title: 'Incompatibilités',
                          subtitle: 'Personnes qui ne doivent pas être dans la même équipe',
                        ),
                        const SizedBox(height: 8),
                        _buildListeIncompatibles(),
                        const SizedBox(height: 20),
                        _SectionHeader(
                          icon: Icons.how_to_vote_rounded,
                          title: 'Tirage semi-choisi',
                          subtitle: 'Chacun choisit ou exclut une personne',
                        ),
                        const SizedBox(height: 8),
                        _buildTirageSemiChoisi(),
                        const SizedBox(height: 20),
                        Material(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          child: SwitchListTile(
                            value: _repartirFillesGarcons,
                            onChanged: (v) => setState(() => _repartirFillesGarcons = v),
                            title: const Text('Répartir filles et garçons équitablement'),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            children: [
                              SwitchListTile(
                                value: _eviterRepeterEquipes,
                                onChanged: (v) => setState(() => _eviterRepeterEquipes = v),
                                title: const Text('Éviter de répéter les équipes précédentes'),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              if (_dernierTirage != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.tonalIcon(
                                      onPressed: _revanche,
                                      icon: const Icon(Icons.replay_rounded, size: 20),
                                      label: const Text('Revanche : mêmes équipes'),
                                    ),
                                  ),
                                ),
                              if (_historiqueEquipes.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: OutlinedButton.icon(
                                    onPressed: _ouvrirHistoriqueEquipes,
                                    icon: const Icon(Icons.history_rounded, size: 20),
                                    label: Text(
                                      'Voir l\'historique (${_historiqueEquipes.length})',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _nomEquipe(int index) {
    if (_nomsEquipesAleatoire &&
        index <= _nomsEquipesAleatoiresCourants.length) {
      return _nomsEquipesAleatoiresCourants[index - 1];
    }
    final theme = teamNameThemes[_themeNomsEquipes];
    final noms = theme.noms;
    return noms[(index - 1).clamp(0, noms.length - 1)];
  }

  /// Retourne la liste des paires (i, j) avec i < j pour l'affichage.
  List<(int, int)> _getPairesIncompatibles() {
    final paires = <(int, int)>[];
    for (var i = 0; i < _eleves.length; i++) {
      for (final j in _incompatibles[i]) {
        if (j > i) {
          paires.add((i, j));
        }
      }
    }
    return paires;
  }

  Widget _buildListeIncompatibles() {
    final paires = _getPairesIncompatibles();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (paires.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Aucune règle. Cliquez sur « Ajouter » pour indiquer deux personnes qui ne doivent pas être ensemble (humeur, conflit, etc.).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...paires.map((pair) {
            final (i, j) = pair;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Theme.of(context)
                    .colorScheme
                    .errorContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: Icon(
                    Icons.person_off_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: 22,
                  ),
                  title: Text(
                    '${_nomAffiche(i)} ⟷ ${_nomAffiche(j)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Supprimer cette incompatibilité',
                    onPressed: () => setState(() {
                      _incompatibles[i].remove(j);
                      _incompatibles[j].remove(i);
                    }),
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _ouvrirAjoutIncompatibilite,
          icon: const Icon(Icons.person_add_disabled_rounded, size: 20),
          label: const Text('Ajouter une incompatibilité'),
        ),
      ],
    );
  }

  Widget _buildTirageSemiChoisi() {
    final participantIndices = [
      for (var i = 0; i < _eleves.length; i++)
        if (_eleves[i].participe) i
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chipSemiChoisi(null, 'Aucun'),
            _chipSemiChoisi('choix', 'Chacun choisit 1'),
            _chipSemiChoisi('exclusion', 'Chacun exclut 1'),
            _chipSemiChoisi('vote', 'Vote discret'),
          ],
        ),
        if (_modeSemiChoisi == 'choix') ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: participantIndices.length < 2
                ? null
                : _ouvrirConfigChoix,
            icon: const Icon(Icons.person_add_rounded, size: 20),
            label: const Text('Configurer les choix (qui souhaite être avec qui)'),
          ),
        ],
        if (_modeSemiChoisi == 'exclusion') ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: participantIndices.length < 2
                ? null
                : _ouvrirConfigExclusion,
            icon: const Icon(Icons.person_off_rounded, size: 20),
            label: const Text('Configurer les exclusions (qui exclut qui)'),
          ),
        ],
        if (_modeSemiChoisi == 'vote') ...[
          const SizedBox(height: 12),
          Text(
            'Chaque participant choisira en secret une personne avec qui être. Personne ne verra les choix des autres.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: participantIndices.length < 2
                ? null
                : _lancerVoteDiscret,
            icon: const Icon(Icons.how_to_vote_rounded, size: 20),
            label: const Text('Lancer le vote discret'),
          ),
        ],
      ],
    );
  }

  Widget _chipSemiChoisi(String? value, String label) {
    final selected = _modeSemiChoisi == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => setState(() => _modeSemiChoisi = value),
      showCheckmark: true,
    );
  }

  void _ouvrirConfigChoix() {
    final participantIndices = [
      for (var i = 0; i < _eleves.length; i++)
        if (_eleves[i].participe) i
    ];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chacun choisit 1 personne'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pour chaque participant, choisissez la personne avec qui il/elle souhaite être dans la même équipe (si possible).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ...participantIndices.map((i) {
                final autres = participantIndices.where((j) => j != i).toList();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          _nomAffiche(i),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int?>(
                          initialValue: _choixEtreAvec[i],
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('—'),
                            ),
                            ...autres.map((j) => DropdownMenuItem<int?>(
                                  value: j,
                                  child: Text(
                                    _nomAffiche(j),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                          ],
                          onChanged: (v) => setState(() => _choixEtreAvec[i] = v),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _ouvrirConfigExclusion() {
    final participantIndices = [
      for (var i = 0; i < _eleves.length; i++)
        if (_eleves[i].participe) i
    ];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chacun exclut 1 personne'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pour chaque participant, choisissez la personne qu\'il/elle ne veut pas avoir dans la même équipe.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ...participantIndices.map((i) {
                final autres = participantIndices.where((j) => j != i).toList();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          _nomAffiche(i),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int?>(
                          initialValue: _exclusion[i],
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('—'),
                            ),
                            ...autres.map((j) => DropdownMenuItem<int?>(
                                  value: j,
                                  child: Text(
                                    _nomAffiche(j),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                          ],
                          onChanged: (v) => setState(() => _exclusion[i] = v),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _lancerVoteDiscret() {
    final participantIndices = [
      for (var i = 0; i < _eleves.length; i++)
        if (_eleves[i].participe) i
    ];
    if (participantIndices.isEmpty || participantIndices.length < 2) return;
    final order = List<int>.from(participantIndices)..shuffle(_random);
    var step = 0;
    void showStep() {
      if (step >= order.length) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vote terminé. Les choix sont enregistrés. Lancez le tirage des équipes.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      final i = order[step];
      final autres = order.where((j) => j != i).toList();
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Vote discret'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tour ${step + 1}/${order.length}\n\n'
                'Choisissez en secret la personne avec qui vous souhaitez être (personne ne verra votre choix).',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...autres.map((j) => ListTile(
                    title: Text(_nomAffiche(j)),
                    onTap: () {
                      setState(() => _choixEtreAvec[i] = j);
                      step++;
                      Navigator.of(context).pop();
                      showStep();
                    },
                  )),
            ],
          ),
        ),
      );
    }
    showStep();
  }

  void _ouvrirAjoutIncompatibilite() {
    int? indexA;
    int? indexB;
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded),
              SizedBox(width: 12),
              Text('Ne doivent pas être ensemble'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choisissez deux personnes qui ne doivent pas être dans la même équipe (incompatibilité d\'humeur, conflit, etc.).',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: indexA,
                  decoration: const InputDecoration(
                    labelText: 'Première personne',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(_eleves.length, (i) => i).map((i) {
                    return DropdownMenuItem(
                      value: i,
                      child: Text(_nomAffiche(i)),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => indexA = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: indexB,
                  decoration: const InputDecoration(
                    labelText: 'Deuxième personne',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(_eleves.length, (i) => i).map((i) {
                    return DropdownMenuItem(
                      value: i,
                      child: Text(_nomAffiche(i)),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => indexB = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (indexA == null || indexB == null) return;
                if (indexA == indexB) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Choisissez deux personnes différentes.',
                      ),
                    ),
                  );
                  return;
                }
                setState(() {
                  _incompatibles[indexA!].add(indexB!);
                  _incompatibles[indexB!].add(indexA!);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${_nomAffiche(indexA!)} et ${_nomAffiche(indexB!)} ne seront pas dans la même équipe.',
                    ),
                  ),
                );
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  /// Couleur d'accent pour une équipe (icône, bordure, titre). Lisible sur fond clair.
  Color _teamColor(int index) {
    const colors = [
      Color(0xFF1565C0),   // bleu
      Color(0xFF6A1B9A),   // violet
      Color(0xFF00695C),   // teal
      Color(0xFFE65100),   // orange
      Color(0xFFAD1457),   // rose/magenta
      Color(0xFF2E7D32),   // vert
      Color(0xFF5D4037),   // marron
      Color(0xFF006064),   // cyan
      Color(0xFF4527A0),   // indigo
      Color(0xFFF57C00),   // orange vif
    ];
    return colors[(index - 1) % colors.length];
  }

  /// Fond pour une équipe : teinte très légère pour ne jamais masquer le texte.
  Color _teamBackgroundColor(BuildContext context, int teamIndex) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final color = _teamColor(teamIndex);
    return Color.lerp(surface, color, 0.08)!;
  }

  /// Tableau liste des participants avec leur équipe (après tirage).
  Widget _buildTableauParticipantsEquipes() {
    final rows = <(String nom, String equipe)>[];
    for (var t = 0; t < _equipesResultat.length; t++) {
      final nomEquipe = t < _nomsEquipesAffiches.length
          ? _nomsEquipesAffiches[t]
          : _nomEquipe(t + 1);
      for (final nom in _equipesResultat[t]) {
        rows.add((nom, nomEquipe));
      }
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Liste des participants par équipe',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                ),
                columns: const [
                  DataColumn(label: Text('Participant')),
                  DataColumn(label: Text('Équipe')),
                ],
                rows: rows
                    .map((r) => DataRow(
                          cells: [
                            DataCell(Text(r.$1)),
                            DataCell(Text(r.$2)),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTirageTab() {
    final nbVolontaires = _eleves.where((e) => e.volontaire).length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      child: _buildContentFrame(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              icon: Icons.volunteer_activism_rounded,
              title: 'Volontaires',
              subtitle: 'Cochez les volontaires ($nbVolontaires cochés)',
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final boutons = [
                  Tooltip(
                    message: 'Cocher tous les élèves comme volontaires',
                    child: FilledButton.tonalIcon(
                      onPressed: () => setState(() {
                        for (final e in _eleves) {
                          e.volontaire = true;
                        }
                      }),
                      icon: const Icon(Icons.check_box_rounded, size: 20),
                      label: const Text('Tout cocher'),
                    ),
                  ),
                  Tooltip(
                    message: 'Décocher tous les volontaires',
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() {
                        for (final e in _eleves) {
                          e.volontaire = false;
                        }
                      }),
                      icon: const Icon(Icons.check_box_outline_blank_rounded, size: 20),
                      label: const Text('Tout décocher'),
                    ),
                  ),
                ];
                if (constraints.maxWidth > 300) {
                  return Row(
                    children: [
                      Expanded(child: boutons[0]),
                      const SizedBox(width: 8),
                      Expanded(child: boutons[1]),
                    ],
                  );
                }
                return Wrap(spacing: 8, runSpacing: 8, children: boutons);
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Pincez pour zoomer, glissez pour déplacer.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _buildElevesGrille(context: context, isParticipation: false),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _favoriserEquite,
              onChanged: (v) => setState(() => _favoriserEquite = v),
              title: const Text('Favoriser l\'équité'),
              subtitle: const Text(
                'Les élèves moins souvent tirés ont plus de chances',
              ),
              secondary: const Icon(Icons.balance_rounded),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SectionHeader(
                    icon: Icons.confirmation_number_rounded,
                    title: 'Nombre de gagnants',
                    subtitle: nbVolontaires == 0
                        ? 'Cochez au moins 1 volontaire ci-dessus'
                        : 'Indiquez combien tirer au sort',
                  ),
                ),
                if (nbVolontaires >= 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Chip(
                      avatar: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                        label: Text(
                        '$nbVolontaires — prêt',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (nbVolontaires == 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Cochez au moins un élève dans la liste des volontaires pour lancer le tirage.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final useColumn = constraints.maxWidth < 380;
                final canDraw = nbVolontaires >= 1;
                final field = _TirageNumberField(
                  key: _tirageNumberKey,
                  max: maxEleves,
                  value: _nbGagnantsTirage,
                  onChanged: (v) => setState(() => _nbGagnantsTirage = v),
                );
                final button = Tooltip(
                  message: canDraw
                      ? 'Tirer $_nbGagnantsTirage gagnant(s) parmi les $nbVolontaires volontaires'
                      : 'Cochez au moins un volontaire ci-dessus',
                  child: FilledButton.icon(
                    onPressed: canDraw
                        ? () {
                            HapticFeedback.mediumImpact();
                            final n = _tirageNumberKey.currentState?.currentValue ??
                                _nbGagnantsTirage;
                            setState(() => _nbGagnantsTirage = n);
                            _lancerTirageAvecCountdown(n);
                          }
                        : null,
                    icon: const Icon(Icons.shuffle_rounded, size: 20),
                    label: const Text('Tirer au sort'),
                  ),
                );
                if (useColumn) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      field,
                      const SizedBox(height: 12),
                      button,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: field,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: button),
                  ],
                );
              },
            ),
            if (_tirageResultat.isNotEmpty) ...[
              const SizedBox(height: 32),
              _SectionHeader(
                icon: Icons.emoji_events_rounded,
                title: 'Gagnant(s) tiré(s) au sort',
                subtitle: null,
              ),
              const SizedBox(height: 12),
              Material(
                elevation: 0,
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _tirageResultat
                        .asMap()
                        .entries
                        .map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: InkWell(
                                onTap: () => _editerTirageResultat(context, e.key),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${e.key + 1}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          e.value,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.edit_rounded,
                                        size: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _editerNom(BuildContext context, int index) {
    final e = _eleves[index];
    final ctrlPrenom = TextEditingController(text: e.prenom.trim());
    final ctrlNom = TextEditingController(
      text: _isNomDefaut(e.nom) ? '' : e.nom.trim(),
    );
    String? genreSelection = e.genre;
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier l\'élève'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: ctrlPrenom,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    hintText: 'Ex. Marie',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrlNom,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    hintText: 'Ex. Dupont',
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: genreSelection,
                  decoration: const InputDecoration(
                    labelText: 'Genre (pour répartition équilibrée)',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Non précisé')),
                    DropdownMenuItem(value: 'F', child: Text('Fille')),
                    DropdownMenuItem(value: 'M', child: Text('Garçon')),
                  ],
                  onChanged: (v) => setDialogState(() => genreSelection = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _eleves[index].prenom = ctrlPrenom.text.trim();
                  _eleves[index].nom = ctrlNom.text.trim();
                  _eleves[index].genre = genreSelection;
                  if (_cocherIdentitesAuto && !_isLigneVideOuDefaut(index)) {
                    _eleves[index].participe = true;
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _editerNomEquipe(BuildContext context, int idxEquipe) {
    if (idxEquipe > _nomsEquipesAffiches.length) return;
    final ctrl = TextEditingController(
      text: _nomsEquipesAffiches[idxEquipe - 1],
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le nom de l\'équipe $idxEquipe'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Nom de l\'équipe',
            hintText: 'Ex. Les Lions',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final nom = ctrl.text.trim();
              if (nom.isNotEmpty) {
                setState(() => _nomsEquipesAffiches[idxEquipe - 1] = nom);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _editerTirageResultat(BuildContext context, int index) {
    if (index >= _tirageResultat.length) return;
    final ctrl = TextEditingController(text: _tirageResultat[index]);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le gagnant n°${index + 1}'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Nom',
            hintText: 'En cas de compatibilité, remplacez par un autre nom',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final nom = ctrl.text.trim();
              if (nom.isNotEmpty) {
                setState(() => _tirageResultat[index] = nom);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  /// Parse une chaîne en liste de noms (un par ligne, ou séparés par virgules/point-virgules).
  static List<String> _parseNoms(String text) {
    final noms = <String>[];
    for (final line in text.split(RegExp(r'[\r\n]+'))) {
      for (final part in line.split(RegExp(r'[,;]'))) {
        final nom = part.trim();
        if (nom.isNotEmpty) noms.add(nom);
      }
    }
    return noms.take(maxEleves).toList();
  }

  void _ouvrirExportEquipes() {
    if (_equipesResultat.isEmpty) return;
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Exporter les équipes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enregistrer ou partager les équipes :',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _partagerEquipes();
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Partager (WhatsApp, SMS…)'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enregistrer sur l\'appareil :',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...[
                    ('TXT', 'Fichier texte (.txt)', Icons.description_rounded),
                    ('ODT', 'LibreOffice / OpenDocument (.odt)', Icons.description_rounded),
                    ('DOCX', 'Microsoft Word (.docx)', Icons.description_rounded),
                    ('PDF', 'PDF coloré pour le tableau (.pdf)', Icons.picture_as_pdf_rounded),
                  ].map((e) {
                    final (ext, label, icon) = e;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(icon),
                        title: Text(label),
                        onTap: () async {
                          Navigator.of(context).pop();
                          try {
                            await enregistrerEquipes(
                              _equipesResultat,
                              _nomsEquipesAffiches,
                              ext,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Équipes enregistrées au format $ext.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur lors de l\'enregistrement : $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _ouvrirAPropos() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos de PloufPlouf'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PloufPlouf',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tirage d\'équipes et tirage au sort pour la classe.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Version ${AppVersion.full}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Créateur : DesertYGL',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Données et confidentialité',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PloufPlouf fonctionne hors ligne. Les listes d\'élèves et l\'historique d\'équité '
                'restent sur votre appareil (SharedPreferences). Aucune donnée n\'est envoyée à un serveur.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Licence : GPL-3.0 (GNU General Public License v3.0)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ce programme est un logiciel libre : vous pouvez le redistribuer et le modifier '
                'selon les termes de la licence GPL-3.0. Il est fourni « tel quel », sans garantie. '
                'Voir le fichier LICENSE à la racine du projet ou : https://www.gnu.org/licenses/gpl-3.0.html',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _ouvrirExportListeEleves() async {
    if (_eleves.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun élève à exporter. Ajoutez ou importez une liste.'),
        ),
      );
      return;
    }
    try {
      final liste = _eleves
          .map((e) => (prenom: e.prenom, nom: e.nom))
          .toList();
      final path = await enregistrerListeElevesPronote(liste);
      if (mounted) {
        if (path == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export annulé ou impossible.')),
          );
        } else if (path.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Liste d\'élèves exportée en CSV (Pronote / Ecole Directe).',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fichier enregistré dans : $path'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export : $e')),
        );
      }
    }
  }

  void _ouvrirImportDialog() {
    final ctrl = TextEditingController();
    final ctrlChemin = TextEditingController();
    List<EleveImport>? elevesFromFile;
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.upload_file_rounded),
              SizedBox(width: 12),
              Text('Importer une liste'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Collez une liste de noms ou importez depuis un fichier : Pronote (CSV/Excel), Ecole Directe, ENT, TXT, PDF, ODT, Word. Colonnes « Nom » et « Prénom » reconnues automatiquement. Max $maxEleves élèves.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (elevesFromFile != null && elevesFromFile!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Material(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: Theme.of(context).colorScheme.primary, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${elevesFromFile!.length} élève(s) chargé(s) (Prénom, Nom). Cliquez sur Importer.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  maxLines: 12,
                  minLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Marie\nJean\nLéa\n... ou importer un CSV/Excel Pronote',
                    alignLabelWithHint: true,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          final text = data?.text ?? '';
                          if (text.isNotEmpty) {
                            elevesFromFile = null;
                            ctrl.text = text;
                            setDialogState(() {});
                          }
                        },
                        icon: const Icon(Icons.content_paste_rounded, size: 20),
                        label: const Text('Coller'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          final result = await importerTexteDepuisFichier();
                          if (result.erreur != null &&
                              result.texte == null &&
                              (result.eleves == null || result.eleves!.isEmpty)) {
                            if (result.erreur!.isNotEmpty && context.mounted) {
                              final msg = result.erreur!.toLowerCase();
                              if (msg.contains('zenithy') || msg.contains('zenity') || msg.contains('path') || msg.contains('not find')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Sur Linux, installez zenity (sudo apt install zenity) ou entrez le chemin du fichier ci-dessous.',
                                    ),
                                    duration: Duration(seconds: 5),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result.erreur!)),
                                );
                              }
                            }
                            return;
                          }
                          final eleves = result.eleves;
                          if (eleves != null && eleves.isNotEmpty) {
                            elevesFromFile = eleves;
                            ctrl.text = '';
                            setDialogState(() {});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${eleves.length} élève(s) reconnu(s) (Prénom, Nom). Cliquez sur Importer.',
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          if (result.texte != null && result.texte!.isNotEmpty) {
                            elevesFromFile = null;
                            ctrl.text = result.texte!;
                            setDialogState(() {});
                            if (context.mounted) {
                              final nbMots = result.texte!
                                  .split(RegExp(r'[\s,;\n]+'))
                                  .where((s) => s.trim().isNotEmpty)
                                  .length;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Texte extrait ($nbMots élément(s)). Cliquez sur Importer pour valider.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.folder_open_rounded, size: 20),
                        label: const Text('Fichier…'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Si la sélection de fichier échoue (Linux), entrez le chemin du fichier :',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: ctrlChemin,
                  decoration: const InputDecoration(
                    hintText: '/chemin/vers/fichier.csv',
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.none,
                  onSubmitted: (_) async {
                    final path = ctrlChemin.text.trim();
                    if (path.isEmpty) return;
                    final result = await importerFichierDepuisChemin(path);
                    if (!context.mounted) return;
                    setDialogState(() {});
                    if (result.erreur != null &&
                        result.texte == null &&
                        (result.eleves == null || result.eleves!.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result.erreur!)),
                      );
                      return;
                    }
                    final eleves = result.eleves;
                    if (eleves != null && eleves.isNotEmpty) {
                      elevesFromFile = eleves;
                      ctrl.text = '';
                      setDialogState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${eleves.length} élève(s) chargé(s). Cliquez sur Importer.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (result.texte != null && result.texte!.isNotEmpty) {
                      elevesFromFile = null;
                      ctrl.text = result.texte!;
                      setDialogState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Texte extrait. Cliquez sur Importer pour valider.'),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      final path = ctrlChemin.text.trim();
                      if (path.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Entrez le chemin du fichier.')),
                          );
                        }
                        return;
                      }
                      final result = await importerFichierDepuisChemin(path);
                      if (!context.mounted) return;
                      setDialogState(() {});
                      if (result.erreur != null &&
                          result.texte == null &&
                          (result.eleves == null || result.eleves!.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result.erreur!)),
                        );
                        return;
                      }
                      final eleves = result.eleves;
                      if (eleves != null && eleves.isNotEmpty) {
                        elevesFromFile = eleves;
                        ctrl.text = '';
                        setDialogState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${eleves.length} élève(s) chargé(s). Cliquez sur Importer.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (result.texte != null && result.texte!.isNotEmpty) {
                        elevesFromFile = null;
                        ctrl.text = result.texte!;
                        setDialogState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Texte extrait. Cliquez sur Importer pour valider.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.folder_rounded, size: 20),
                    label: const Text('Ouvrir ce fichier'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (elevesFromFile != null && elevesFromFile!.isNotEmpty) {
                  final n = elevesFromFile!.length > maxEleves ? maxEleves : elevesFromFile!.length;
                  setState(() {
                    for (var i = 0; i < n; i++) {
                      final e = elevesFromFile![i];
                      if (i < _eleves.length) {
                        _eleves[i].prenom = e.prenom;
                        _eleves[i].nom = e.nom;
                        if (e.genre != null) _eleves[i].genre = e.genre;
                      } else {
                        _eleves.add(Eleve(
                          prenom: e.prenom,
                          nom: e.nom,
                          genre: e.genre,
                        ));
                        _incompatibles.add({});
                        _choixEtreAvec.add(null);
                        _exclusion.add(null);
                      }
                    }
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$n élève(s) importé(s) (Prénom, Nom).'),
                    ),
                  );
                  return;
                }
                final noms = _parseNoms(ctrl.text);
                if (noms.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aucun nom trouvé. Collez une liste ou importez un fichier (CSV, Excel, TXT…).'),
                    ),
                  );
                  return;
                }
                setState(() {
                  for (var i = 0; i < noms.length && i < maxEleves; i++) {
                    if (i < _eleves.length) {
                      _eleves[i].prenom = '';
                      _eleves[i].nom = noms[i];
                    } else {
                      _eleves.add(Eleve(nom: noms[i]));
                      _incompatibles.add({});
                      _choixEtreAvec.add(null);
                      _exclusion.add(null);
                    }
                  }
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${noms.length > maxEleves ? maxEleves : noms.length} élève(s) importé(s).',
                    ),
                  ),
                );
              },
              child: const Text('Importer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TirageNumberField extends StatefulWidget {
  const _TirageNumberField({
    super.key,
    required this.max,
    required this.value,
    required this.onChanged,
  });

  final int max;
  final int value;
  final void Function(int) onChanged;

  @override
  State<_TirageNumberField> createState() => _TirageNumberFieldState();
}

class _TirageNumberFieldState extends State<_TirageNumberField> {
  late TextEditingController _ctrl;

  int get currentValue {
    final v = _parse(_ctrl.text);
    _ctrl.text = v.toString();
    return v;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_TirageNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _ctrl.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int _parse(String s) {
    final n = int.tryParse(s);
    if (n == null || n < 1) return 1;
    if (n > widget.max) return widget.max;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: '1 à ${widget.max}',
        prefixIcon: const Icon(Icons.numbers_rounded),
        suffixIcon: IconButton(
          icon: const Icon(Icons.check_rounded),
          tooltip: 'Valider le nombre',
          onPressed: () {
            final v = _parse(_ctrl.text);
            _ctrl.text = v.toString();
            widget.onChanged(v);
          },
        ),
      ),
      onSubmitted: (s) {
        final v = _parse(s);
        _ctrl.text = v.toString();
        widget.onChanged(v);
      },
    );
  }
}

/// Logo Plouf : affiche l'image de tête de vache, plus petite, fond blanc rendu transparent.
class _PloufLogoWidget extends StatefulWidget {
  const _PloufLogoWidget({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  static const String _assetVache = 'assets/images/vache_plouf.jpg';

  @override
  State<_PloufLogoWidget> createState() => _PloufLogoWidgetState();
}

class _PloufLogoWidgetState extends State<_PloufLogoWidget> {
  Uint8List? _pngSansFond;
  bool _erreur = false;

  @override
  void initState() {
    super.initState();
    _chargerImageSansFond();
  }

  Future<void> _chargerImageSansFond() async {
    try {
      final data = await rootBundle.load(_PloufLogoWidget._assetVache);
      final bytes = data.buffer.asUint8List();
      final decoded = image_lib.decodeImage(bytes);
      if (decoded == null || !mounted) return;
      // Image avec canal alpha pour la transparence
      final out = image_lib.Image(width: decoded.width, height: decoded.height, numChannels: 4);
      const seuil = 245; // au-dessus = considéré comme fond blanc
      for (var y = 0; y < decoded.height; y++) {
        for (var x = 0; x < decoded.width; x++) {
          final p = decoded.getPixel(x, y);
          final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
          final alpha = (r > seuil && g > seuil && b > seuil) ? 0 : 255;
          out.setPixelRgba(x, y, r, g, b, alpha);
        }
      }
      final pngBytes = image_lib.encodePng(out);
      if (mounted) setState(() { _pngSansFond = Uint8List.fromList(pngBytes); });
    } catch (_) {
      if (mounted) setState(() { _erreur = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Plouf plouf ! Une vache qui se baigne dans un tonneau…',
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: _pngSansFond != null
            ? Image.memory(
                _pngSansFond!,
                fit: BoxFit.contain,
                alignment: Alignment.center,
              )
            : _erreur
                ? CustomPaint(
                    painter: _PloufLogoPainter(color: widget.color),
                    size: Size(widget.width, widget.height),
                  )
                : const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
    );
  }
}

class _PloufLogoPainter extends CustomPainter {
  _PloufLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = (w + h) * 0.012;
    final cx = w * 0.5;

    final brown = const Color(0xFF6D4C41);
    final brownDark = const Color(0xFF4E342E);
    final cowBlack = const Color(0xFF212121);
    final blue = const Color(0xFF29B6F6);

    canvas.save();
    final pad = w * 0.05;
    canvas.translate(pad, pad);
    final dw = w - 2 * pad;
    final dh = h - 2 * pad;

    // —— TONNEAU (en bas, forme de baignoire / baril vu de face) ——
    final barrelTop = dh * 0.48;
    final barrelH = dh * 0.52;
    final barrelW = dw * 0.9;
    final barrelLeft = (dw - barrelW) / 2;
    final rr = barrelH * 0.15;
    final barrelPath = Path();
    barrelPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(barrelLeft, barrelTop, barrelW, barrelH),
      Radius.circular(rr),
    ));
    canvas.drawPath(barrelPath, Paint()..color = brown);
    canvas.drawPath(barrelPath, Paint()..color = brownDark..style = PaintingStyle.stroke..strokeWidth = stroke);
    for (var i = 1; i <= 3; i++) {
      final by = barrelTop + barrelH * (i / 4);
      canvas.drawLine(
        Offset(barrelLeft + rr, by),
        Offset(barrelLeft + barrelW - rr, by),
        Paint()..color = brownDark..strokeWidth = stroke * 1.3,
      );
    }
    canvas.drawLine(
      Offset(barrelLeft + barrelW * 0.15, barrelTop),
      Offset(barrelLeft + barrelW * 0.85, barrelTop),
      Paint()..color = brownDark..strokeWidth = stroke,
    );

    // —— Tête de vache style cartoon (référence : gros yeux, museau rose, langue rouge, oreilles tombantes) ——
    final faceGray = const Color(0xFFBDBDBD);
    final snoutPink = const Color(0xFFFFCCBC);
    final earPink = const Color(0xFFFFAB91);
    final tongueRed = const Color(0xFFE53935);
    final headTop = dh * 0.08;
    final headH = dh * 0.42;
    final headW = dw * 0.7;
    final headLeft = cx - headW / 2;
    final headPath = Path();
    headPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(headLeft, headTop, headW, headH),
      Radius.circular(headW * 0.2),
    ));
    canvas.drawPath(headPath, Paint()..color = faceGray);
    canvas.drawPath(headPath, Paint()..color = cowBlack..style = PaintingStyle.stroke..strokeWidth = stroke);
    // Tache claire (pelage)
    canvas.drawOval(
      Rect.fromLTWH(headLeft + headW * 0.12, headTop + headH * 0.18, headW * 0.28, headH * 0.22),
      Paint()..color = const Color(0xFFFFFDE7),
    );

    // Poils ébouriffés (spikes en haut)
    final spikePath = Path();
    spikePath.moveTo(cx - headW * 0.2, headTop + headH * 0.08);
    spikePath.lineTo(cx - headW * 0.08, headTop - headH * 0.02);
    spikePath.lineTo(cx + headW * 0.05, headTop + headH * 0.05);
    spikePath.lineTo(cx + headW * 0.22, headTop);
    spikePath.lineTo(cx + headW * 0.1, headTop + headH * 0.1);
    spikePath.close();
    canvas.drawPath(spikePath, Paint()..color = faceGray);
    canvas.drawPath(spikePath, Paint()..color = cowBlack..style = PaintingStyle.stroke..strokeWidth = stroke * 0.8);

    // Oreilles tombantes (gris dehors, rose dedans)
    final earW = headW * 0.28;
    final earH = headH * 0.35;
    canvas.drawOval(Rect.fromCenter(center: Offset(headLeft + headW * 0.12, headTop + headH * 0.2), width: earW, height: earH), Paint()..color = faceGray);
    canvas.drawOval(Rect.fromCenter(center: Offset(headLeft + headW * 0.12, headTop + headH * 0.2), width: earW, height: earH), Paint()..color = cowBlack..style = PaintingStyle.stroke..strokeWidth = stroke);
    canvas.drawOval(Rect.fromCenter(center: Offset(headLeft + headW * 0.12, headTop + headH * 0.22), width: earW * 0.6, height: earH * 0.7), Paint()..color = earPink);
    canvas.drawOval(Rect.fromCenter(center: Offset(headLeft + headW * 0.88, headTop + headH * 0.2), width: earW, height: earH), Paint()..color = faceGray);
    canvas.drawOval(Rect.fromCenter(center: Offset(headLeft + headW * 0.88, headTop + headH * 0.2), width: earW, height: earH), Paint()..color = cowBlack..style = PaintingStyle.stroke..strokeWidth = stroke);
    canvas.drawOval(Rect.fromCenter(center: Offset(headLeft + headW * 0.88, headTop + headH * 0.22), width: earW * 0.6, height: earH * 0.7), Paint()..color = earPink);

    // Tache noire sur le front (à droite du centre) — dessinée avant les yeux pour ne pas les masquer
    canvas.drawCircle(Offset(cx + headW * 0.12, headTop + headH * 0.18), headW * 0.08, Paint()..color = cowBlack);

    // Yeux « hallucinés » : TRÈS gros, bien visibles, regard surpris / dément
    final eyeY = headTop + headH * 0.36;
    final eyeW = headW * 0.28;   // largeur généreuse
    final eyeH = headW * 0.26;   // hauteur légèrement ovale = yeux bien ouverts
    final eyeLeft = cx - headW * 0.28;
    final eyeRight = cx + headW * 0.28;
    final eyeStroke = stroke * 1.8;  // contour épais pour visibilité
    final pupilW = eyeW * 0.5;
    final pupilH = eyeH * 0.55;
    final highlightR = (eyeW + eyeH) * 0.08;

    // Œil gauche : blanc + contour noir épais + grosse pupille noire + reflet
    canvas.drawOval(Rect.fromCenter(center: Offset(eyeLeft, eyeY), width: eyeW, height: eyeH), Paint()..color = Colors.white);
    canvas.drawOval(Rect.fromCenter(center: Offset(eyeLeft, eyeY), width: eyeW, height: eyeH), Paint()..color = cowBlack..style = PaintingStyle.stroke..strokeWidth = eyeStroke);
    canvas.drawOval(Rect.fromCenter(center: Offset(eyeLeft, eyeY), width: pupilW, height: pupilH), Paint()..color = cowBlack);
    canvas.drawCircle(Offset(eyeLeft - eyeW * 0.15, eyeY - eyeH * 0.2), highlightR, Paint()..color = Colors.white);

    // Œil droit : idem
    canvas.drawOval(Rect.fromCenter(center: Offset(eyeRight, eyeY), width: eyeW, height: eyeH), Paint()..color = Colors.white);
    canvas.drawOval(Rect.fromCenter(center: Offset(eyeRight, eyeY), width: eyeW, height: eyeH), Paint()..color = cowBlack..style = PaintingStyle.stroke..strokeWidth = eyeStroke);
    canvas.drawOval(Rect.fromCenter(center: Offset(eyeRight, eyeY), width: pupilW, height: pupilH), Paint()..color = cowBlack);
    canvas.drawCircle(Offset(eyeRight + eyeW * 0.15, eyeY - eyeH * 0.2), highlightR, Paint()..color = Colors.white);

    // Sourcils arqués relevés (effet « halluciné » / surpris)
    final browPathL = Path();
    browPathL.moveTo(eyeLeft - eyeW * 0.5, eyeY - eyeH * 0.65);
    browPathL.quadraticBezierTo(eyeLeft, eyeY - eyeH * 0.95, eyeLeft + eyeW * 0.5, eyeY - eyeH * 0.6);
    canvas.drawPath(browPathL, Paint()..color = cowBlack..style = PaintingStyle.stroke..strokeWidth = stroke * 1.5..strokeCap = StrokeCap.round);
    final browPathR = Path();
    browPathR.moveTo(eyeRight - eyeW * 0.5, eyeY - eyeH * 0.6);
    browPathR.quadraticBezierTo(eyeRight, eyeY - eyeH * 0.95, eyeRight + eyeW * 0.5, eyeY - eyeH * 0.65);
    canvas.drawPath(browPathR, Paint()..color = cowBlack..style = PaintingStyle.stroke..strokeWidth = stroke * 1.5..strokeCap = StrokeCap.round);

    // Museau rose (grand, bas du visage) + narines ovales
    final snoutTop = headTop + headH * 0.48;
    final snoutW = headW * 0.55;
    final snoutH = headH * 0.5;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, snoutTop + snoutH * 0.35), width: snoutW, height: snoutH), Paint()..color = snoutPink);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, snoutTop + snoutH * 0.35), width: snoutW, height: snoutH), Paint()..color = cowBlack..style = PaintingStyle.stroke..strokeWidth = stroke);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - snoutW * 0.2, snoutTop + snoutH * 0.35), width: snoutW * 0.2, height: snoutH * 0.25), Paint()..color = cowBlack..style = PaintingStyle.stroke..strokeWidth = stroke * 0.8);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - snoutW * 0.2, snoutTop + snoutH * 0.35), width: snoutW * 0.12, height: snoutH * 0.15), Paint()..color = snoutPink);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + snoutW * 0.2, snoutTop + snoutH * 0.35), width: snoutW * 0.2, height: snoutH * 0.25), Paint()..color = cowBlack..style = PaintingStyle.stroke..strokeWidth = stroke * 0.8);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + snoutW * 0.2, snoutTop + snoutH * 0.35), width: snoutW * 0.12, height: snoutH * 0.15), Paint()..color = snoutPink);

    // Langue rouge qui dépasse (épaisse, arrondie)
    final tonguePath = Path();
    final ty = headTop + headH * 0.92;
    tonguePath.moveTo(cx - headW * 0.15, ty);
    tonguePath.quadraticBezierTo(cx - headW * 0.05, ty + headH * 0.25, cx, ty + headH * 0.32);
    tonguePath.quadraticBezierTo(cx + headW * 0.05, ty + headH * 0.25, cx + headW * 0.15, ty);
    tonguePath.quadraticBezierTo(cx, ty + headH * 0.08, cx - headW * 0.15, ty);
    tonguePath.close();
    canvas.drawPath(tonguePath, Paint()..color = tongueRed);
    canvas.drawPath(tonguePath, Paint()..color = cowBlack..style = PaintingStyle.stroke..strokeWidth = stroke * 0.8);

    // Bulles (elle se baigne dans le tonneau)
    canvas.drawCircle(Offset(cx - headW * 0.45, headTop + headH * 0.25), dw * 0.04, Paint()..color = blue.withValues(alpha: 0.6));
    canvas.drawCircle(Offset(cx + headW * 0.42, headTop + headH * 0.2), dw * 0.035, Paint()..color = blue.withValues(alpha: 0.6));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PloufLogoPainter oldDelegate) => oldDelegate.color != color;
}
