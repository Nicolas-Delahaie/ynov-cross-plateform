from __future__ import annotations

import asyncio
import logging
from pathlib import Path

from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from app.services.cache_service import CacheService
from app.services.interpol_service import InterpolService
from app.services.pro_service import ProService
from app.services.import_service import ImportService

logger = logging.getLogger("admin.import")

router = APIRouter()
templates = Jinja2Templates(directory="templates")

cache = CacheService("data/app.db")


@router.post("/admin/import", response_class=HTMLResponse)
async def admin_import_interpol(request: Request):
    interpol = InterpolService()
    pro = ProService()

    imported = 0
    error = None

    try:
        importer = ImportService(interpol=interpol, pro=pro, cache=cache)
        imported, error = await importer.import_interpol_red(
            max_pages=2,
            result_per_page=50,
            clear_before=True,
        )
    except asyncio.CancelledError:
        raise
    except Exception as e:
        error = f"Unexpected error: {type(e).__name__}"
    finally:
        await interpol.close()

    stats = cache.stats()
    cards = cache.list_notices_with_image(notice_type="red", limit=120)

    return templates.TemplateResponse(
        request,
        "_cards_grid.html",
        {
            "stats": stats,
            "cards": cards,
            "error": error,
            "imported": imported,
            "card_type": "interpol",
        },
    )


@router.post("/admin/import/pro", response_class=HTMLResponse)
async def admin_import_pro(request: Request):
    interpol = InterpolService()
    pro = ProService()

    imported = 0
    error = None

    try:
        importer = ImportService(interpol=interpol, pro=pro, cache=cache)
        imported, error = await importer.import_pro(count=100, clear_before=True)
    except asyncio.CancelledError:
        raise
    except Exception as e:
        error = f"Unexpected error: {type(e).__name__}"

    persons_stats = cache.persons_stats()
    pro_cards = cache.list_persons("pro", limit=120)

    return templates.TemplateResponse(
        request,
        "_cards_grid_pro.html",
        {
            "persons_stats": persons_stats,
            "cards": pro_cards,
            "error": error,
            "imported": imported,
        },
    )


def _delete_photos(subdir: str) -> int:
    """Supprime les fichiers .jpg dans data/photos/{subdir}/. Retourne le nombre supprimé."""
    photo_dir = Path(f"data/photos/{subdir}")
    count = 0
    if photo_dir.exists():
        for f in photo_dir.glob("*.jpg"):
            f.unlink(missing_ok=True)
            count += 1
    return count


@router.post("/admin/clear/pro", response_class=HTMLResponse)
async def admin_clear_pro(request: Request):
    deleted = _delete_photos("pro")
    cache.clear_persons("pro")
    logger.info("Clear PRO: %s fichiers supprimés", deleted)

    persons_stats = cache.persons_stats()
    return templates.TemplateResponse(
        request,
        "_cards_grid_pro.html",
        {
            "persons_stats": persons_stats,
            "cards": [],
            "error": None,
            "imported": 0,
        },
    )


@router.post("/admin/clear/interpol", response_class=HTMLResponse)
async def admin_clear_interpol(request: Request):
    deleted = _delete_photos("interpol")
    cache.clear_interpol("red")
    cache.clear_persons("interpol")
    logger.info("Clear Interpol: %s fichiers supprimés", deleted)

    stats = cache.stats()
    return templates.TemplateResponse(
        request,
        "_cards_grid.html",
        {
            "stats": stats,
            "cards": [],
            "error": None,
            "imported": 0,
            "card_type": "interpol",
        },
    )
