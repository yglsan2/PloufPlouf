// Basic Flutter widget test for PloufPlouf.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tirage_equipes/main.dart';
import 'package:tirage_equipes/services/pick_fairness_service.dart';
import 'package:tirage_equipes/services/sound_preferences_service.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await PickFairnessService.init();
    await SoundPreferencesService.init();
  });

  testWidgets('App loads and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const PloufPloufApp());

    expect(find.text('PloufPlouf'), findsWidgets);
    expect(find.text('Équipes'), findsOneWidget);
    expect(find.text('Tirage'), findsOneWidget);
    expect(find.text('Roue'), findsOneWidget);
  });
}
