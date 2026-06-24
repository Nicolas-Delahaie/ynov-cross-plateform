from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Query, Request

from app.services.cache_service import CacheService

router = APIRouter()

cache = CacheService("data/app.db")


@router.get("/api/persons")
async def list_persons(
    request: Request,
    type: Optional[str] = Query(
        default=None,
        description='Filtre : "pro" (LinkedIn) ou "interpol". Vide = mix des deux.',
    ),
    limit: int = Query(default=20, ge=1, le=200),
):
    """Liste de personnes pour le jeu « LinkedIn ou Interpol ? ».

    Chaque item est unifié :
    - `post` : le métier (PRO) ou le délit (Interpol) à afficher
    - `type` : la bonne réponse ("pro" | "interpol")
    - `photo_url` : URL absolue de la photo (basée sur l'hôte appelant)
    """
    type_filter = type if type in ("pro", "interpol") else None
    rows = cache.list_persons_for_game(person_type=type_filter, limit=limit)

    base = str(request.base_url).rstrip("/")  # ex: http://127.0.0.1:8000
    items = []
    for r in rows:
        name = r["forename"] + (f" {r['surname']}" if r.get("surname") else "")
        post = r["charge"] if r["type"] == "interpol" else r["job"]
        items.append({
            "id": r["id"],
            "type": r["type"],                 # réponse : "pro" | "interpol"
            "name": name,
            "post": post,                      # métier (PRO) ou délit (Interpol)
            "photo_url": f"{base}/photos/{r['photo_path']}",
        })

    return {"count": len(items), "persons": items}
