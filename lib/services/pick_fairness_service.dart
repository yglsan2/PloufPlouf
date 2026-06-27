import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Suivi local de l'équité des tirages (roue + tirage au sort).
/// Favorise les élèves moins souvent appelés, sans compte cloud.
class PickFairnessService extends ChangeNotifier {
  PickFairnessService._();
  static final PickFairnessService instance = PickFairnessService._();

  static const _kData = 'plouf_pick_fairness_v1';

  final Map<String, int> _pickCounts = {};
  final Map<String, int> _lastSession = {};
  int _sessionCounter = 0;
  bool _ready = false;

  bool get isReady => _ready;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kData);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        instance._sessionCounter = map['session'] as int? ?? 0;
        final counts = map['counts'] as Map<String, dynamic>? ?? {};
        final last = map['last'] as Map<String, dynamic>? ?? {};
        instance._pickCounts
          ..clear()
          ..addAll(counts.map((k, v) => MapEntry(k, v as int)));
        instance._lastSession
          ..clear()
          ..addAll(last.map((k, v) => MapEntry(k, v as int)));
      } catch (_) {
        // Données corrompues : repartir à zéro.
      }
    }
    instance._ready = true;
    instance.notifyListeners();
  }

  int pickCount(String name) => _pickCounts[name] ?? 0;

  /// Nombre de séances depuis le dernier tirage de cet élève (plus = prioritaire).
  int sessionsSince(String name) {
    final last = _lastSession[name];
    if (last == null) return _sessionCounter + 1;
    return _sessionCounter - last;
  }

  /// Pastille visuelle : 0 = jamais tiré, 1 = récent, 2 = normal, 3 = ancien.
  int fairnessTier(String name) {
    final since = sessionsSince(name);
    if (_lastSession[name] == null) return 0;
    if (since <= 1) return 1;
    if (since <= 3) return 2;
    return 3;
  }

  void beginSession() {
    _sessionCounter++;
    _persist();
    notifyListeners();
  }

  void recordPicks(Iterable<String> names) {
    for (final name in names) {
      _pickCounts[name] = (_pickCounts[name] ?? 0) + 1;
      _lastSession[name] = _sessionCounter;
    }
    _persist();
    notifyListeners();
  }

  String pickOne(List<String> candidates, Random random, {required bool favorEquity}) {
    if (candidates.isEmpty) throw ArgumentError('Liste vide');
    if (!favorEquity || candidates.length == 1) {
      return candidates[random.nextInt(candidates.length)];
    }
    final weights = candidates.map((c) => sessionsSince(c) + 1).toList();
    final total = weights.fold<int>(0, (a, b) => a + b);
    var roll = random.nextDouble() * total;
    for (var i = 0; i < candidates.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return candidates[i];
    }
    return candidates.last;
  }

  List<String> pickMany(
    List<String> candidates,
    int count,
    Random random, {
    required bool favorEquity,
  }) {
    final pool = List<String>.from(candidates);
    final result = <String>[];
    final n = count.clamp(0, pool.length);
    for (var i = 0; i < n; i++) {
      final picked = pickOne(pool, random, favorEquity: favorEquity);
      result.add(picked);
      pool.remove(picked);
    }
    return result;
  }

  Future<void> resetAll() async {
    _pickCounts.clear();
    _lastSession.clear();
    _sessionCounter = 0;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kData,
      jsonEncode({
        'session': _sessionCounter,
        'counts': _pickCounts,
        'last': _lastSession,
      }),
    );
  }
}
