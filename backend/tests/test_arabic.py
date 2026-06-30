"""Tests for Arabic normalization and similarity helpers."""
from __future__ import annotations

from src.utils.arabic import is_similar, normalize_arabic, normalize_words, word_similarity


def test_strips_diacritics():
    assert normalize_arabic("عَمَّ يَتَسَاءَلُونَ") == "عم يتسالون"


def test_normalizes_alef_variants():
    assert normalize_arabic("إِنَّ") == normalize_arabic("انَّ") == "ان"


def test_removes_tatweel_and_non_arabic():
    assert normalize_arabic("الـرحمن 123 .") == "الرحمن"


def test_normalize_words_drops_empty():
    assert normalize_words("  الَّذِي   هُمْ  ") == ["الذي", "هم"]


def test_identical_words_are_fully_similar():
    assert word_similarity("هم", "هم") == 1.0


def test_is_similar_threshold():
    # share most characters
    assert is_similar("يعلمون", "تعلمون", threshold=0.6)
    # completely different
    assert not is_similar("نبا", "عظيم", threshold=0.6)
