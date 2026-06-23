import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../interfaces/i_storage_service.dart';
import '../models/user_statistics.dart';
import '../utils/constants.dart';

/// Implémentation concrète du service de stockage (Dependency Inversion Principle)
class StorageService implements IStorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Statistics
  @override
  Future<void> saveStatistics(UserStatistics statistics) async {
    await _prefs?.setString(
      AppConstants.statisticsKey,
      jsonEncode(statistics.toJson()),
    );
  }

  @override
  UserStatistics? loadStatistics() {
    final String? statisticsJson = _prefs?.getString(AppConstants.statisticsKey);
    if (statisticsJson == null) return null;
    
    try {
      return UserStatistics.fromJson(jsonDecode(statisticsJson));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearStatistics() async {
    await _prefs?.remove(AppConstants.statisticsKey);
  }

  // Settings
  @override
  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs?.setBool(AppConstants.settingsSoundKey, enabled);
  }

  @override
  bool getSoundEnabled() {
    return _prefs?.getBool(AppConstants.settingsSoundKey) ?? true;
  }

  @override
  Future<void> setVibrationEnabled(bool enabled) async {
    await _prefs?.setBool(AppConstants.settingsVibrationKey, enabled);
  }

  @override
  bool getVibrationEnabled() {
    return _prefs?.getBool(AppConstants.settingsVibrationKey) ?? true;
  }

  @override
  Future<void> setDifficulty(int profilesPerGame) async {
    await _prefs?.setInt(AppConstants.settingsDifficultyKey, profilesPerGame);
  }

  @override
  int getDifficulty() {
    return _prefs?.getInt(AppConstants.settingsDifficultyKey) ??
        AppConstants.defaultProfilesPerGame;
  }

  @override
  Future<void> setDarkMode(bool enabled) async {
    await _prefs?.setBool(AppConstants.settingsDarkModeKey, enabled);
  }

  @override
  bool getDarkMode() {
    return _prefs?.getBool(AppConstants.settingsDarkModeKey) ?? false;
  }
}
