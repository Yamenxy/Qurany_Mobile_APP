"""
Qurany Backend API Server
=========================
Flask-based API server that provides:
- Audio transcription using OpenAI Whisper
- Comparison with reference Quranic text
- Error detection and classification

Run with: python app.py
"""

import os
import re
import json
import tempfile
from flask import Flask, request, jsonify
from flask_cors import CORS

# Ensure ffmpeg is available (bundled via imageio-ffmpeg)
try:
    import imageio_ffmpeg
    _ffmpeg_dir = os.path.dirname(imageio_ffmpeg.get_ffmpeg_exe())
    if _ffmpeg_dir not in os.environ.get("PATH", ""):
        os.environ["PATH"] = _ffmpeg_dir + os.pathsep + os.environ.get("PATH", "")
        print(f"Added ffmpeg to PATH: {_ffmpeg_dir}")
except ImportError:
    print("Warning: imageio-ffmpeg not installed. Whisper may fail if ffmpeg is not in PATH.")

app = Flask(__name__)
CORS(app)

# ─────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────
WHISPER_MODEL = os.environ.get("WHISPER_MODEL", "medium")
model = None  # Lazy-loaded

# Session storage for streaming transcriptions
_session_texts = {}  # session_id -> accumulated text


def get_model():
    """Lazy-load the Whisper model to avoid startup delay if not needed."""
    global model
    if model is None:
        import whisper
        print(f"Loading Whisper model '{WHISPER_MODEL}'...")
        model = whisper.load_model(WHISPER_MODEL)
        print("Whisper model loaded.")
    return model


# ─────────────────────────────────────────────
# Arabic text utilities
# ─────────────────────────────────────────────
def normalize_arabic(text):
    """Remove diacritics and normalize Arabic text for comparison."""
    text = re.sub(r"[ًٌٍَُِّْٰـ]", "", text)  # Remove tashkeel
    text = re.sub(r"[^ء-ي\s]", "", text)        # Remove non-Arabic chars
    text = re.sub(r"\s+", " ", text).strip()
    return text


def compare_texts(predicted_text, reference_text):
    """
    Compare predicted (transcribed) text with reference Quranic text.
    Returns detailed comparison results with error classification.
    """
    from rapidfuzz import fuzz

    predicted = normalize_arabic(predicted_text)
    reference = normalize_arabic(reference_text)

    # Overall similarity
    similarity = fuzz.token_sort_ratio(predicted, reference)

    pred_words = predicted.split()
    ref_words = reference.split()

    # Word-level comparison
    errors = []
    matched_words = 0

    # Use dynamic programming (LCS-like) for alignment
    i, j = 0, 0
    while i < len(ref_words) and j < len(pred_words):
        if ref_words[i] == pred_words[j]:
            matched_words += 1
            i += 1
            j += 1
        else:
            # Check if it's a substitution, omission, or addition
            # Look ahead to determine
            if i + 1 < len(ref_words) and j < len(pred_words) and ref_words[i + 1] == pred_words[j]:
                # Omission: reference word was skipped
                errors.append({
                    'type': 'omission',
                    'expectedWord': ref_words[i],
                    'recitedWord': '',
                    'wordIndex': i,
                })
                i += 1
            elif j + 1 < len(pred_words) and i < len(ref_words) and ref_words[i] == pred_words[j + 1]:
                # Addition: extra word in prediction
                errors.append({
                    'type': 'addition',
                    'expectedWord': '',
                    'recitedWord': pred_words[j],
                    'wordIndex': j,
                })
                j += 1
            else:
                # Substitution
                errors.append({
                    'type': 'substitution',
                    'expectedWord': ref_words[i],
                    'recitedWord': pred_words[j],
                    'wordIndex': i,
                })
                i += 1
                j += 1

    # Remaining reference words are omissions
    while i < len(ref_words):
        errors.append({
            'type': 'omission',
            'expectedWord': ref_words[i],
            'recitedWord': '',
            'wordIndex': i,
        })
        i += 1

    # Remaining predicted words are additions
    while j < len(pred_words):
        errors.append({
            'type': 'addition',
            'expectedWord': '',
            'recitedWord': pred_words[j],
            'wordIndex': j,
        })
        j += 1

    total_words = len(ref_words)
    mistakes = len(errors)

    return {
        'similarity_score': round(similarity, 2),
        'total_words': total_words,
        'matched_words': matched_words,
        'mistakes': mistakes,
        'errors': errors,
        'predicted_normalized': predicted,
        'reference_normalized': reference,
    }


# ─────────────────────────────────────────────
# Quran reference text (load from file or API)
# ─────────────────────────────────────────────
def get_surah_text(surah_number):
    """Get the reference text for a given surah."""
    try:
        import requests
        url = f"https://api.alquran.cloud/v1/surah/{surah_number}/ar.uthmani"
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            data = response.json()
            ayahs = data['data']['ayahs']
            return ' '.join(a['text'] for a in ayahs)
    except Exception as e:
        print(f"Error fetching surah {surah_number}: {e}")

    # Fallback: check local file
    local_files = {
        112: 'ikhlas[1].txt',
    }
    if surah_number in local_files:
        filepath = os.path.join(os.path.dirname(__file__), '..', local_files[surah_number])
        if os.path.exists(filepath):
            with open(filepath, 'r', encoding='utf-8') as f:
                return f.read().strip()

    return ''


# ─────────────────────────────────────────────
# API Routes
# ─────────────────────────────────────────────

@app.route('/api/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({
        'status': 'ok',
        'model': WHISPER_MODEL,
        'version': '1.0.0',
    })


@app.route('/api/transcribe', methods=['POST'])
def transcribe():
    """
    Transcribe audio and compare with reference Quranic text.

    Expects multipart form data with:
    - audio: audio file (wav, mp3, etc.)
    - surah_number: integer (surah to compare against)
    """
    if 'audio' not in request.files:
        return jsonify({'error': 'No audio file provided'}), 400

    audio_file = request.files['audio']
    surah_number = int(request.form.get('surah_number', 112))

    # Save audio to temp file
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
        audio_file.save(tmp.name)
        tmp_path = tmp.name

    try:
        # Transcribe with Whisper
        whisper_model = get_model()
        result = whisper_model.transcribe(
            tmp_path,
            language="ar",
            task="transcribe",
            initial_prompt="يتحدث باللغة العربية الفصحى",
            condition_on_previous_text=True,
            temperature=0.0,
            best_of=5,
            fp16=False,
        )

        transcribed_text = result['text'].strip()
        segments = result.get('segments', [])

        # Guard against Whisper echoing the initial_prompt on silent/empty audio
        prompt_text = normalize_arabic("يتحدث باللغة العربية الفصحى")
        if normalize_arabic(transcribed_text) == prompt_text or not transcribed_text:
            return jsonify({'error': 'لم يتم التعرف على أي كلام في التسجيل'}), 422

        # Get reference text
        reference_text = get_surah_text(surah_number)
        if not reference_text:
            return jsonify({
                'error': f'Could not load reference text for Surah {surah_number}'
            }), 404

        # Compare
        comparison = compare_texts(transcribed_text, reference_text)

        # Build response
        response = {
            'transcribed_text': transcribed_text,
            'reference_text': reference_text,
            'similarity_score': comparison['similarity_score'],
            'total_words': comparison['total_words'],
            'matched_words': comparison['matched_words'],
            'mistakes': comparison['mistakes'],
            'errors': comparison['errors'],
            'segments': [
                {
                    'start': s['start'],
                    'end': s['end'],
                    'text': s['text'],
                }
                for s in segments
            ],
        }

        return jsonify(response)

    except Exception as e:
        return jsonify({'error': str(e)}), 500

    finally:
        # Clean up temp file
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)


@app.route('/api/surah/<int:surah_number>', methods=['GET'])
def get_surah(surah_number):
    """Get reference text for a specific surah."""
    if surah_number < 1 or surah_number > 114:
        return jsonify({'error': 'Invalid surah number'}), 400

    text = get_surah_text(surah_number)
    if not text:
        return jsonify({'error': 'Surah text not available'}), 404

    return jsonify({
        'surah_number': surah_number,
        'text': text,
    })


@app.route('/api/stream', methods=['POST'])
def stream_audio():
    """
    Accept streaming audio chunks for real-time transcription.
    Maintains per-session accumulated text for progressive display.
    
    Accepts JSON with:
    - audio_data: base64-encoded audio chunk
    - session_id: unique session identifier
    - surah_number: surah being recited (for reference comparison)
    """
    import base64

    data = request.json
    if not data:
        return jsonify({'error': 'No data provided'}), 400

    session_id = data.get('session_id', '')
    surah_number = data.get('surah_number', 112)
    audio_data_b64 = data.get('audio_data', '')

    # If no audio data, return accumulated text for this session
    if not audio_data_b64:
        accumulated = _session_texts.get(session_id, '')
        return jsonify({
            'session_id': session_id,
            'text': accumulated,
            'is_final': False,
        })

    try:
        audio_bytes = base64.b64decode(audio_data_b64)

        # Save chunk to temp file
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
            tmp.write(audio_bytes)
            tmp_path = tmp.name

        # Transcribe chunk
        whisper_model = get_model()
        result = whisper_model.transcribe(
            tmp_path,
            language="ar",
            task="transcribe",
            initial_prompt="يتحدث باللغة العربية الفصحى",
            fp16=False,
        )

        os.unlink(tmp_path)

        chunk_text = result.get('text', '').strip()

        # Accumulate text for this session
        if session_id not in _session_texts:
            _session_texts[session_id] = ''
        
        if chunk_text:
            if _session_texts[session_id]:
                _session_texts[session_id] += ' ' + chunk_text
            else:
                _session_texts[session_id] = chunk_text

        # Optionally do partial comparison with reference
        partial_comparison = None
        reference_text = get_surah_text(surah_number)
        if reference_text and _session_texts[session_id]:
            try:
                partial = compare_texts(_session_texts[session_id], reference_text)
                partial_comparison = {
                    'similarity_score': partial['similarity_score'],
                    'matched_words': partial['matched_words'],
                    'mistakes': partial['mistakes'],
                }
            except Exception:
                pass

        return jsonify({
            'session_id': session_id,
            'text': _session_texts[session_id],
            'chunk_text': chunk_text,
            'is_final': False,
            'partial_comparison': partial_comparison,
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/stream/end', methods=['POST'])
def end_stream():
    """
    End a streaming session and clean up accumulated text.
    Returns the final accumulated text.
    """
    data = request.json or {}
    session_id = data.get('session_id', '')
    final_text = _session_texts.pop(session_id, '')
    return jsonify({
        'session_id': session_id,
        'text': final_text,
        'is_final': True,
    })


# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────
if __name__ == '__main__':
    print("=" * 50)
    print("  Qurany Backend API Server")
    print("=" * 50)
    print(f"  Whisper Model: {WHISPER_MODEL}")
    print(f"  Server: http://0.0.0.0:5000")
    print("=" * 50)

    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True,
    )
