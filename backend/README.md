# Backend — LinkedIn ou Interpol

> Projet global → [README racine](../README.md)

## Prérequis

- Python 3.11+
- pip

## Installation

```powershell
cd backend
py -m pip install -r requirements.txt
```

> Sur Windows, la commande `py -m ...` est recommandée pour éviter les problèmes de PATH avec `uvicorn`.
> Sur macOS/Linux, remplacer `py -m pip` par `pip3` (ou `pip`).

## Lancer le serveur

```powershell
cd backend
py -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

```bash
# macOS / Linux
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Le serveur est accessible sur **http://127.0.0.1:8000**.

> Les données de jeu (`data/app.db` + `data/photos/`) sont déjà incluses dans le
> dépôt : aucun import n'est nécessaire pour lancer le jeu. L'interface
> `/admin` reste disponible pour régénérer un nouveau jeu de données si besoin
> (voir ci-dessous).

## Interface d'administration

Ouvrir **http://127.0.0.1:8000/admin**

### Section Interpol (notices rouges)

| Bouton                    | Action                                                                             |
| -------------------------- | ----------------------------------------------------------------------------------- |
| **Import Interpol (100)** | Télécharge jusqu'à 100 avis rouges depuis l'API publique Interpol, photos incluses |
| **Vider**                  | Supprime toutes les notices de la DB + les photos locales                          |

> L'import efface automatiquement les données existantes avant de relancer.
> L'import tourne **en tâche de fond** : une **barre de progression** s'affiche en
> temps réel (polling HTMX) et bascule sur la grille de cartes une fois terminé.

### Section PRO (profils fictifs)

| Bouton                | Action                                                       |
| ---------------------- | ------------------------------------------------------------- |
| **Import PRO (100)**  | Génère 100 profils fictifs avec photo, prénom, nom, métier   |
| **Vider**              | Supprime tous les profils PRO de la DB + les photos locales  |

> Source photos PRO : Lexica.art (visages générés par IA). Bascule automatique sur randomuser.me si indisponible.
> Répartition : 70 % hommes, 30 % femmes (40 ans+).

> ⚠️ Si tu relances un import, les **UUID des photos PRO changent** : pense à
> recommitter `data/app.db` + `data/photos/` ensemble pour que les autres
> contributeurs (et le correcteur) aient des données cohérentes.

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
GET http://127.0.0.1:8000/photos/{photo_path}
```

| `photo_path` en DB        | URL complète                                            |
| -------------------------- | --------------------------------------------------------- |
| `pro/3f2a1b4c-…-uuid.jpg` | `http://127.0.0.1:8000/photos/pro/3f2a1b4c-…-uuid.jpg`  |
| `interpol/2024-74464.jpg` | `http://127.0.0.1:8000/photos/interpol/2024-74464.jpg`  |

## API REST pour le jeu — `GET /api/persons`

Endpoint qui alimente le jeu Flutter « LinkedIn ou Interpol ». Renvoie un
**mélange aléatoire** PRO + Interpol, chaque item unifié pour le front.

**Paramètres :**

| Param   | Défaut    | Description                                          |
| ------- | --------- | ------------------------------------------------------ |
| `limit` | 20        | Nombre de profils (max 200)                            |
| `type`  | _(vide)_  | `pro` (LinkedIn) ou `interpol`. Vide = mix des deux    |

**Exemple : `GET http://127.0.0.1:8000/api/persons?limit=20`**

```json
{
  "count": 20,
  "persons": [
    {
      "id": 12,
      "type": "interpol",
      "name": "JOHN DOE",
      "post": "Criminal act of kidnapping, attempted robbery and murder",
      "photo_url": "http://127.0.0.1:8000/photos/interpol/2024-74464.jpg"
    },
    {
      "id": 13,
      "type": "pro",
      "name": "Omar Leroy",
      "post": "Financial Analyst",
      "photo_url": "http://127.0.0.1:8000/photos/pro/3f2a1b4c.jpg"
    }
  ]
}
```

- **`type`** : la bonne réponse du jeu (`pro` | `interpol`).
- **`post`** : champ unifié = métier (PRO) ou délit (Interpol) — le front l'affiche sans distinction.
- **`photo_url`** : URL absolue construite à partir de l'hôte appelant (marche en web, émulateur, ou téléphone).

> **CORS** est activé (`*`) pour autoriser le front Flutter (web/émulateur/téléphone).
> Implémentation : `app/api/routes/persons.py` + `CacheService.list_persons_for_game()`.

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
```
