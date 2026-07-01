"""Tests for thread-safe ASR model loading."""
from __future__ import annotations

import threading
from unittest.mock import MagicMock, patch

from src.services.asr_service import ASRService


def test_concurrent_load_instantiates_model_once():
    service = ASRService()
    mock_whisper = MagicMock()
    barrier = threading.Barrier(8)

    def load_model() -> None:
        barrier.wait()
        service.load()

    with patch("faster_whisper.WhisperModel", mock_whisper):
        threads = [threading.Thread(target=load_model) for _ in range(8)]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join()

    assert mock_whisper.call_count == 1
    assert service.is_loaded


def test_load_is_idempotent_after_first_load():
    service = ASRService()
    mock_whisper = MagicMock()

    with patch("faster_whisper.WhisperModel", mock_whisper):
        service.load()
        service.load()
        service.load()

    assert mock_whisper.call_count == 1
