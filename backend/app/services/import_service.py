from __future__ import annotations

from typing import Any, Dict, Optional, Tuple, List
import asyncio
import logging
import time

from app.services.interpol_service import InterpolService
from app.services.cache_service import CacheService
import time



logger = logging.getLogger("import.interpol")


class ImportService:
    def __init__(self, interpol: InterpolService, cache: CacheService) -> None:
        self.interpol = interpol
        self.cache = cache

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

        t0 = time.perf_counter()

        imported = 0
        processed = 0
        skipped_no_image = 0
        page = 1
        next_href: Optional[str] = None
        total: Optional[int] = None

        logger.info("START import red | max_pages=%s per_page=%s clear_before=%s", max_pages, result_per_page, clear_before)

        try:
            while page <= max_pages:
                logger.info("Fetching page %s/%s ...", page, max_pages)

                try:
                    payload = await (self.interpol.get_by_href(next_href) if next_href else self.interpol.list_red(page=page, result_per_page=result_per_page))
                except asyncio.CancelledError:
                    raise
                except Exception as e:
                    logger.exception("Interpol list error page=%s", page)
                    return imported, f"Interpol list error: {type(e).__name__}"

                if total is None:
                    maybe_total = payload.get("total")
                    if isinstance(maybe_total, int):
                        total = maybe_total
                        logger.info("Interpol total (global) = %s", total)

                notices = self._extract_notices_list(payload)
                if not notices:
                    logger.info("No notices returned on page %s -> stop", page)
                    break

                t0 = time.perf_counter()
                last_heartbeat = t0

                for item in notices:
                    if not isinstance(item, dict):
                        continue

                    notice_id = self.interpol.extract_notice_id_from_list_item(item)
                    if not notice_id:
                        continue

                    processed += 1

                    # ✅ log rapide au début + toutes les 5
                    if processed <= 3 or processed % 5 == 0:
                        logger.info("Processing notice %s (processed=%s, imported=%s)", notice_id, processed, imported)

                    try:
                        # ✅ timeout global par notice (details+images)
                        async with asyncio.timeout(40):
                            row = await self.interpol.fetch_one_red_with_image(notice_id)

                    except asyncio.TimeoutError:
                        logger.warning("Timeout notice %s -> skip", notice_id)
                        continue

                    except asyncio.CancelledError:
                        raise

                    except Exception:
                        # si tu veux investiguer : logger.exception(...)
                        continue

                    if not row:
                        skipped_no_image += 1
                    else:
                        self.cache.upsert_notice(row)
                        imported += 1

                    # ✅ heartbeat temps (si tu veux un log même quand c’est lent)
                    now = time.perf_counter()
                    if now - last_heartbeat >= 5:
                        logger.info(
                            "Heartbeat: processed=%s imported=%s skipped_no_image=%s elapsed=%.1fs",
                            processed, imported, skipped_no_image, now - t0
                        )
                        last_heartbeat = now


                    # Log de progression toutes les 10 notices (évite spam)
                    if processed % 10 == 0:
                        if total is not None:
                            logger.info(
                                "Progress: processed=%s imported=%s skipped_no_image=%s | total=%s",
                                processed, imported, skipped_no_image, total
                            )
                        else:
                            logger.info(
                                "Progress: processed=%s imported=%s skipped_no_image=%s",
                                processed, imported, skipped_no_image
                            )

                next_href = self._extract_next_link(payload)
                if not next_href:
                    logger.info("No next link -> stop")
                    break

                page += 1

        except asyncio.CancelledError:
            logger.info("Import cancelled by client disconnect / cancellation.")
            raise

        dt = time.perf_counter() - t0
        logger.info(
            "DONE import red | imported=%s processed=%s skipped_no_image=%s duration=%.2fs",
            imported, processed, skipped_no_image, dt
        )

        return imported, None
