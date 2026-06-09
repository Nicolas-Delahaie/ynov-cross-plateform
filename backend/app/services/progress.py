from __future__ import annotations

from typing import Optional


class Progress:
    """État partagé d'un import en cours, lu par le polling HTMX."""

    def __init__(self) -> None:
        self.running: bool = False
        self.done: bool = False
        self.phase: str = ""
        self.current: int = 0
        self.total: int = 0
        self.imported: int = 0
        self.skipped: int = 0
        self.error: Optional[str] = None

    def start(self, total: int, phase: str = "Démarrage…") -> None:
        self.running = True
        self.done = False
        self.phase = phase
        self.current = 0
        self.total = total
        self.imported = 0
        self.skipped = 0
        self.error = None

    def update(
        self,
        *,
        current: Optional[int] = None,
        total: Optional[int] = None,
        imported: Optional[int] = None,
        skipped: Optional[int] = None,
        phase: Optional[str] = None,
    ) -> None:
        if current is not None:
            self.current = current
        if total is not None:
            self.total = total
        if imported is not None:
            self.imported = imported
        if skipped is not None:
            self.skipped = skipped
        if phase is not None:
            self.phase = phase

    def finish(self, error: Optional[str] = None) -> None:
        self.running = False
        self.done = True
        self.error = error
        if error is None:
            self.current = self.total
            self.phase = "Terminé"
        else:
            self.phase = "Erreur"

    @property
    def pct(self) -> int:
        if self.total <= 0:
            return 0
        return min(100, round(self.current / self.total * 100))


# Trackers globaux (un worker uvicorn → état partagé en mémoire)
interpol_progress = Progress()
pro_progress = Progress()


def get_progress(kind: str) -> Progress:
    return pro_progress if kind == "pro" else interpol_progress
