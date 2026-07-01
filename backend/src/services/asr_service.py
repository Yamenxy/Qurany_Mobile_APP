"""Speech-to-text using faster-whisper (local, free, CPU/GPU).

The model is loaded lazily on first use and reused across requests. Importing
faster-whisper is deferred so the rest of the app (and the test suite) can run
even when the heavy ML dependency is not installed.
"""
from __future__ import annotations

import logging
import threading
from dataclasses import dataclass, field

from ..config import settings

logger = logging.getLogger(__name__)


@dataclass
class TranscriptionSegment:
    start: float
    end: float
    text: str

    def to_dict(self) -> dict:
        return {"start": self.start, "end": self.end, "text": self.text}


@dataclass
class TranscriptionResult:
    text: str
    language: str
    duration: float = 0.0
    segments: list[TranscriptionSegment] = field(default_factory=list)


class ASRService:
    """Thin wrapper around a lazily-loaded faster-whisper model."""

    def __init__(self) -> None:
        self._model = None
        self._load_lock = threading.Lock()

    @property
    def is_loaded(self) -> bool:
        return self._model is not None

    def load(self) -> None:
        """Load the Whisper model into memory (idempotent, thread-safe)."""
        if self._model is not None:
            return

        with self._load_lock:
            # Double-checked locking: another thread may have loaded while waiting.
            if self._model is not None:
                return
            try:
                from faster_whisper import WhisperModel
            except ImportError as exc:  # pragma: no cover - depends on env
                raise RuntimeError(
                    "faster-whisper is not installed. Run "
                    "`pip install -r requirements.txt`."
                ) from exc

            logger.info(
                "Loading Whisper model '%s' (device=%s, compute_type=%s)...",
                settings.whisper_model,
                settings.whisper_device,
                settings.whisper_compute_type,
            )
            self._model = WhisperModel(
                settings.whisper_model,
                device=settings.whisper_device,
                compute_type=settings.whisper_compute_type,
            )
            logger.info("Whisper model loaded.")

    def transcribe(self, audio_path: str, language: str | None = None) -> TranscriptionResult:
        """Transcribe an audio file to Arabic text."""
        self.load()
        assert self._model is not None

        segments_iter, info = self._model.transcribe(
            audio_path,
            language=language or settings.asr_language,
            beam_size=settings.whisper_beam_size,
            vad_filter=True,
        )

        segments: list[TranscriptionSegment] = []
        parts: list[str] = []
        for seg in segments_iter:
            text = seg.text.strip()
            segments.append(TranscriptionSegment(start=seg.start, end=seg.end, text=text))
            parts.append(text)

        return TranscriptionResult(
            text=" ".join(parts).strip(),
            language=getattr(info, "language", language or settings.asr_language),
            duration=getattr(info, "duration", 0.0) or 0.0,
            segments=segments,
        )


# Module-level singleton.
asr_service = ASRService()
