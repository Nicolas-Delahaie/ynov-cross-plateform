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
from app.services.progress import get_progress, interpol_progress, pro_progress

logger = logging.getLogger("admin.import")

router = APIRouter()
templates = Jinja2Templates(directory="templates")

cache = CacheService("data/app.db")


# ── Helpers progression ──────────────────────────────────────────────────────

def _progress_response(request: Request, kind: str) -> HTMLResponse:
    """Rend la barre de progression auto-rafraîchissante (polling HTMX)."""
    return templates.TemplateResponse(
        request,
        "_progress.html",
        {
            "progress": get_progress(kind),
            "kind": kind,
            "target_block": "proCardsBlock" if kind == "pro" else "cardsBlock",
            "bar_color": "success" if kind == "pro" else "danger",
        },
    )


def _interpol_grid_response(request: Request, error, imported) -> HTMLResponse:
    return templates.TemplateResponse(
        request,
        "_cards_grid.html",
        {
            "stats": cache.stats(),
            "cards": cache.list_notices_with_image(notice_type="red", limit=120),
            "error": error,
            "imported": imported,
            "card_type": "interpol",
        },
    )


def _pro_grid_response(request: Request, error, imported) -> HTMLResponse:
    return templates.TemplateResponse(
        request,
        "_cards_grid_pro.html",
        {
            "persons_stats": cache.persons_stats(),
            "cards": cache.list_persons("pro", limit=120),
            "error": error,
            "imported": imported,
        },
    )


# ── Tâches de fond ───────────────────────────────────────────────────────────

async def _run_interpol_import() -> None:
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
            progress=interpol_progress,
        )
    except Exception as e:
        error = f"Unexpected error: {type(e).__name__}"
        logger.exception("Interpol import crashed")
    finally:
        await interpol.close()
        interpol_progress.update(imported=imported)
        interpol_progress.finish(error=error)


async def _run_pro_import() -> None:
    interpol = InterpolService()
    pro = ProService()
    imported = 0
    error = None
    try:
        importer = ImportService(interpol=interpol, pro=pro, cache=cache)
        imported, error = await importer.import_pro(
            count=100,
            clear_before=True,
            progress=pro_progress,
        )
    except Exception as e:
        error = f"Unexpected error: {type(e).__name__}"
        logger.exception("PRO import crashed")
    finally:
        await interpol.close()
        pro_progress.update(imported=imported)
        pro_progress.finish(error=error)


# ── Routes import (non bloquantes) ───────────────────────────────────────────

@router.post("/admin/import", response_class=HTMLResponse)
async def admin_import_interpol(request: Request):
    if not interpol_progress.running:
        interpol_progress.start(total=100, phase="Démarrage…")
        asyncio.create_task(_run_interpol_import())
    return _progress_response(request, "interpol")


@router.post("/admin/import/pro", response_class=HTMLResponse)
async def admin_import_pro(request: Request):
    if not pro_progress.running:
        pro_progress.start(total=100, phase="Démarrage…")
        asyncio.create_task(_run_pro_import())
    return _progress_response(request, "pro")


@router.get("/admin/progress/{kind}", response_class=HTMLResponse)
async def admin_progress(request: Request, kind: str):
    prog = get_progress(kind)
    if prog.running:
        return _progress_response(request, kind)
    # Import terminé → on renvoie la grille finale (le polling s'arrête).
    if kind == "pro":
        return _pro_grid_response(request, prog.error, prog.imported)
    return _interpol_grid_response(request, prog.error, prog.imported)


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
