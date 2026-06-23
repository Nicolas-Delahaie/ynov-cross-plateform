# LinkedIn ou Interpol

Application mobile de jeu "swipe" où l'utilisateur devine si une photo de profil appartient à un profil LinkedIn professionnel ou à un criminel recherché par Interpol.

![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)

- **Frontend Flutter** → [frontend/README.md](frontend/README.md)
- **Backend Python** → [backend/README.md](backend/README.md)

> ⚠️ Le jeu a besoin des **deux côtés lancés en même temps** : le backend sert
> les profils et les photos (`/api/persons`, `/photos/...`), le frontend les
> affiche. Les données de jeu (`backend/data/app.db` + `backend/data/photos/`)
> sont déjà incluses dans le dépôt — aucun import à faire pour tester.

## Installation

### 1. Cloner le repository

```bash
git clone https://github.com/Nicolas-Delahaie/ynov-cross-plateform.git
cd ynov-cross-plateform
```

### 2. Lancer le backend (terminal 1)

```bash
cd backend
py -m pip install -r requirements.txt
py -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Détails complets : [backend/README.md#installation](backend/README.md#installation)

### 3. Lancer le frontend (terminal 2)

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

Détails complets : [frontend/README.md#installation](frontend/README.md#installation)
