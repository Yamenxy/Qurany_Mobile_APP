"""ASR / reference quality smoke tests (category D).

Heavy model inference tests are skipped when checkpoints are not present locally
(models are gitignored — download from Kaggle first).
"""
from __future__ import annotations

from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parents[1]
HAFS_MODEL = BACKEND / "models" / "qurany-whisper-base-al-baqarah" / "config.json"
BAZZI_MODEL = BACKEND / "models" / "qurany-whisper-base-al-baqarah-bazzi" / "config.json"
BAZZI_TEXT = BACKEND / "data" / "reference" / "Al-Baqarah_Bazzi.txt"


def test_bazzi_reference_file_present():
    assert BAZZI_TEXT.exists(), f"Missing canonical Bazzi text at {BAZZI_TEXT}"


def test_bazzi_reference_parses_285_ayahs():
    from src.utils.bazzi_text import bazzi_ayah_numbers, parse_bazzi_reference_txt

    ayah_map = parse_bazzi_reference_txt(BAZZI_TEXT)
    nums = bazzi_ayah_numbers(ayah_map)
    assert nums[0] == 1
    assert nums[-1] == 285
    assert len(nums) == 285


@pytest.mark.skipif(not HAFS_MODEL.exists(), reason="Hafs model not installed locally")
def test_hafs_model_checkpoint_layout():
    model_dir = HAFS_MODEL.parent
    assert (model_dir / "config.json").exists()
    assert (model_dir / "model.safetensors").exists() or (model_dir / "pytorch_model.bin").exists()


@pytest.mark.skipif(not BAZZI_MODEL.exists(), reason="Bazzi model not installed locally")
def test_bazzi_model_checkpoint_layout():
    model_dir = BAZZI_MODEL.parent
    assert (model_dir / "config.json").exists()
    assert (model_dir / "model.safetensors").exists() or (model_dir / "pytorch_model.bin").exists()


def test_analyze_text_perfect_bazzi_ayah_from_cache(client):
    """Lightweight quality gate: perfect transcript should score 100%."""
    ref_resp = client.get("/api/v1/surahs/2", params={"riwayah": "bazzi"})
    assert ref_resp.status_code == 200
    # Use a short ayah near the end if available (ayah 266 was used in manual testing).
    ayahs = {a["numberInSurah"]: a["text"] for a in ref_resp.json()["ayahs"]}
    ayah_num = 266 if 266 in ayahs else min(ayahs)
    resp = client.post(
        "/api/v1/analyze-text",
        json={
            "surah_number": 2,
            "transcribed_text": ayahs[ayah_num],
            "riwayah": "bazzi",
            "startAyah": ayah_num,
            "endAyah": ayah_num,
        },
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["similarity_score"] == 100.0
    assert body["mistakes"] == 0
