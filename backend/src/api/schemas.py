"""Pydantic request/response models.

Field aliases keep the JSON wire format identical to what the Flutter client
already expects (top-level keys are snake_case; error fields are camelCase, as
in `recitation_session.dart::RecitationError`).
"""
from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


class RecitationError(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    type: str = Field(description="substitution | omission | addition | sequence")
    expected_word: str = Field(default="", alias="expectedWord")
    recited_word: str = Field(default="", alias="recitedWord")
    word_index: int = Field(default=0, alias="wordIndex")


class TranscriptionSegment(BaseModel):
    start: float
    end: float
    text: str


class AnalysisResult(BaseModel):
    transcribed_text: str
    reference_text: str
    similarity_score: float = Field(ge=0, le=100)
    total_words: int
    matched_words: int
    mistakes: int
    errors: list[RecitationError] = Field(default_factory=list)
    segments: list[TranscriptionSegment] = Field(default_factory=list)


class AnalyzeTextRequest(BaseModel):
    surah_number: int = Field(default=78, description="Chapter number (MVP: 78)")
    transcribed_text: str = Field(min_length=1)


class TranscriptionResponse(BaseModel):
    text: str
    language: str
    duration: float
    segments: list[TranscriptionSegment] = Field(default_factory=list)


class SurahAyah(BaseModel):
    numberInSurah: int
    globalNumber: int
    text: str


class SurahReferenceResponse(BaseModel):
    surah_number: int
    name: str
    numberOfAyahs: int
    full_text: str
    normalized_text: str
    ayahs: list[SurahAyah]


class HealthResponse(BaseModel):
    status: str
    app: str
    asr_model: str
    asr_loaded: bool
    supported_surahs: list[int]
