# backend/main.py
import logging
from fastapi import FastAPI

from app.api.routes.admin_dashboard import router as admin_dashboard_router
from app.api.routes.admin_import import router as admin_import_router

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)

app = FastAPI(title="YNOV Admin")
app.include_router(admin_dashboard_router)
app.include_router(admin_import_router)
