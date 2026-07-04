"""Unit tests for riwayah validation (category A — no HTTP, no ASR model)."""
from __future__ import annotations

import pytest

from src.services.riwayah import (
    BAZZI_SURAH_NUMBER,
    DEFAULT_RIWAYAH,
    SUPPORTED_RIWAYAT,
    normalize_riwayah,
    validate_riwayah_for_surah,
)


def test_normalize_defaults_to_hafs():
    assert normalize_riwayah(None) == DEFAULT_RIWAYAH
    assert normalize_riwayah("") == "hafs"
    assert normalize_riwayah("  HAFS ") == "hafs"


def test_normalize_accepts_bazzi():
    assert normalize_riwayah("bazzi") == "bazzi"


def test_normalize_rejects_unknown_riwayah():
    with pytest.raises(ValueError, match="Unsupported riwayah"):
        normalize_riwayah("warsh")


def test_bazzi_only_allowed_on_surah_2():
    validate_riwayah_for_surah("bazzi", BAZZI_SURAH_NUMBER)


def test_bazzi_rejected_on_other_surahs():
    with pytest.raises(ValueError, match="only supported for surah 2"):
        validate_riwayah_for_surah("bazzi", 78)


def test_supported_riwayat_tuple():
    assert set(SUPPORTED_RIWAYAT) == {"hafs", "bazzi"}
