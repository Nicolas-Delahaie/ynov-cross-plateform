# Backend MACEN — Guide d'utilisation

## Prérequis

- Python 3.11+
- pip

---

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

## Interface d'administration

Ouvrir dans un navigateur : **http://localhost:8000/admin**

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

> Source photos PRO : Lexica.art (visages arabes / moyen-orientaux générés par IA).
> Si Lexica est indisponible → bascule automatique sur randomuser.me.
> Répartition : 70 % hommes, 30 % femmes (40 ans+).

---

## Structure des données

### Base de données SQLite — `data/app.db`

#### Table `persons` — profils unifiés (Interpol + PRO)

```sql
CREATE TABLE persons (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    forename   TEXT NOT NULL,       -- prénom
    surname    TEXT,                -- nom de famille
    job        TEXT,                -- PRO uniquement : métier fictif (NULL pour Interpol)
    type       TEXT NOT NULL,       -- "interpol" | "pro"
    photo_path TEXT NOT NULL,       -- chemin relatif, ex: "pro/uuid.jpg" ou "interpol/2024-1234.jpg"
    source_id  TEXT UNIQUE,         -- UUID (PRO) ou notice_id Interpol
    created_at TEXT NOT NULL        -- ISO 8601
)
```

#### Table `interpol_notice` — données brutes Interpol

```sql
CREATE TABLE interpol_notice (
    notice_id   TEXT PRIMARY KEY,
    notice_type TEXT NOT NULL,      -- "red"
    display_name TEXT,
    nationalities TEXT,
    date_of_birth TEXT,
    image_url   TEXT,               -- URL source Interpol (photo en ligne)
    charge      TEXT,               -- ex: "Criminal act of kidnapping, attempted robbery and murder"
    raw_json    TEXT,               -- JSON complet de l'API Interpol
    fetched_at  TEXT NOT NULL
)
```

---

## Accès aux photos

Les photos sont servies statiquement par le backend :

```
GET http://localhost:8000/photos/{photo_path}
```

Comme:

```
http://localhost:8000/photos/interpol/2023-21420.jpg
```

**Exemples :**

| `photo_path` en DB        | URL complète                                           |
| ------------------------- | ------------------------------------------------------ |
| `pro/3f2a1b4c-…-uuid.jpg` | `http://localhost:8000/photos/pro/3f2a1b4c-…-uuid.jpg` |
| `interpol/2024-74464.jpg` | `http://localhost:8000/photos/interpol/2024-74464.jpg` |

> Les fichiers sont stockés localement dans `backend/data/photos/`.

---

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

## Arborescence

```
backend/
├── main.py                        # entrée FastAPI, mount /photos
├── requirements.txt
├── data/
│   ├── app.db                     # SQLite
│   └── photos/
│       ├── interpol/              # photos avis rouges (.jpg)
│       └── pro/                   # photos profils fictifs (.jpg)
├── templates/
│   ├── dashboard.html
│   ├── _cards_grid.html           # grille Interpol
│   └── _cards_grid_pro.html       # grille PRO
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
```
