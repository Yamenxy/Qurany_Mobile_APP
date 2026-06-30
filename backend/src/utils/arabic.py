"""Arabic text normalization and word-similarity helpers.

These mirror the on-device logic in the Flutter client
(`recitation_screen.dart::_normalizeArabic` / `_isSimilar`) so that the
backend produces results consistent with the existing app behaviour, with a
few extra normalizations for robustness.
"""
from __future__ import annotations

import re

# Quranic diacritics (tashkeel) + superscript alef.
_DIACRITICS = re.compile(r"[\u064B-\u065F\u0670]")
# Tatweel / kashida.
_TATWEEL = "\u0640"
# Alef variants -> bare alef.
_ALEF_VARIANTS = re.compile(r"[\u0625\u0623\u0622\u0671\u0627]")
# Anything that is not an Arabic letter or whitespace.
_NON_ARABIC = re.compile(r"[^\u0621-\u064A\s]")
_MULTISPACE = re.compile(r"\s+")


def normalize_arabic(text: str) -> str:
    """Return a diacritic-free, normalized form suitable for comparison.

    Steps: strip tashkeel, remove tatweel, unify alef/hamza/ya/ta-marbuta
    variants, drop non-Arabic characters, and collapse whitespace.
    """
    if not text:
        return ""

    text = _DIACRITICS.sub("", text)
    text = text.replace(_TATWEEL, "")
    text = _ALEF_VARIANTS.sub("\u0627", text)
    # Hamza on waw / ya -> bare forms.
    text = text.replace("\u0624", "\u0648")  # ؤ -> و
    text = text.replace("\u0626", "\u064A")  # ئ -> ي
    # Alef maqsura -> ya.
    text = text.replace("\u0649", "\u064A")
    # Ta marbuta -> ha.
    text = text.replace("\u0629", "\u0647")
    # Standalone hamza removed.
    text = text.replace("\u0621", "")
    text = _NON_ARABIC.sub("", text)
    text = _MULTISPACE.sub(" ", text).strip()
    return text


def normalize_words(text: str) -> list[str]:
    """Normalize then split into a list of non-empty word tokens."""
    norm = normalize_arabic(text)
    return [w for w in norm.split(" ") if w]


def word_similarity(a: str, b: str) -> float:
    """Jaccard similarity of the character sets of two words (0..1)."""
    if a == b:
        return 1.0
    set_a, set_b = set(a), set(b)
    union = set_a | set_b
    if not union:
        return 0.0
    return len(set_a & set_b) / len(union)


def is_similar(a: str, b: str, threshold: float = 0.6) -> bool:
    """Whether two normalized words are "close enough" to be a partial match."""
    if a == b:
        return True
    return word_similarity(a, b) > threshold
