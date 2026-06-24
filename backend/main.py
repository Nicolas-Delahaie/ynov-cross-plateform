# backend/main.py
import logging
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.routes.admin_dashboard import router as admin_dashboard_router
from app.api.routes.admin_import import router as admin_import_router
from app.api.routes.persons import router as persons_router

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)

# Créer les répertoires de photos au démarrage
Path("data/photos/interpol").mkdir(parents=True, exist_ok=True)
Path("data/photos/pro").mkdir(parents=True, exist_ok=True)

app = FastAPI(title="YNOV Admin")

# CORS ouvert (dev) : permet au front Flutter (web/émulateur/téléphone) d'appeler l'API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/photos", StaticFiles(directory="data/photos"), name="photos")

app.include_router(admin_dashboard_router)
app.include_router(admin_import_router)
app.include_router(persons_router)
