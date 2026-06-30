"""HTTP API routes for recitation analysis."""
from __future__ import annotations

import logging
import shutil
import uuid
from pathlib import Path

from fastapi import (
    APIRouter,
    File,
    Form,
    HTTPException,
    UploadFile,
    WebSocket,
    WebSocketDisconnect,
)
from fastapi.concurrency import run_in_threadpool

from ..config import settings
from ..services.analysis_service import analyze_audio, analyze_text
from ..services.asr_service import asr_service
from ..services.reference_service import get_surah_reference
from . import schemas

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1")

_ALLOWED_AUDIO_SUFFIXES = {".wav", ".mp3", ".m4a", ".aac", ".ogg", ".flac", ".webm"}


def _validate_surah(surah_number: int) -> None:
    if surah_number not in settings.supported_surahs:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Surah {surah_number} is not supported in this MVP. "
                f"Supported surahs: {settings.supported_surahs}."
            ),
        )


def _save_upload(file: UploadFile) -> Path:
    suffix = Path(file.filename or "").suffix.lower() or ".wav"
    if suffix not in _ALLOWED_AUDIO_SUFFIXES:
        raise HTTPException(
            status_code=415,
            detail=f"Unsupported audio type '{suffix}'. "
            f"Allowed: {sorted(_ALLOWED_AUDIO_SUFFIXES)}.",
        )
    settings.uploads_dir.mkdir(parents=True, exist_ok=True)
    dest = settings.uploads_dir / f"{uuid.uuid4().hex}{suffix}"
    with dest.open("wb") as out:
        shutil.copyfileobj(file.file, out)
    return dest


@router.get("/surahs", summary="List supported surahs")
def list_surahs() -> dict:
    return {"supported_surahs": settings.supported_surahs}


@router.get(
    "/surahs/{surah_number}",
    response_model=schemas.SurahReferenceResponse,
    summary="Get a surah's reference text",
)
def get_surah(surah_number: int) -> dict:
    _validate_surah(surah_number)
    ref = get_surah_reference(surah_number)
    return ref.to_dict()


@router.post(
    "/transcribe",
    response_model=schemas.TranscriptionResponse,
    summary="Transcribe a recitation audio file (no comparison)",
)
async def transcribe(file: UploadFile = File(...)) -> dict:
    audio_path = _save_upload(file)
    try:
        result = await run_in_threadpool(asr_service.transcribe, str(audio_path))
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    finally:
        audio_path.unlink(missing_ok=True)
    return {
        "text": result.text,
        "language": result.language,
        "duration": result.duration,
        "segments": [s.to_dict() for s in result.segments],
    }


@router.post(
    "/analyze",
    response_model=schemas.AnalysisResult,
    response_model_by_alias=True,
    summary="Transcribe audio and compare it against the surah reference",
)
async def analyze(
    file: UploadFile = File(...),
    surah_number: int = Form(78),
) -> dict:
    _validate_surah(surah_number)
    audio_path = _save_upload(file)
    try:
        return await run_in_threadpool(analyze_audio, surah_number, str(audio_path))
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    finally:
        audio_path.unlink(missing_ok=True)


@router.post(
    "/analyze-text",
    response_model=schemas.AnalysisResult,
    response_model_by_alias=True,
    summary="Compare an existing transcript against the surah reference",
)
async def analyze_transcript(payload: schemas.AnalyzeTextRequest) -> dict:
    _validate_surah(payload.surah_number)
    return analyze_text(payload.surah_number, payload.transcribed_text)


@router.websocket("/stream")
async def stream_alignment(websocket: WebSocket) -> None:
    """Live alignment feedback over WebSocket.

    The client sends JSON frames as the (partial) transcript grows:

        {"surah_number": 78, "transcribed_text": "..."}

    and receives an analysis result frame (same shape as ``/analyze-text``)
    for each message, enabling server-driven live highlighting without
    streaming audio. Send {"type": "end"} to close.
    """
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_json()
            if data.get("type") == "end":
                break
            surah_number = int(data.get("surah_number", 78))
            transcript = str(data.get("transcribed_text", ""))
            if surah_number not in settings.supported_surahs:
                await websocket.send_json(
                    {"error": f"Surah {surah_number} not supported."}
                )
                continue
            result = analyze_text(surah_number, transcript)
            await websocket.send_json(result)
    except WebSocketDisconnect:
        return
    except (ValueError, KeyError) as exc:
        await websocket.send_json({"error": str(exc)})
