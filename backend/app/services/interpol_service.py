from __future__ import annotations

from typing import Any, Dict, Optional
import asyncio
import logging
from pathlib import Path
from urllib.parse import urlparse

from curl_cffi import requests

logger = logging.getLogger("interpol")


class InterpolService:
    BASE_URL = "https://ws-public.interpol.int"

    def __init__(self) -> None:
        self.headers = {"Accept": "application/json"}

    def _get_sync(self, url: str, params: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        r = requests.get(
            url,
            params=params or {},
            headers=self.headers,
            impersonate="chrome",
            timeout=30,
        )
        if not r.ok:
            logger.error("Interpol API HTTP %s — url=%s", r.status_code, url)
        r.raise_for_status()
        return r.json()

    async def _get(self, url: str, params: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        return await asyncio.to_thread(self._get_sync, url, params)

    def _abs(self, path: str) -> str:
        return f"{self.BASE_URL}{path}"

    async def list_red(self, page: int = 1, result_per_page: int = 50) -> Dict[str, Any]:
        return await self._get(self._abs("/notices/v1/red"), {"page": page, "resultPerPage": result_per_page})

    async def red_details(self, notice_id: str) -> Dict[str, Any]:
        return await self._get(self._abs(f"/notices/v1/red/{notice_id}"))

    async def red_images(self, notice_id: str) -> Dict[str, Any]:
        return await self._get(self._abs(f"/notices/v1/red/{notice_id}/images"))

    async def get_by_href(self, href: str) -> Dict[str, Any]:
        """
        Permet de suivre _links.next.href si Interpol renvoie une URL absolue.
        Si l’API renvoie un path relatif, on le convertit en URL absolue.
        """
        if href.startswith("http://") or href.startswith("https://"):
            return await self._get(href)

        # cas path relatif: "/notices/v1/red?page=2..."
        return await self._get(self._abs(href))

    @staticmethod
    def extract_notice_id_from_list_item(item: Dict[str, Any]) -> Optional[str]:
        href = (((item.get("_links") or {}).get("self") or {}).get("href") or "").rstrip("/")
        if not href:
            return None
        return href.split("/")[-1]  # ex: "2024-74464"

    @staticmethod
    def _build_display_name(details: Dict[str, Any]) -> str:
        name = details.get("name") or ""
        forename = details.get("forename") or ""
        full = (forename + " " + name).strip()
        return full if full else "Unknown"

    async def fetch_one_red_with_image(self, notice_id: str) -> Optional[Dict[str, Any]]:
        details = await self.red_details(notice_id)
        images = await self.red_images(notice_id)

        image_url = None
        items = (images.get("_embedded") or {}).get("images") or []
        if isinstance(items, list) and items:
            image_url = ((items[0].get("_links") or {}).get("self") or {}).get("href")

        if not image_url:
            return None  # photo obligatoire => skip

        forename = (details.get("forename") or "").strip() or "Unknown"
        surname = (details.get("name") or "").strip() or None

        return {
            "notice_id": notice_id,
            "notice_type": "red",
            "forename": forename,
            "surname": surname,
            "display_name": self._build_display_name(details),
            "nationalities": ",".join(details.get("nationalities", [])) if details.get("nationalities") else None,
            "date_of_birth": details.get("date_of_birth"),
            "image_url": image_url,
            "raw_json": {"details": details, "images": images},
        }

    def _download_image_sync(self, url: str, dest_path: str) -> bool:
        try:
            Path(dest_path).parent.mkdir(parents=True, exist_ok=True)
            r = requests.get(
                url,
                impersonate="chrome",
                timeout=20,
            )
            r.raise_for_status()
            if not r.content:
                logger.warning("download_image: empty body url=%s", url)
                return False
            Path(dest_path).write_bytes(r.content)
            return True
        except Exception as e:
            logger.warning("download_image FAILED url=%s err=%s", url, e)
            return False

    async def download_image(self, url: str, dest_path: str) -> bool:
        return await asyncio.to_thread(self._download_image_sync, url, dest_path)

    async def close(self) -> None:
        # No-op: on n’a pas de client persistant à fermer avec curl_cffi.requests.get
        return
