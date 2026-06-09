# Frontend — LinkedIn ou Interpol

> Projet global → [README racine](../README.md)

## Fonctionnalités

### MVP (Version actuelle)

- ✅ Système de swipe gauche/droite ou boutons pour répondre
- ✅ Score et série (streak) en temps réel
- ✅ Barre de progression
- ✅ Vibrations haptiques sur succès/erreur
- ✅ Confettis sur bon score (>70%)
- ✅ Statistiques persistantes (meilleur score, taux de réussite)
- ✅ 3 niveaux de difficulté (10/20/30 photos)
- ✅ Paramètres personnalisables (son, vibration)

### Fonctionnalités futures

- 🔲 Intégration API backend pour données dynamiques
- 🔲 Système de sons
- 🔲 Partage de score sur réseaux sociaux
- 🔲 Mode timer/challenge
- 🔲 Leaderboard en ligne

## Architecture

Le projet suit les **principes SOLID** et utilise une architecture en couches :

```text
lib/
├── interfaces/           # Abstractions (Dependency Inversion)
│   ├── i_data_service.dart
│   ├── i_storage_service.dart
│   ├── i_profile_repository.dart
│   └── i_statistics_repository.dart
├── models/               # Modèles de données
│   ├── profile.dart
│   ├── game_session.dart
│   └── user_statistics.dart
├── providers/            # State Management (Provider)
│   ├── game_provider.dart
│   ├── settings_provider.dart
│   └── statistics_provider.dart
├── repositories/         # Repository Pattern
│   ├── profile_repository.dart
│   └── statistics_repository.dart
├── services/             # Services concrets
│   ├── data_service.dart
│   └── storage_service.dart
├── screens/
│   ├── home_screen.dart
│   ├── game_screen.dart
│   ├── result_screen.dart
│   ├── statistics_screen.dart
│   └── settings_screen.dart
├── widgets/
│   └── profile_card.dart
└── utils/
    └── constants.dart
```

### Patterns utilisés

- **Repository Pattern** : Abstraction de l'accès aux données
- **Dependency Injection** : Injection des dépendances via constructeurs
- **Provider Pattern** : Gestion d'état réactive

## Principes SOLID

### S - Single Responsibility Principle ✅

- `GameProvider` : Logique du jeu uniquement
- `StatisticsProvider` : Gestion des statistiques uniquement
- `SettingsProvider` : Gestion des paramètres uniquement

### O - Open/Closed Principle ✅

Les interfaces permettent l'extension sans modification :

- Ajouter `ApiDataService implements IDataService` sans toucher au reste
- Changer le stockage en implémentant `IStorageService`

### L - Liskov Substitution Principle ✅

- `DataService` peut être remplacé par `ApiDataService`
- `StorageService` peut être remplacé par `SecureStorageService`

### I - Interface Segregation Principle ✅

- `IProfileRepository` : opérations sur les profils uniquement
- `IStatisticsRepository` : opérations sur les stats uniquement

### D - Dependency Inversion Principle ✅

```dart
class GameProvider {
  final IProfileRepository _profileRepository;  // Interface
  final StatisticsProvider _statisticsProvider;

  GameProvider(this._profileRepository, this._statisticsProvider);
}
```

## Prérequis

- Flutter SDK 3.10+
- Dart SDK 3.0+
- Android Studio / Xcode pour les émulateurs

## Installation

### 1. Installer les dépendances

```bash
flutter pub get
```

### 2. Lancer l'application

**Via le terminal :**

```bash
flutter run -d android
flutter run -d ios
flutter run -d chrome
flutter run -d windows
```

**Via VS Code :**

Ouvrir le dossier `frontend/` directement (`code frontend/`), puis sélectionner le device dans la barre de statut et lancer avec **F5**.

> ⚠️ Ne pas ouvrir la racine du dépôt — l'extension Flutter ne trouve pas le `pubspec.yaml`.

## Dépendances principales

```yaml
dependencies:
  provider: ^6.1.0 # State management
  shared_preferences: ^2.2.0 # Stockage local
  hive: ^2.2.3 # Base de données locale
  hive_flutter: ^1.1.0
  flutter_card_swiper: ^7.2.0 # Swipe UI
  vibration: ^3.1.5 # Retour haptique
  confetti: ^0.8.0 # Animations
  share_plus: ^12.0.1 # Partage
  http: ^1.1.0 # Requêtes HTTP
```

Les profils de test sont dans `assets/data/profiles.json` — seront remplacés par l'API backend.

## Tests

```bash
flutter test
flutter test --coverage
```

## Intégration API backend

Pour basculer vers l'API (voir [backend/README.md](../backend/README.md)) :

1. Créer `ApiDataService implements IDataService`
2. Remplacer dans `main.dart` :

```dart
final IDataService dataService = ApiDataService(baseUrl: 'http://localhost:8000');
```

Aucune autre modification nécessaire grâce à SOLID.
