from __future__ import annotations

import asyncio
from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from app.services.cache_service import CacheService
from app.services.interpol_service import InterpolService
from app.services.import_service import ImportService
import logging
logger = logging.getLogger("admin.import")

logger.info("Admin clicked Import Interpol")

router = APIRouter()
templates = Jinja2Templates(directory="templates")

cache = CacheService("data/app.db")


@router.post("/admin/import", response_class=HTMLResponse)
async def admin_import(request: Request):
    interpol = InterpolService()

    imported = 0
    error = None

    try:
        importer = ImportService(interpol=interpol, cache=cache)

        # ⚠️ adapte les paramètres à TA nouvelle signature.
        # Si tu as gardé clear_before, garde-le; sinon, retire-le.
        imported, error = await importer.import_interpol_red(
            max_pages=2,
            result_per_page=50,
            clear_before=True,  # retire si tu l’as supprimé dans ImportService
        )

    except asyncio.CancelledError:
        # recommandé: ne pas avaler CancelledError
        raise

    except Exception as e:
        # On renvoie quand même la page avec un message d’erreur (pas de 500)
        error = f"Unexpected error: {type(e).__name__}"

    finally:
        # OK si close() existe (no-op) ; sinon supprime cette ligne
        await interpol.close()

    stats = cache.stats()
    cards = cache.list_notices_with_image(notice_type="red", limit=120)

    return templates.TemplateResponse(
        "_cards_grid.html",
        {"request": request, "stats": stats, "cards": cards, "error": error, "imported": imported},
    )
