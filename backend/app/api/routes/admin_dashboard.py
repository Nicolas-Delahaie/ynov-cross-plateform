# backend/app/api/routes/admin_dashboard.py
from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from app.services.cache_service import CacheService

router = APIRouter()
templates = Jinja2Templates(directory="templates")

cache = CacheService("data/app.db")


@router.get("/admin", response_class=HTMLResponse)
def admin_dashboard(request: Request):
    stats = cache.stats()
    cards = cache.list_notices_with_image(notice_type="red", limit=120)
    persons_stats = cache.persons_stats()
    pro_cards = cache.list_persons("pro", limit=120)

    return templates.TemplateResponse(
        request,
        "dashboard.html",
        {
            "stats": stats,
            "cards": cards,
            "persons_stats": persons_stats,
            "pro_cards": pro_cards,
        },
    )
