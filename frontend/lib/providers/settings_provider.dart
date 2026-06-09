import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import '../interfaces/i_storage_service.dart';
import '../utils/constants.dart';

/// Provider pour les paramètres (Single Responsibility + Dependency Injection)
class SettingsProvider with ChangeNotifier {
  final IStorageService _storageService;
  final AudioPlayer _player = AudioPlayer();

  bool _soundEnabled = true;
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

  Future<void> _playSound(String asset) async {
    if (!_soundEnabled) return;
    try {
      // ReleaseMode.stop : on peut rejouer rapidement le même son
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('Sound error ($asset): $e');
    }
  }

  /// Son agréable de réussite.
  Future<void> playSuccess() => _playSound('sounds/success.wav');

  /// Son d'échec (trombone triste).
  Future<void> playError() => _playSound('sounds/fail.wav');

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  Future<void> vibrateTap() async {
    await vibrateIfEnabled(duration: 30);
  }

  Future<void> vibrateCelebration() async {
    await vibrateIfEnabled(duration: 100);
    await Future.delayed(const Duration(milliseconds: 120));
    await vibrateIfEnabled(duration: 200);
  }
}
