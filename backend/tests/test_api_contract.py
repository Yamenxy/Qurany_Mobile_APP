"""API contract tests (category B) — response shapes and safe error payloads."""
from __future__ import annotations

import pytest

ANALYSIS_RESULT_KEYS = {
    "transcribed_text",
    "reference_text",
    "similarity_score",
    "total_words",
    "matched_words",
    "mistakes",
    "errors",
}


def test_health_contract(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "ok"
    assert isinstance(body["supported_surahs"], list)
    assert isinstance(body.get("supported_riwayat"), list)
    assert "models" in body


def test_list_surahs_contract(client):
    resp = client.get("/api/v1/surahs")
    assert resp.status_code == 200
    body = resp.json()
    assert set(body["supported_surahs"]) == {78, 2}
    assert set(body["supported_riwayat"]) == {"hafs", "bazzi"}


def test_surah_reference_contract_hafs(client):
    resp = client.get("/api/v1/surahs/78")
    assert resp.status_code == 200
    body = resp.json()
    required = {
        "surah_number",
        "name",
        "numberOfAyahs",
        "full_text",
        "normalized_text",
        "ayahs",
        "riwayah",
    }
    assert required.issubset(body.keys())
    assert body["numberOfAyahs"] == len(body["ayahs"])
    ayah = body["ayahs"][0]
    assert {"numberInSurah", "globalNumber", "text"}.issubset(ayah.keys())


def test_surah_reference_contract_bazzi(client):
    resp = client.get("/api/v1/surahs/2", params={"riwayah": "bazzi"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["riwayah"] == "bazzi"
    assert body["numberOfAyahs"] == 285


def test_analyze_text_response_contract(client):
    ref = client.get("/api/v1/surahs/78").json()["full_text"]
    resp = client.post(
        "/api/v1/analyze-text",
        json={"surah_number": 78, "transcribed_text": ref, "riwayah": "hafs"},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert ANALYSIS_RESULT_KEYS.issubset(body.keys())
    assert 0 <= body["similarity_score"] <= 100
    assert isinstance(body["errors"], list)
    if body["errors"]:
        err = body["errors"][0]
        assert set(err.keys()) == {"type", "expectedWord", "recitedWord", "wordIndex"}


def test_analyze_text_with_bazzi_on_surah_2(client):
    resp = client.get("/api/v1/surahs/2", params={"riwayah": "bazzi"})
    ayah1 = resp.json()["ayahs"][0]["text"]
    analyze = client.post(
        "/api/v1/analyze-text",
        json={"surah_number": 2, "transcribed_text": ayah1, "riwayah": "bazzi"},
    )
    assert analyze.status_code == 200
    assert analyze.json()["riwayah"] == "bazzi"


def test_error_response_is_json_detail_not_stack(client):
    resp = client.get("/api/v1/surahs/999")
    assert resp.status_code == 400
    body = resp.json()
    assert "detail" in body
    assert isinstance(body["detail"], (str, list))
    text = str(body)
    assert "Traceback" not in text


def test_invalid_riwayah_returns_400(client):
    resp = client.get("/api/v1/surahs/2", params={"riwayah": "invalid"})
    assert resp.status_code == 400
    assert "detail" in resp.json()


@pytest.mark.parametrize(
    "payload",
    [
        {"surah_number": 78, "transcribed_text": ""},
    ],
)
def test_analyze_text_rejects_empty_transcript(client, payload):
    resp = client.post("/api/v1/analyze-text", json=payload)
    assert resp.status_code == 422
