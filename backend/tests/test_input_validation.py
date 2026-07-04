"""Input validation tests (category B + backend side of H)."""
from __future__ import annotations


def test_analyze_text_rejects_unsupported_surah(client):
    resp = client.post(
        "/api/v1/analyze-text",
        json={"surah_number": 99, "transcribed_text": "test"},
    )
    assert resp.status_code == 400
    assert "detail" in resp.json()


def test_bazzi_analyze_rejected_for_surah_78(client):
    resp = client.post(
        "/api/v1/analyze-text",
        json={"surah_number": 78, "transcribed_text": "test", "riwayah": "bazzi"},
    )
    assert resp.status_code == 400
