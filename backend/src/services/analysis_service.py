"""Orchestrates the full recitation-analysis pipeline.

audio -> ASR transcription -> Arabic normalization -> alignment vs reference
-> word-by-word error feedback.

The returned dict matches the shape consumed by the Flutter client
(see `recitation_screen.dart::_performLocalComparison`).
"""
from __future__ import annotations

from .alignment_service import analyze_alignment
from .asr_service import TranscriptionResult, asr_service
from .reference_service import get_surah_reference


def _build_result(
    reference_text: str,
    transcribed_text: str,
    segments: list[dict] | None = None,
) -> dict:
    feedback = analyze_alignment(reference_text, transcribed_text)
    return {
        "transcribed_text": transcribed_text,
        "reference_text": reference_text,
        "similarity_score": feedback["similarity_score"],
        "total_words": feedback["total_words"],
        "matched_words": feedback["matched_words"],
        "mistakes": feedback["mistakes"],
        "errors": feedback["errors"],
        "segments": segments or [],
    }


def analyze_text(surah_number: int, transcribed_text: str) -> dict:
    """Compare already-transcribed text against a surah's reference."""
    reference = get_surah_reference(surah_number)
    return _build_result(reference.full_text, transcribed_text)


def analyze_audio(surah_number: int, audio_path: str) -> dict:
    """Full pipeline: transcribe the audio file, then compare."""
    reference = get_surah_reference(surah_number)
    result: TranscriptionResult = asr_service.transcribe(audio_path)
    segments = [s.to_dict() for s in result.segments]
    return _build_result(reference.full_text, result.text, segments)
