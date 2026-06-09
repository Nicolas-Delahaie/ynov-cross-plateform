# Backend — LinkedIn ou Interpol

> Projet global → [README racine](../README.md)

## Prérequis

- Python 3.11+
- pip

## Installation

Depuis la racine du projet :

```powershell
cd backend
py -m pip install -r requirements.txt
```

> Sur Windows, la commande `py -m ...` est recommandée pour éviter les problèmes de PATH avec `uvicorn`.

---

## Lancer le serveur

```powershell
cd backend
py -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Le serveur est accessible sur **http://127.0.0.1:8000**.

Si votre environnement Python est déjà configuré dans le PATH, vous pouvez aussi utiliser :

```powershell
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

---
```bash
pip install -r requirements.txt
```

## Lancer le serveur

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Accessible sur **<http://localhost:8000>**

## Interface d'administration

Ouvrir **<http://localhost:8000/admin>**

### Section Interpol (notices rouges)

| Bouton                    | Action                                                                             |
| ------------------------- | ---------------------------------------------------------------------------------- |
| **Import Interpol (100)** | Télécharge jusqu'à 100 avis rouges depuis l'API publique Interpol, photos incluses |
| **Vider**                 | Supprime toutes les notices de la DB + les photos locales                          |

> L'import efface automatiquement les données existantes avant de relancer.
> L'import tourne **en tâche de fond** : une **barre de progression** s'affiche en
> temps réel (polling HTMX) et bascule sur la grille de cartes une fois terminé.

### Section PRO (profils fictifs)

| Bouton               | Action                                                      |
| -------------------- | ----------------------------------------------------------- |
| **Import PRO (100)** | Génère 100 profils fictifs avec photo, prénom, nom, métier  |
| **Vider**            | Supprime tous les profils PRO de la DB + les photos locales |

> Source photos PRO : Lexica.art (visages générés par IA). Bascule automatique sur randomuser.me si indisponible.
> Répartition : 70 % hommes, 30 % femmes (40 ans+).

## Structure des données

### Base de données SQLite — `data/app.db`

#### Table `persons`

```sql
CREATE TABLE persons (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    forename   TEXT NOT NULL,
    surname    TEXT,
    job        TEXT,         -- PRO: métier fictif | Interpol: NULL
    type       TEXT NOT NULL, -- "interpol" | "pro"
    photo_path TEXT NOT NULL, -- ex: "pro/uuid.jpg" ou "interpol/2024-1234.jpg"
    source_id  TEXT UNIQUE,
    created_at TEXT NOT NULL  -- ISO 8601
)
```

#### Table `interpol_notice`

```sql
CREATE TABLE interpol_notice (
    notice_id    TEXT PRIMARY KEY,
    notice_type  TEXT NOT NULL,  -- "red"
    display_name TEXT,
    nationalities TEXT,
    date_of_birth TEXT,
    image_url    TEXT,
    charge       TEXT,
    raw_json     TEXT,
    fetched_at   TEXT NOT NULL
)
```

## Accès aux photos

```
GET http://localhost:8000/photos/{photo_path}
```

| `photo_path` en DB        | URL complète                                           |
| ------------------------- | ------------------------------------------------------ |
| `pro/3f2a1b4c-…-uuid.jpg` | `http://localhost:8000/photos/pro/3f2a1b4c-…-uuid.jpg` |
| `interpol/2024-74464.jpg` | `http://localhost:8000/photos/interpol/2024-74464.jpg` |

## Intégration Flutter

## API REST pour le jeu — `GET /api/persons` ✅ (implémenté)

Endpoint qui alimente le jeu Flutter « LinkedIn ou Interpol ». Renvoie un
**mélange aléatoire** PRO + Interpol, chaque item unifié pour le front.

**Paramètres :**

| Param   | Défaut | Description                                              |
| ------- | ------ | ------------------------------------------------------- |
| `limit` | 20     | Nombre de profils (max 200)                             |
| `type`  | _(vide)_ | `pro` (LinkedIn) ou `interpol`. Vide = mix des deux    |

**Exemple : `GET http://localhost:8000/api/persons?limit=20`**

```json
{
  "count": 20,
  "persons": [
    {
      "id": 12,
      "type": "interpol",
      "name": "JOHN DOE",
      "post": "Criminal act of kidnapping, attempted robbery and murder",
      "photo_url": "http://localhost:8000/photos/interpol/2024-74464.jpg"
    },
    {
      "id": 13,
      "type": "pro",
      "name": "Omar Leroy",
      "post": "Financial Analyst",
      "photo_url": "http://localhost:8000/photos/pro/3f2a1b4c.jpg"
    }
  ]
}
```

- **`type`** : la bonne réponse du jeu (`pro` | `interpol`).
- **`post`** : champ unifié = métier (PRO) ou délit (Interpol) — le front l'affiche sans distinction.
- **`photo_url`** : URL absolue construite à partir de l'hôte appelant (marche en web, émulateur, ou téléphone).

> **CORS** est activé (`*`) pour autoriser le front Flutter (web/émulateur/téléphone).
> Implémentation : `backend/app/api/routes/persons.py` + `CacheService.list_persons_for_game()`.

### Accès direct SQLite (alternative, si même machine)

```dart
// Avec le package sqflite ou sqlite3
final db = await openDatabase('path/to/data/app.db');
final rows = await db.query('persons', where: 'type = ?', whereArgs: ['pro']);
```

---

Endpoint à créer : `GET /api/persons?type=pro&limit=100`

Réponse attendue :

```json
{
  "forename": "Omar",
  "surname": "Leroy",
  "job": "Financial Analyst",
  "charge": null,
  "type": "pro",
  "photo_url": "http://localhost:8000/photos/pro/3f2a1b4c.jpg"
}
```

Fichier à créer : `app/api/routes/persons.py`

```sql
SELECT p.forename, p.surname, p.job, p.type, p.photo_path, i.charge
FROM persons p
LEFT JOIN interpol_notice i ON p.source_id = i.notice_id
WHERE p.type = ?
ORDER BY RANDOM()
LIMIT ?
```

## Arborescence

```text
backend/
├── main.py
├── requirements.txt
├── data/
│   ├── app.db
│   └── photos/
│       ├── interpol/
│       └── pro/
├── templates/
│   ├── dashboard.html
│   ├── _cards_grid.html
│   └── _cards_grid_pro.html
└── app/
    ├── api/routes/
    │   ├── admin_dashboard.py     # GET /admin
    │   ├── admin_import.py        # POST /admin/import, /import/pro, /clear/*, GET /admin/progress/{kind}
    │   └── persons.py             # GET /api/persons (API du jeu)
    └── services/
        ├── cache_service.py       # SQLite (lecture/écriture)
        ├── interpol_service.py    # API Interpol + download photos
        ├── pro_service.py         # génération profils + Lexica/randomuser
        ├── import_service.py      # orchestration imports
        └── progress.py            # état de progression des imports (barre)
    │   ├── admin_dashboard.py
    │   └── admin_import.py
    └── services/
        ├── cache_service.py
        ├── interpol_service.py
        ├── pro_service.py
        └── import_service.py
```
