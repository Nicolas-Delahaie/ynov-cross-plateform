from __future__ import annotations

from typing import Any, Dict, Optional, Tuple, List
import asyncio
import logging
import time
from pathlib import Path
from uuid import uuid4

from app.services.interpol_service import InterpolService
from app.services.pro_service import ProService
from app.services.cache_service import CacheService


logger_interpol = logging.getLogger("import.interpol")
logger_pro = logging.getLogger("import.pro")


class ImportService:
    def __init__(self, interpol: InterpolService, pro: ProService, cache: CacheService) -> None:
        self.interpol = interpol
        self.pro = pro
        self.cache = cache

    @staticmethod
    def _clear_photo_dir(subdir: str) -> None:
        """Supprime tous les .jpg dans data/photos/{subdir}/."""
        photo_dir = Path(f"data/photos/{subdir}")
        if photo_dir.exists():
            for f in photo_dir.glob("*.jpg"):
                f.unlink(missing_ok=True)

    @staticmethod
    def _extract_notices_list(payload: Dict[str, Any]) -> List[Dict[str, Any]]:
        embedded = payload.get("_embedded") or {}
        notices = embedded.get("notices") or []
        return notices if isinstance(notices, list) else []

    @staticmethod
    def _extract_next_link(payload: Dict[str, Any]) -> Optional[str]:
        links = payload.get("_links") or {}
        return ((links.get("next") or {}).get("href")) or None

    async def import_interpol_red(
        self,
        *,
        max_pages: int = 1,
        result_per_page: int = 50,
        clear_before: bool = False,
    ) -> Tuple[int, Optional[str]]:
        if clear_before:
            self.cache.clear_interpol("red")
            self.cache.clear_persons("interpol")
            self._clear_photo_dir("interpol")

        t0 = time.perf_counter()

        imported = 0
        processed = 0
        skipped_no_image = 0
        page = 1
        next_href: Optional[str] = None
        total: Optional[int] = None

        logger_interpol.info(
            "START import red | max_pages=%s per_page=%s clear_before=%s",
            max_pages, result_per_page, clear_before,
        )

        try:
            while page <= max_pages:
                logger_interpol.info("Fetching page %s/%s ...", page, max_pages)

                try:
                    payload = await (
                        self.interpol.get_by_href(next_href)
                        if next_href
                        else self.interpol.list_red(page=page, result_per_page=result_per_page)
                    )
                except asyncio.CancelledError:
                    raise
                except Exception as e:
                    logger_interpol.exception("Interpol list error page=%s", page)
                    return imported, f"Interpol list error: {type(e).__name__}: {e}"

                if total is None:
                    maybe_total = payload.get("total")
                    if isinstance(maybe_total, int):
                        total = maybe_total
                        logger_interpol.info("Interpol total (global) = %s", total)

                notices = self._extract_notices_list(payload)
                if not notices:
                    logger_interpol.info("No notices returned on page %s -> stop", page)
                    break

                last_heartbeat = time.perf_counter()

                for item in notices:
                    if not isinstance(item, dict):
                        continue

                    notice_id = self.interpol.extract_notice_id_from_list_item(item)
                    if not notice_id:
                        continue

                    processed += 1

                    if processed <= 3 or processed % 5 == 0:
                        logger_interpol.info(
                            "Processing notice %s (processed=%s, imported=%s)",
                            notice_id, processed, imported,
                        )

                    try:
                        async with asyncio.timeout(40):
                            row = await self.interpol.fetch_one_red_with_image(notice_id)
                    except asyncio.TimeoutError:
                        logger_interpol.warning("Timeout notice %s -> skip", notice_id)
                        continue
                    except asyncio.CancelledError:
                        raise
                    except Exception:
                        continue

                    if not row:
                        skipped_no_image += 1
                    else:
                        # Extraire la charge depuis raw_json avant upsert
                        warrants = (
                            ((row.get("raw_json") or {}).get("details") or {})
                            .get("arrest_warrants") or []
                        )
                        row["charge"] = warrants[0].get("charge") if warrants else None

                        self.cache.upsert_notice(row)

                        # Téléchargement photo local
                        photo_rel = f"interpol/{notice_id}.jpg"
                        photo_ok = await self.interpol.download_image(
                            row["image_url"],
                            f"data/photos/{photo_rel}",
                        )

                        if photo_ok:
                            self.cache.upsert_person({
                                "forename": row["forename"],
                                "surname": row.get("surname"),
                                "job": None,
                                "type": "interpol",
                                "photo_path": photo_rel,
                                "source_id": notice_id,
                            })
                        else:
                            logger_interpol.warning("Photo download failed for %s", notice_id)

                        imported += 1

                    now = time.perf_counter()
                    if now - last_heartbeat >= 5:
                        logger_interpol.info(
                            "Heartbeat: processed=%s imported=%s skipped_no_image=%s elapsed=%.1fs",
                            processed, imported, skipped_no_image, now - t0,
                        )
                        last_heartbeat = now

                    if processed % 10 == 0:
                        if total is not None:
                            logger_interpol.info(
                                "Progress: processed=%s imported=%s skipped_no_image=%s | total=%s",
                                processed, imported, skipped_no_image, total,
                            )
                        else:
                            logger_interpol.info(
                                "Progress: processed=%s imported=%s skipped_no_image=%s",
                                processed, imported, skipped_no_image,
                            )

                next_href = self._extract_next_link(payload)
                if not next_href:
                    logger_interpol.info("No next link -> stop")
                    break

                page += 1

        except asyncio.CancelledError:
            logger_interpol.info("Import cancelled by client disconnect / cancellation.")
            raise

        dt = time.perf_counter() - t0
        logger_interpol.info(
            "DONE import red | imported=%s processed=%s skipped_no_image=%s duration=%.2fs",
            imported, processed, skipped_no_image, dt,
        )

        return imported, None

    async def import_pro(
        self,
        *,
        count: int = 100,
        clear_before: bool = False,
    ) -> Tuple[int, Optional[str]]:
        if clear_before:
            self.cache.clear_persons("pro")
            self._clear_photo_dir("pro")

        t0 = time.perf_counter()
        imported = 0
        skipped = 0
        last_heartbeat = t0

        logger_pro.info("START import pro | count=%s clear_before=%s", count, clear_before)

        # Pré-charge le cache d'URLs Lexica (Arab faces — 70% male / 30% female 40+)
        # Si Lexica est indisponible, ProService bascule automatiquement sur randomuser.me (nat=tr)
        n_urls = await self.pro.build_url_cache()
        logger_pro.info(
            "Lexica URL cache: %s total (%s male / %s female) | fallback=%s",
            n_urls, len(self.pro._male_urls), len(self.pro._female_urls), self.pro._use_fallback,
        )

        try:
            for i in range(count):
                profile = self.pro.generate_profile()
                uid = str(uuid4())
                photo_rel = f"pro/{uid}.jpg"

                try:
                    async with asyncio.timeout(25):
                        photo_ok = await self.pro.download_photo(f"data/photos/{photo_rel}")
                except asyncio.TimeoutError:
                    logger_pro.warning("Timeout photo PRO #%s -> skip", i + 1)
                    skipped += 1
                    continue
                except asyncio.CancelledError:
                    raise
                except Exception:
                    skipped += 1
                    continue

                if not photo_ok:
                    logger_pro.warning("Photo download failed PRO #%s -> skip", i + 1)
                    skipped += 1
                    continue

                self.cache.upsert_person({
                    "forename": profile["forename"],
                    "surname": profile["surname"],
                    "job": profile["job"],
                    "type": "pro",
                    "photo_path": photo_rel,
                    "source_id": uid,
                })
                imported += 1

                now = time.perf_counter()
                if now - last_heartbeat >= 5:
                    logger_pro.info(
                        "Heartbeat: imported=%s skipped=%s elapsed=%.1fs",
                        imported, skipped, now - t0,
                    )
                    last_heartbeat = now

                if (i + 1) % 10 == 0:
                    logger_pro.info(
                        "Progress: %s/%s imported=%s skipped=%s",
                        i + 1, count, imported, skipped,
                    )

        except asyncio.CancelledError:
            logger_pro.info("PRO import cancelled.")
            raise

        dt = time.perf_counter() - t0
        logger_pro.info(
            "DONE import pro | imported=%s skipped=%s duration=%.2fs",
            imported, skipped, dt,
        )

        return imported, None
