import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférence globale : sons de l'app activés ou non.
class SoundPreferencesService extends ChangeNotifier {
  SoundPreferencesService._();
  static final SoundPreferencesService instance = SoundPreferencesService._();

  static const _kEnabled = 'plouf_sounds_enabled';

  bool _enabled = true;
  bool _ready = false;

  bool get isReady => _ready;
  bool get enabled => _enabled;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    instance._enabled = prefs.getBool(_kEnabled) ?? true;
    instance._ready = true;
    instance.notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, value);
    notifyListeners();
  }
}
