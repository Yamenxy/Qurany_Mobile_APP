"""FastAPI application entry point for the Qurany recitation backend."""
from __future__ import annotations

import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api import schemas
from .api.routes import router as api_router
from .config import settings
from .services.asr_service import asr_service

logging.basicConfig(
    level=logging.DEBUG if settings.debug else logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


def create_app() -> FastAPI:
    app = FastAPI(
        title="Qurany Recitation Backend",
        description=(
            "Receives recitation audio, transcribes it with faster-whisper, "
            "aligns it against canonical Quran text, and returns word-by-word "
            "feedback. MVP scope: Surah Al-Naba (chapter 78)."
        ),
        version="0.1.0",
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(api_router)

    @app.get("/", include_in_schema=False)
    def root() -> dict:
        return {"service": settings.app_name, "docs": "/docs"}

    @app.get("/health", response_model=schemas.HealthResponse, summary="Health check")
    def health() -> dict:
        return {
            "status": "ok",
            "app": settings.app_name,
            "asr_model": settings.whisper_model,
            "asr_loaded": asr_service.is_loaded,
            "supported_surahs": settings.supported_surahs,
        }

    return app


app = create_app()
