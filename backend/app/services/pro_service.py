from __future__ import annotations

import asyncio
import logging
import random
from pathlib import Path
from urllib.parse import quote as urlquote

from curl_cffi import requests

logger = logging.getLogger("pro")

# ── Datasets embarqués ────────────────────────────────────────────────────────

_FORENAMES = [
    "Alice", "Antoine", "Camille", "Charlotte", "Clara", "Clément", "Dylan",
    "Emma", "Ethan", "Eva", "Fatima", "François", "Gabriel", "Hugo", "Inès",
    "Jade", "Julien", "Laura", "Layla", "Léa", "Léo", "Louis", "Lucas",
    "Lucie", "Manon", "Marine", "Mathieu", "Mathis", "Maxime", "Mohamed",
    "Nathan", "Nicolas", "Noah", "Océane", "Olivia", "Paul", "Pierre",
    "Romain", "Sacha", "Sarah", "Sofia", "Sophie", "Thomas", "Tom",
    "Valentine", "Victor", "Yasmine", "Zachary", "Amelia", "Ethan",
    "Liam", "Mia", "James", "Yasmin", "Omar", "Lena", "Felix", "Nina",
    "Axel", "Elise", "Quentin",
]

_SURNAMES = [
    "Martin", "Bernard", "Dubois", "Thomas", "Robert", "Richard", "Petit",
    "Durand", "Leroy", "Moreau", "Simon", "Laurent", "Lefebvre", "Michel",
    "Garcia", "David", "Bertrand", "Roux", "Vincent", "Fournier", "Morel",
    "Girard", "André", "Lefevre", "Mercier", "Dupont", "Lambert", "Bonnet",
    "François", "Martinez", "Leblanc", "Garnier", "Faure", "Rousseau",
    "Blanc", "Guerin", "Muller", "Henry", "Roussel", "Nicolas",
]

_JOBS = [
    # Tech & Data
    "Software Engineer", "Data Scientist", "Product Manager", "DevOps Engineer",
    "UX Designer", "Cybersecurity Analyst", "Machine Learning Engineer",
    "Frontend Developer", "Backend Developer", "Cloud Architect",
    # Finance & Business
    "Financial Analyst", "Investment Banker", "Tax Consultant", "Auditor",
    "Risk Manager", "Chief Financial Officer", "Business Analyst",
    "Management Consultant", "Project Manager", "Supply Chain Manager",
    # Health
    "General Practitioner", "Cardiologist", "Pharmacist", "Nurse",
    "Radiologist", "Psychiatrist", "Physiotherapist", "Dentist",
    # Law & Public sector
    "Lawyer", "Judge", "Notary", "Legal Counsel", "Public Prosecutor",
    "Policy Analyst", "Diplomat", "Urban Planner",
    # Education & Research
    "University Professor", "Research Scientist", "Economist",
    "Sociologist", "Historian", "Journalist", "Teacher",
    # Engineering & Industry
    "Civil Engineer", "Mechanical Engineer", "Electrical Engineer",
    "Chemical Engineer", "Quality Manager", "Industrial Designer",
    # Creative
    "Architect", "Graphic Designer", "Art Director", "Photographer",
    "Communications Manager", "Marketing Director",
]

# Requêtes Lexica — hommes arabes / moyen-orientaux (pool ~70%)
_ARAB_QUERIES_MALE = [
    "arab man professional headshot realistic portrait",
    "middle eastern man professional headshot studio photo",
    "moroccan man business portrait photo",
    "egyptian man professional portrait photo",
    "north african man businessman portrait realistic",
    "arabic man beard professional headshot",
    "lebanese man professional portrait photo",
]

# Requêtes Lexica — femmes arabes / moyen-orientales 40+ (pool ~30%)
_ARAB_QUERIES_FEMALE = [
    "arab woman 45 years old professional portrait realistic",
    "middle eastern mature woman professional business portrait",
    "north african woman 50 years old professional headshot",
]


# ── ProService ────────────────────────────────────────────────────────────────

class ProService:
    LEXICA_API = "https://lexica.art/api/v1/search"
    RANDOMUSER_API = "https://randomuser.me/api/"

    def __init__(self) -> None:
        self._male_urls: list[str] = []
        self._female_urls: list[str] = []
        self._use_fallback: bool = False

    def generate_profile(self) -> dict:
        return {
            "forename": random.choice(_FORENAMES),
            "surname": random.choice(_SURNAMES),
            "job": random.choice(_JOBS),
        }

    def _fetch_urls_for_queries(self, queries: list[str]) -> list[str]:
        urls: list[str] = []
        for q in queries:
            try:
                r = requests.get(
                    f"{self.LEXICA_API}?q={urlquote(q)}",
                    impersonate="chrome",
                    headers={"Accept": "application/json", "Referer": "https://lexica.art/"},
                    timeout=20,
                )
                r.raise_for_status()
                data = r.json()
                images = data.get("images", [])
                logger.info("Lexica q=%r -> %s images", q, len(images))
                for img in images:
                    if not img.get("nsfw") and img.get("src"):
                        urls.append(img["src"])
            except Exception as e:
                logger.warning("Lexica FAILED q=%r err=%s", q, e)
                continue
        return urls

    def _build_url_cache_sync(self) -> None:
        self._male_urls = self._fetch_urls_for_queries(_ARAB_QUERIES_MALE)
        self._female_urls = self._fetch_urls_for_queries(_ARAB_QUERIES_FEMALE)
        random.shuffle(self._male_urls)
        random.shuffle(self._female_urls)
        total = len(self._male_urls) + len(self._female_urls)
        if total == 0:
            logger.warning("Lexica cache vide — bascule sur randomuser.me (nat=tr)")
            self._use_fallback = True
        else:
            self._use_fallback = False
            logger.info("Lexica cache: %s male / %s female", len(self._male_urls), len(self._female_urls))

    async def build_url_cache(self) -> int:
        await asyncio.to_thread(self._build_url_cache_sync)
        return len(self._male_urls) + len(self._female_urls)

    # ── Fallback : randomuser.me turc (apparence méditerranéenne / moyen-orientale) ──

    def _download_photo_fallback_sync(self, dest_path: str, gender: str) -> bool:
        try:
            r = requests.get(
                f"{self.RANDOMUSER_API}?gender={gender}&nat=tr&inc=picture&noinfo",
                impersonate="chrome",
                timeout=20,
            )
            r.raise_for_status()
            photo_url = r.json()["results"][0]["picture"]["large"]
            img = requests.get(photo_url, impersonate="chrome", timeout=20)
            img.raise_for_status()
            if not img.content:
                return False
            Path(dest_path).parent.mkdir(parents=True, exist_ok=True)
            Path(dest_path).write_bytes(img.content)
            return True
        except Exception as e:
            logger.warning("Fallback download FAILED dest=%s err=%s", dest_path, e)
            return False

    # ── Download principal ────────────────────────────────────────────────────

    def _download_photo_sync(self, dest_path: str) -> bool:
        # 70% homme, 30% femme 40+
        is_male = random.random() < 0.70

        if self._use_fallback:
            gender = "male" if is_male else "female"
            return self._download_photo_fallback_sync(dest_path, gender)

        pool = self._male_urls if is_male else self._female_urls
        if not pool:
            pool = self._male_urls or self._female_urls
        if not pool:
            return False

        try:
            Path(dest_path).parent.mkdir(parents=True, exist_ok=True)
            url = random.choice(pool)
            r = requests.get(url, impersonate="chrome", timeout=30)
            r.raise_for_status()
            if not r.content:
                return False
            Path(dest_path).write_bytes(r.content)
            return True
        except Exception as e:
            logger.warning("Lexica download FAILED url=%s err=%s", url, e)
            return False

    async def download_photo(self, dest_path: str) -> bool:
        return await asyncio.to_thread(self._download_photo_sync, dest_path)
