"""Tests for word alignment and error classification."""
from __future__ import annotations

from src.services.alignment_service import analyze_alignment

REF = "عَمَّ يَتَسَاءَلُونَ عَنِ النَّبَإِ الْعَظِيمِ"


def test_perfect_match_scores_100():
    result = analyze_alignment(REF, REF)
    assert result["similarity_score"] == 100.0
    assert result["mistakes"] == 0
    assert result["errors"] == []
    assert result["matched_words"] == result["total_words"] == 5


def test_omission_detected():
    # Drop the last word "العظيم".
    recited = "عَمَّ يَتَسَاءَلُونَ عَنِ النَّبَإِ"
    result = analyze_alignment(REF, recited)
    types = [e["type"] for e in result["errors"]]
    assert "omission" in types
    assert result["matched_words"] == 4
    assert result["mistakes"] == 1


def test_addition_detected():
    recited = REF + " زِيَادَةٌ"
    result = analyze_alignment(REF, recited)
    additions = [e for e in result["errors"] if e["type"] == "addition"]
    assert len(additions) == 1
    # Additions do not reduce matched reference words.
    assert result["matched_words"] == 5
    assert result["similarity_score"] == 100.0


def test_substitution_detected():
    recited = "عَمَّ يَتَسَاءَلُونَ عَنِ الْكِتَابِ الْعَظِيمِ"
    result = analyze_alignment(REF, recited)
    subs = [e for e in result["errors"] if e["type"] == "substitution"]
    assert len(subs) == 1
    assert subs[0]["wordIndex"] == 3


def test_empty_recitation_all_omissions():
    result = analyze_alignment(REF, "")
    assert result["similarity_score"] == 0.0
    assert result["matched_words"] == 0
    assert all(e["type"] == "omission" for e in result["errors"])
    assert len(result["errors"]) == 5


def test_sequence_error_detected():
    # Swap "عن" and "النبإ".
    recited = "عَمَّ يَتَسَاءَلُونَ النَّبَإِ عَنِ الْعَظِيمِ"
    result = analyze_alignment(REF, recited)
    types = [e["type"] for e in result["errors"]]
    assert "sequence" in types
