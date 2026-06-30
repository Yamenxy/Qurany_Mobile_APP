"""Root entry point. Run with: python main.py  (or: uvicorn src.main:app)."""
from __future__ import annotations

import uvicorn

from src.config import settings

if __name__ == "__main__":
    uvicorn.run(
        "src.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
    )
