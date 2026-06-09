import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import '../interfaces/i_storage_service.dart';
import '../utils/constants.dart';

/// Provider pour les paramètres (Single Responsibility + Dependency Injection)
class SettingsProvider with ChangeNotifier {
  final IStorageService _storageService;

  bool _soundEnabled = false;
  bool _vibrationEnabled = true;
  int _difficulty = AppConstants.defaultProfilesPerGame;
  bool _isInitialized = false;

  SettingsProvider(this._storageService);

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  int get difficulty => _difficulty;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    await _storageService.init();
    _loadSettings();
    _isInitialized = true;
    notifyListeners();
  }

  void _loadSettings() {
    _soundEnabled = _storageService.getSoundEnabled();
    _vibrationEnabled = _storageService.getVibrationEnabled();
    _difficulty = _storageService.getDifficulty();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _storageService.setSoundEnabled(enabled);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _storageService.setVibrationEnabled(enabled);
    notifyListeners();
  }

  Future<void> setDifficulty(int profilesPerGame) async {
    _difficulty = profilesPerGame;
    await _storageService.setDifficulty(profilesPerGame);
    notifyListeners();
  }

  Future<void> vibrateIfEnabled({int duration = 100}) async {
    if (!_vibrationEnabled) return;

    final bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: duration);
    }
  }

  Future<void> vibrateSuccess() async {
    await vibrateIfEnabled(duration: 50);
  }

  Future<void> vibrateError() async {
    await vibrateIfEnabled(duration: 200);
  }

  Future<void> vibrateTap() async {
    await vibrateIfEnabled(duration: 30);
  }

  Future<void> vibrateCelebration() async {
    await vibrateIfEnabled(duration: 100);
    await Future.delayed(const Duration(milliseconds: 120));
    await vibrateIfEnabled(duration: 200);
  }
}
