import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tirage_equipes/services/sound_preferences_service.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SoundPreferencesService.init();
  });

  test('sons activés par défaut', () {
    expect(SoundPreferencesService.instance.enabled, isTrue);
  });

  test('désactivation persistée', () async {
    await SoundPreferencesService.instance.setEnabled(false);
    expect(SoundPreferencesService.instance.enabled, isFalse);
    await SoundPreferencesService.instance.setEnabled(true);
    expect(SoundPreferencesService.instance.enabled, isTrue);
  });
}
