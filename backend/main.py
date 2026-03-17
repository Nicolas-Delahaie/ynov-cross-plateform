# backend/main.py
import logging
from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from app.api.routes.admin_dashboard import router as admin_dashboard_router
from app.api.routes.admin_import import router as admin_import_router

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)

# Créer les répertoires de photos au démarrage
Path("data/photos/interpol").mkdir(parents=True, exist_ok=True)
Path("data/photos/pro").mkdir(parents=True, exist_ok=True)

app = FastAPI(title="YNOV Admin")

app.mount("/photos", StaticFiles(directory="data/photos"), name="photos")

app.include_router(admin_dashboard_router)
app.include_router(admin_import_router)
