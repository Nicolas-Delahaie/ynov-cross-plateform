import '../models/user_statistics.dart';

/// Interface pour le service de stockage persistant.
///
/// Fournit une abstraction pour sauvegarder et charger des données
/// de manière persistante (SharedPreferences, Hive, etc.).
/// Suit le principe Dependency Inversion (SOLID) pour permettre
/// différentes implémentations de stockage.
abstract class IStorageService {
  /// Initialise le service de stockage.
  ///
  /// Doit être appelé avant toute autre opération.
  /// Lance une [StorageException] en cas d'erreur d'initialisation.
  Future<void> init();

  // === Gestion des statistiques ===

  /// Sauvegarde les statistiques utilisateur.
  ///
  /// [statistics] : Objet [UserStatistics] à persister.
  Future<void> saveStatistics(UserStatistics statistics);

  /// Charge les statistiques utilisateur depuis le stockage.
  ///
  /// Retourne les [UserStatistics] sauvegardées, ou null si aucune statistique n'existe.
  UserStatistics? loadStatistics();

  /// Efface toutes les statistiques sauvegardées.
  ///
  /// Action irréversible.
  Future<void> clearStatistics();

  // === Gestion des paramètres ===

  /// Sauvegarde l'état d'activation du son.
  ///
  /// [enabled] : `true` pour activer le son, `false` pour le désactiver.
  Future<void> setSoundEnabled(bool enabled);

  /// Récupère l'état d'activation du son.
  ///
  /// Retourne `false` par défaut si la valeur n'a jamais été définie.
  bool getSoundEnabled();

  /// Sauvegarde l'état d'activation des vibrations.
  ///
  /// [enabled] : `true` pour activer les vibrations, `false` pour les désactiver.
  Future<void> setVibrationEnabled(bool enabled);

  /// Récupère l'état d'activation des vibrations.
  ///
  /// Retourne `true` par défaut si la valeur n'a jamais été définie.
  bool getVibrationEnabled();

  /// Sauvegarde le niveau de difficulté (nombre de profils par partie).
  ///
  /// [profilesPerGame] : Nombre de profils à utiliser dans une partie.
  Future<void> setDifficulty(int profilesPerGame);

  /// Récupère le niveau de difficulté (nombre de profils par partie).
  ///
  /// Retourne la valeur par défaut si la valeur n'a jamais été définie.
  int getDifficulty();

  /// Sauvegarde l'état du mode sombre.
  Future<void> setDarkMode(bool enabled);

  /// Récupère l'état du mode sombre.
  ///
  /// Retourne `false` par défaut si la valeur n'a jamais été définie.
  bool getDarkMode();
}
