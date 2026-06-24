# Frontend — LinkedIn ou Interpol

> Projet global → [README racine](../README.md)
> ℹ️ Le front fonctionne **avec ou sans backend lancé** : voir [Fallback offline](#fallback-offline-sans-backend).

## Fonctionnalités

- ✅ Données dynamiques via l'API backend (`GET /api/persons`) — voir [API Backend](#api-backend)
- ✅ Fallback offline avec de vraies photos si le backend est injoignable — voir [Fallback offline](#fallback-offline-sans-backend)
- ✅ Système de swipe gauche/droite ou boutons pour répondre
- ✅ Score et série (streak) en temps réel
- ✅ Barre de progression
- ✅ Feedback centré après chaque réponse (bon/faux + révélation du métier/délit)
- ✅ Compte à rebours (3·2·1) avant la carte suivante
- ✅ Sons de réussite / échec + vibrations haptiques
- ✅ Confettis sur bon score (>70%)
- ✅ Confirmation avant de quitter une partie en cours
- ✅ Statistiques persistantes (meilleur score, taux de réussite)
- ✅ Réinitialisation des statistiques (avec confirmation)
- ✅ Partage du score (`share_plus`)
- ✅ Paramètres personnalisables (son, vibration, mode sombre)

### Fonctionnalités futures

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
│   ├── data_service.dart             # source locale (assets/data/profiles.json), fallback
│   ├── api_data_service.dart         # ✅ source backend (GET /api/persons), avec fallback auto vers DataService
│   ├── api_profile_data_service.dart
│   └── storage_service.dart
├── screens/
│   ├── home_screen.dart
│   ├── game_screen.dart
│   ├── result_screen.dart
│   ├── statistics_screen.dart
│   └── settings_screen.dart
├── widgets/
│   ├── profile_card.dart
│   ├── game_header.dart          # score, série, barre de progression
│   ├── game_card_swiper.dart     # pile de cartes swipables
│   ├── game_feedback_overlay.dart # popup correct/raté apres chaque swipe
│   └── answer_buttons_row.dart   # boutons Interpol/LinkedIn
└── utils/
    ├── constants.dart
    └── app_theme.dart
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
- Le backend est **optionnel** (voir [backend/README.md](../backend/README.md)) : sans lui, le jeu utilise automatiquement les profils embarqués en local

## Installation

### 1. Installer les dépendances

```bash
flutter pub get
```

### 2. Lancer l'application

**Via le terminal :**

```bash
flutter run -d chrome
flutter run -d windows
flutter run -d android
flutter run -d ios
```

**Via VS Code :**

Ouvrir le dossier `frontend/` directement (`code frontend/`), puis sélectionner le device dans la barre de statut et lancer avec **F5**.

> ⚠️ Ne pas ouvrir la racine du dépôt — l'extension Flutter ne trouve pas le `pubspec.yaml`.

## Dépendances principales

```yaml
dependencies:
  provider: ^6.1.0              # State management
  shared_preferences: ^2.2.0    # Stockage local (statistiques, paramètres)
  flutter_card_swiper: ^7.2.0   # Swipe UI
  vibration: ^3.1.5             # Retour haptique
  confetti: ^0.8.0              # Animations
  audioplayers: ^6.1.0          # Sons réussite/échec
  share_plus: ^12.0.1           # Partage du score
  http: ^1.1.0                  # Requêtes HTTP (API backend)
```

- `assets/data/profiles.json` : 189 vrais profils (Interpol + PRO) exportés depuis `backend/data/app.db`, utilisés en fallback offline (via `DataService`).
- `assets/images/interpol/`, `assets/images/pro/` : les 189 photos correspondantes, embarquées dans l'app pour que le fallback affiche de vraies images (pas de placeholder).
- `assets/sounds/` : sons du jeu (`success.wav`, `fail.wav`).

**ℹ️ Source de données active :** l'app essaie d'abord le **backend**
(`ApiDataService` → `GET /api/persons`). Si injoignable (timeout, erreur), elle
bascule automatiquement sur les profils locaux ci-dessus — voir
[Fallback offline](#fallback-offline-sans-backend).

## Tests

```bash
flutter test
flutter test --coverage
```

## API Backend

L'app charge les profils depuis le backend FastAPI via `ApiDataService`
(branché dans `main.dart`). Endpoint consommé : **`GET /api/persons`**.

Réponse mappée vers le modèle `Profile` :

| Backend (`/api/persons`) | Front (`Profile`)      |
| ------------------------- | ------------------------ |
| `photo_url`               | `imageUrl`               |
| `post` (métier/délit)     | `context`                |
| `type` = `pro`            | `ProfileType.linkedin`   |
| `type` = `interpol`       | `ProfileType.interpol`   |

### Configurer l'URL du backend

Dans `main.dart`, selon l'endroit où tourne le front :

```dart
final IDataService dataService = ApiDataService(
  baseUrl: 'http://localhost:8000',   // web / Chrome (même PC)
  // baseUrl: 'http://10.0.2.2:8000', // émulateur Android
  // baseUrl: 'http://<IP-du-PC>:8000', // téléphone réel (même WiFi)
);
```

> Voir [`backend/README.md`](../backend/README.md) pour lancer le backend.
> Si le backend est injoignable, `ApiDataService` bascule automatiquement
> sur le fallback offline (voir ci-dessous) — l'écran de jeu reste fonctionnel.

## Fallback offline (sans backend)

Le front peut tourner **sans backend lancé**. `ApiDataService.loadProfiles()`
essaie l'API (`timeout` 15s) ; en cas d'échec (backend non démarré, erreur
réseau, réponse invalide), il bascule sur `DataService`, qui charge
`assets/data/profiles.json` (189 profils Interpol/PRO réels, exportés depuis
`backend/data/app.db`) et leurs photos dans `assets/images/`.

`ProfileCard` détecte automatiquement la source de l'image (`Image.network`
pour une URL backend, `Image.asset` pour un chemin local) — aucune
configuration nécessaire.

> Cette fonctionnalité va au-delà des contraintes minimales du projet : elle
> permet de démontrer le jeu sans dépendance au backend (ex. pour une
> correction rapide), tout en gardant l'intégration API complète et
> fonctionnelle quand le backend tourne.

> Si `backend/data/app.db` est régénéré (nouvel import via `/admin`), ce jeu
> de données local devient désynchronisé — il faudra réexporter
> `assets/data/profiles.json` et recopier les nouvelles photos dans
> `assets/images/` pour le remettre à jour.

## Contribution

### Workflow Git

1. Créer une branche feature
```bash
git checkout -b feature/nom-feature
```

2. Commit avec messages clairs
```bash
git commit -m "feat: ajout de [fonctionnalité]"
```

3. Push et créer une Pull Request
```bash
git push origin feature/nom-feature
```

### Conventions de code

- Suivre les [Dart style guidelines](https://dart.dev/guides/language/effective-dart/style)
- Commenter les interfaces et méthodes publiques
- Écrire des tests pour les nouvelles fonctionnalités
- Respecter les principes SOLID

### Messages de commit

Format : `type(scope): message`

Types :
- `feat` : Nouvelle fonctionnalité
- `fix` : Correction de bug
- `docs` : Documentation
- `style` : Formatage
- `refactor` : Refactoring
- `test` : Tests
- `chore` : Maintenance

Exemples :
```bash
git commit -m "feat(game): ajout du mode timer"
git commit -m "fix(storage): correction sauvegarde stats"
git commit -m "docs(readme): mise à jour installation"
```

## Auteurs

- **Frontend** : [Nicolas Delahaie](https://github.com/Nicolas-Delahaie)
- **Backend** : Anas

## Contact

Pour toute question ou suggestion :
- 🐛 Issues : [GitHub Issues](https://github.com/Nicolas-Delahaie/ynov-cross-plateform/issues)
