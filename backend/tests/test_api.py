"""API endpoint tests (no ASR model required)."""
from __future__ import annotations


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "ok"
    assert 78 in body["supported_surahs"]


def test_list_surahs(client):
    resp = client.get("/api/v1/surahs")
    assert resp.status_code == 200
    assert resp.json()["supported_surahs"] == [78]


def test_get_surah_reference(client):
    resp = client.get("/api/v1/surahs/78")
    assert resp.status_code == 200
    body = resp.json()
    assert body["surah_number"] == 78
    assert body["numberOfAyahs"] == 40
    assert len(body["ayahs"]) == 40
    assert body["full_text"]
    assert body["normalized_text"]


def test_unsupported_surah_rejected(client):
    resp = client.get("/api/v1/surahs/1")
    assert resp.status_code == 400


def test_analyze_text_perfect(client):
    ref = client.get("/api/v1/surahs/78").json()["full_text"]
    resp = client.post(
        "/api/v1/analyze-text",
        json={"surah_number": 78, "transcribed_text": ref},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["similarity_score"] == 100.0
    assert body["mistakes"] == 0
    assert body["errors"] == []
    # Wire format must use camelCase inside errors when present (checked below).


def test_analyze_text_with_errors_uses_camelcase(client):
    # Recite only the first two words -> the rest are omissions.
    resp = client.post(
        "/api/v1/analyze-text",
        json={"surah_number": 78, "transcribed_text": "عَمَّ يَتَسَاءَلُونَ"},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["mistakes"] > 0
    err = body["errors"][0]
    # Flutter's RecitationError.fromJson expects these exact keys.
    assert set(err.keys()) == {"type", "expectedWord", "recitedWord", "wordIndex"}


def test_analyze_text_unsupported_surah(client):
    resp = client.post(
        "/api/v1/analyze-text",
        json={"surah_number": 2, "transcribed_text": "بسم الله"},
    )
    assert resp.status_code == 400


def test_stream_alignment_websocket(client):
    ref = client.get("/api/v1/surahs/78").json()["full_text"]
    with client.websocket_connect("/api/v1/stream") as ws:
        ws.send_json({"surah_number": 78, "transcribed_text": "عَمَّ يَتَسَاءَلُونَ"})
        partial = ws.receive_json()
        assert partial["mistakes"] > 0  # only part recited

        ws.send_json({"surah_number": 78, "transcribed_text": ref})
        full = ws.receive_json()
        assert full["similarity_score"] == 100.0

        ws.send_json({"type": "end"})
