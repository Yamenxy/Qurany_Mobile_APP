"""Loads and caches canonical surah reference text (MVP: Surah Al-Naba / 78).

Primary source is the locally seeded JSON in ``data/surah_naba/``. If that is
missing and the fallback is enabled, the text is fetched once from the
AlQuran Cloud API (the same source the Flutter app uses) and cached to disk.
"""
from __future__ import annotations

import json
import logging
from functools import lru_cache

from ..config import settings
from ..utils.arabic import normalize_arabic

logger = logging.getLogger(__name__)

_SEED_FILENAME = "surah_naba.json"


class SurahReference:
    """In-memory representation of a surah's reference text."""

    def __init__(self, surah_number: int, name: str, ayahs: list[dict]):
        self.surah_number = surah_number
        self.name = name
        self.ayahs = ayahs  # [{numberInSurah, globalNumber, text}]

    @property
    def full_text(self) -> str:
        """All ayahs joined into a single Uthmani reference string."""
        return " ".join(a["text"] for a in self.ayahs).strip()

    @property
    def normalized_text(self) -> str:
        return normalize_arabic(self.full_text)

    def to_dict(self) -> dict:
        return {
            "surah_number": self.surah_number,
            "name": self.name,
            "numberOfAyahs": len(self.ayahs),
            "ayahs": self.ayahs,
            "full_text": self.full_text,
            "normalized_text": self.normalized_text,
        }


def _seed_path(surah_number: int):
    # MVP only seeds Al-Naba; the path is fixed for chapter 78.
    return settings.surah_naba_dir / _SEED_FILENAME


def _load_from_disk(surah_number: int) -> SurahReference | None:
    path = _seed_path(surah_number)
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return SurahReference(
            surah_number=data.get("surah_number", surah_number),
            name=data.get("name", ""),
            ayahs=data["ayahs"],
        )
    except (json.JSONDecodeError, KeyError) as exc:
        logger.warning("Failed to parse seed file %s: %s", path, exc)
        return None


def _fetch_from_api(surah_number: int) -> SurahReference | None:
    if not settings.reference_fetch_fallback:
        return None
    import httpx

    url = f"{settings.alquran_api_base}/surah/{surah_number}/ar.uthmani"
    try:
        resp = httpx.get(url, timeout=30.0)
        resp.raise_for_status()
        payload = resp.json()["data"]
    except (httpx.HTTPError, KeyError) as exc:
        logger.error("Reference fetch failed for surah %s: %s", surah_number, exc)
        return None

    ayahs = [
        {
            "numberInSurah": a["numberInSurah"],
            "globalNumber": a["number"],
            "text": a["text"],
        }
        for a in payload["ayahs"]
    ]
    ref = SurahReference(surah_number, payload.get("name", ""), ayahs)

    # Cache to disk for next time.
    try:
        path = _seed_path(surah_number)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(
                {
                    "surah_number": ref.surah_number,
                    "name": ref.name,
                    "numberOfAyahs": len(ayahs),
                    "ayahs": ayahs,
                },
                ensure_ascii=False,
                indent=2,
            ),
            encoding="utf-8",
        )
    except OSError as exc:  # caching is best-effort
        logger.warning("Could not cache reference for surah %s: %s", surah_number, exc)

    return ref


@lru_cache
def get_surah_reference(surah_number: int) -> SurahReference:
    """Return the reference text for a surah, loading/caching as needed."""
    if surah_number not in settings.supported_surahs:
        raise ValueError(
            f"Surah {surah_number} is not supported in this MVP "
            f"(supported: {settings.supported_surahs})."
        )

    ref = _load_from_disk(surah_number) or _fetch_from_api(surah_number)
    if ref is None:
        raise RuntimeError(
            f"Reference text for surah {surah_number} is unavailable "
            "(no local seed and API fallback failed)."
        )
    return ref
