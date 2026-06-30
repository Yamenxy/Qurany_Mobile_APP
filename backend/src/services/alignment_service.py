"""Word-level alignment and error classification.

Aligns a (normalized) recited transcript against the (normalized) reference
recitation using Needleman-Wunsch dynamic programming, then classifies the
differences into the error types the Flutter client understands:

    substitution | omission | addition | sequence

The output dict matches the contract consumed by the app
(`recitation_screen.dart` / `recitation_session.dart`):

    {
      "similarity_score": float,   # 0..100
      "total_words": int,
      "matched_words": int,
      "mistakes": int,
      "errors": [{"type", "expectedWord", "recitedWord", "wordIndex"}],
    }
"""
from __future__ import annotations

from dataclasses import dataclass

from ..config import settings
from ..utils.arabic import is_similar, normalize_arabic

# Backtrace operation kinds.
_MATCH = "match"
_SUB = "substitution"
_DEL = "omission"   # in reference, not recited
_INS = "addition"   # recited, not in reference


@dataclass
class _Op:
    kind: str
    ref_index: int | None   # index into reference word list
    expected: str           # original reference word ("" for additions)
    recited: str            # transcribed word ("" for omissions)


def _tokenize(original_text: str) -> tuple[list[str], list[str]]:
    """Return (original_words, normalized_words) kept index-aligned.

    Words that normalize to empty (e.g. pure punctuation) are dropped from
    both lists together so indices stay in sync.
    """
    originals: list[str] = []
    normalized: list[str] = []
    for raw in original_text.split():
        norm = normalize_arabic(raw)
        if not norm:
            continue
        originals.append(raw)
        normalized.append(norm)
    return originals, normalized


def _words_match(a: str, b: str, threshold: float) -> bool:
    return a == b or is_similar(a, b, threshold)


def _align(ref: list[str], hyp: list[str], threshold: float) -> list[_Op]:
    """Needleman-Wunsch alignment over normalized tokens.

    Returns the ordered list of operations describing how to turn the
    reference sequence into the recited sequence.
    """
    n, m = len(ref), len(hyp)
    # cost[i][j] = min edit cost aligning ref[:i] with hyp[:j]
    cost = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(1, n + 1):
        cost[i][0] = i
    for j in range(1, m + 1):
        cost[0][j] = j

    for i in range(1, n + 1):
        for j in range(1, m + 1):
            sub_cost = 0 if _words_match(ref[i - 1], hyp[j - 1], threshold) else 1
            cost[i][j] = min(
                cost[i - 1][j - 1] + sub_cost,  # match / substitution
                cost[i - 1][j] + 1,             # deletion (omission)
                cost[i][j - 1] + 1,             # insertion (addition)
            )

    # Backtrace from (n, m) to (0, 0).
    ops: list[_Op] = []
    i, j = n, m
    while i > 0 or j > 0:
        if i > 0 and j > 0:
            matched = _words_match(ref[i - 1], hyp[j - 1], threshold)
            sub_cost = 0 if matched else 1
            if cost[i][j] == cost[i - 1][j - 1] + sub_cost:
                ops.append(
                    _Op(
                        kind=_MATCH if matched else _SUB,
                        ref_index=i - 1,
                        expected=ref[i - 1],
                        recited=hyp[j - 1],
                    )
                )
                i -= 1
                j -= 1
                continue
        if i > 0 and cost[i][j] == cost[i - 1][j] + 1:
            ops.append(
                _Op(kind=_DEL, ref_index=i - 1, expected=ref[i - 1], recited="")
            )
            i -= 1
            continue
        # insertion
        ops.append(_Op(kind=_INS, ref_index=i, expected="", recited=hyp[j - 1]))
        j -= 1

    ops.reverse()
    return ops


def _detect_sequence_errors(ops: list[_Op]) -> None:
    """Re-label adjacent transposed substitutions as 'sequence' errors.

    A swap looks like: ref[A]->hyp[B] followed by ref[B]->hyp[A].
    """
    for k in range(len(ops) - 1):
        a, b = ops[k], ops[k + 1]
        if a.kind == _SUB and b.kind == _SUB:
            if a.expected == b.recited and b.expected == a.recited and a.expected:
                a.kind = "sequence"
                b.kind = "sequence"


def analyze_alignment(
    reference_text: str,
    transcribed_text: str,
    threshold: float | None = None,
) -> dict:
    """Compare a recitation against the reference and produce feedback."""
    if threshold is None:
        threshold = settings.similarity_threshold

    ref_original, ref_norm = _tokenize(reference_text)
    _, hyp_norm = _tokenize(transcribed_text)

    total_words = len(ref_norm)

    ops = _align(ref_norm, hyp_norm, threshold)
    _detect_sequence_errors(ops)

    errors: list[dict] = []
    for op in ops:
        if op.kind == _MATCH:
            continue
        if op.kind in (_SUB, "sequence", _DEL):
            idx = op.ref_index if op.ref_index is not None else 0
            expected_display = (
                ref_original[idx] if 0 <= idx < len(ref_original) else op.expected
            )
            errors.append(
                {
                    "type": op.kind,
                    "expectedWord": expected_display if op.kind != _INS else "",
                    "recitedWord": op.recited,
                    "wordIndex": idx,
                }
            )
        elif op.kind == _INS:
            idx = min(op.ref_index or 0, max(total_words - 1, 0))
            errors.append(
                {
                    "type": _INS,
                    "expectedWord": "",
                    "recitedWord": op.recited,
                    "wordIndex": idx,
                }
            )

    # Reference words counted as wrong (everything except additions).
    ref_errors = sum(1 for e in errors if e["type"] != _INS)
    matched_words = max(total_words - ref_errors, 0)
    mistakes = len(errors)

    similarity = (matched_words / total_words * 100) if total_words else 0.0
    similarity = max(0.0, min(100.0, similarity))

    return {
        "similarity_score": round(similarity, 2),
        "total_words": total_words,
        "matched_words": matched_words,
        "mistakes": mistakes,
        "errors": errors,
    }
