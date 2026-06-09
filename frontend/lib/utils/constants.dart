import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryColor = Color(0xFF0077B5); // LinkedIn blue
  static const Color secondaryColor = Color(0xFFDC143C); // Interpol red
  static const Color backgroundColor = Color(0xFFF3F4F6);
  static const Color textColor = Color(0xFF1F2937);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);

  // Game settings
  static const int defaultProfilesPerGame = 20;
  static const int easyProfilesPerGame = 10;
  static const int hardProfilesPerGame = 30;
  
  // Animations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);
  
  // Streak threshold for confetti
  static const int confettiStreakThreshold = 5;
  
  // Storage keys
  static const String statisticsKey = 'user_statistics';
  static const String settingsSoundKey = 'settings_sound';
  static const String settingsVibrationKey = 'settings_vibration';
  static const String settingsDifficultyKey = 'settings_difficulty';
  static const String settingsDarkModeKey = 'settings_dark_mode';
  
  // Asset paths
  static const String profilesDataPath = 'assets/data/profiles.json';
}
