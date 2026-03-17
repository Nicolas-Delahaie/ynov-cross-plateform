# backend/app/services/cache_service.py
import sqlite3
from typing import Optional, Dict, Any, List
from pathlib import Path
import json
from datetime import datetime, timezone


class CacheService:
    def __init__(self, db_path: str = "data/app.db") -> None:
        Path(db_path).parent.mkdir(parents=True, exist_ok=True)
        self.db_path = db_path
        self._init_db()

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self) -> None:
        with self._connect() as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS interpol_notice (
                    notice_id TEXT PRIMARY KEY,
                    notice_type TEXT NOT NULL,
                    display_name TEXT,
                    nationalities TEXT,
                    date_of_birth TEXT,
                    image_url TEXT,
                    raw_json TEXT,
                    charge TEXT,
                    fetched_at TEXT NOT NULL
                )
            """)
            # Migration : ajout colonne charge si table existait déjà sans elle
            try:
                conn.execute("ALTER TABLE interpol_notice ADD COLUMN charge TEXT")
            except Exception:
                pass  # colonne déjà présente
            conn.execute("""
                CREATE TABLE IF NOT EXISTS persons (
                    id         INTEGER PRIMARY KEY AUTOINCREMENT,
                    forename   TEXT NOT NULL,
                    surname    TEXT,
                    job        TEXT,
                    type       TEXT NOT NULL,
                    photo_path TEXT NOT NULL,
                    source_id  TEXT UNIQUE,
                    created_at TEXT NOT NULL
                )
            """)
            conn.commit()

    # ── interpol_notice (existant, inchangé) ─────────────────────────────────

    def clear_interpol(self, notice_type: str = "red") -> None:
        with self._connect() as conn:
            conn.execute("DELETE FROM interpol_notice WHERE notice_type = ?", (notice_type,))
            conn.commit()

    def upsert_notice(self, notice: Dict[str, Any]) -> None:
        with self._connect() as conn:
            conn.execute("""
                INSERT INTO interpol_notice (
                    notice_id, notice_type, display_name, nationalities, date_of_birth,
                    image_url, raw_json, charge, fetched_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(notice_id) DO UPDATE SET
                    notice_type=excluded.notice_type,
                    display_name=excluded.display_name,
                    nationalities=excluded.nationalities,
                    date_of_birth=excluded.date_of_birth,
                    image_url=excluded.image_url,
                    raw_json=excluded.raw_json,
                    charge=excluded.charge,
                    fetched_at=excluded.fetched_at
            """, (
                notice["notice_id"],
                notice["notice_type"],
                notice.get("display_name"),
                notice.get("nationalities"),
                notice.get("date_of_birth"),
                notice.get("image_url"),
                json.dumps(notice.get("raw_json")) if notice.get("raw_json") else None,
                notice.get("charge"),
                datetime.now(timezone.utc).isoformat(),
            ))
            conn.commit()

    def stats(self) -> Dict[str, Any]:
        with self._connect() as conn:
            total = conn.execute("SELECT COUNT(*) AS c FROM interpol_notice").fetchone()["c"]
            with_photo = conn.execute(
                "SELECT COUNT(*) AS c FROM interpol_notice WHERE image_url IS NOT NULL AND image_url != ''"
            ).fetchone()["c"]
            last_import = conn.execute(
                "SELECT MAX(fetched_at) AS m FROM interpol_notice"
            ).fetchone()["m"]

        pct = round((with_photo / total * 100.0), 1) if total else 0.0
        return {"total": total, "with_photo": with_photo, "pct_with_photo": pct, "last_import": last_import}

    def list_notices_with_image(self, notice_type: str = "red", limit: int = 120) -> List[Dict[str, Any]]:
        with self._connect() as conn:
            rows = conn.execute("""
                SELECT notice_id, notice_type, display_name, nationalities, date_of_birth,
                       image_url, charge, fetched_at
                FROM interpol_notice
                WHERE notice_type = ?
                  AND image_url IS NOT NULL AND image_url != ''
                ORDER BY fetched_at DESC
                LIMIT ?
            """, (notice_type, limit)).fetchall()

        return [dict(r) for r in rows]

    # ── persons (nouveau, unifié) ─────────────────────────────────────────────

    def upsert_person(self, person: Dict[str, Any]) -> None:
        with self._connect() as conn:
            conn.execute("""
                INSERT INTO persons (forename, surname, job, type, photo_path, source_id, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(source_id) DO UPDATE SET
                    forename=excluded.forename,
                    surname=excluded.surname,
                    job=excluded.job,
                    type=excluded.type,
                    photo_path=excluded.photo_path,
                    created_at=excluded.created_at
            """, (
                person["forename"],
                person.get("surname"),
                person.get("job"),
                person["type"],
                person["photo_path"],
                person.get("source_id"),
                datetime.now(timezone.utc).isoformat(),
            ))
            conn.commit()

    def clear_persons(self, person_type: str) -> None:
        with self._connect() as conn:
            conn.execute("DELETE FROM persons WHERE type = ?", (person_type,))
            conn.commit()

    def list_persons(self, person_type: str, limit: int = 120) -> List[Dict[str, Any]]:
        with self._connect() as conn:
            rows = conn.execute("""
                SELECT id, forename, surname, job, type, photo_path, source_id, created_at
                FROM persons
                WHERE type = ?
                ORDER BY created_at DESC
                LIMIT ?
            """, (person_type, limit)).fetchall()

        return [dict(r) for r in rows]

    def persons_stats(self) -> Dict[str, Any]:
        with self._connect() as conn:
            interpol_count = conn.execute(
                "SELECT COUNT(*) AS c FROM persons WHERE type = 'interpol'"
            ).fetchone()["c"]
            pro_count = conn.execute(
                "SELECT COUNT(*) AS c FROM persons WHERE type = 'pro'"
            ).fetchone()["c"]
            last_interpol = conn.execute(
                "SELECT MAX(created_at) AS m FROM persons WHERE type = 'interpol'"
            ).fetchone()["m"]
            last_pro = conn.execute(
                "SELECT MAX(created_at) AS m FROM persons WHERE type = 'pro'"
            ).fetchone()["m"]

        return {
            "interpol_count": interpol_count,
            "pro_count": pro_count,
            "total": interpol_count + pro_count,
            "last_interpol": last_interpol,
            "last_pro": last_pro,
        }
