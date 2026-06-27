import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tirage_equipes/services/pick_fairness_service.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await PickFairnessService.init();
  });

  test('pickOne favorise les moins tirés', () {
    final random = Random(42);
    final service = PickFairnessService.instance;
    final counts = <String, int>{'Alice': 0, 'Bob': 0, 'Charlie': 0};

    for (var i = 0; i < 30; i++) {
      service.beginSession();
      final picked = service.pickOne(
        ['Alice', 'Bob', 'Charlie'],
        random,
        favorEquity: true,
      );
      service.recordPicks([picked]);
      counts[picked] = counts[picked]! + 1;
    }

    expect(counts['Alice']! + counts['Bob']! + counts['Charlie']!, 30);
    final spread = counts.values.reduce((a, b) => a > b ? a : b) -
        counts.values.reduce((a, b) => a < b ? a : b);
    expect(spread, lessThanOrEqualTo(8));
  });

  test('pickMany sans remplacement', () {
    final random = Random(1);
    final service = PickFairnessService.instance;
    final picks = service.pickMany(
      ['A', 'B', 'C', 'D'],
      3,
      random,
      favorEquity: false,
    );
    expect(picks.length, 3);
    expect(picks.toSet().length, 3);
  });
}
