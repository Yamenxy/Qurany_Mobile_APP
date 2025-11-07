# Qurany — Whisper-based Arabic Transcription

This small project demonstrates using OpenAI's Whisper (openai-whisper) in Python to:
- Preprocess audio (noise reduction),
- Transcribe Arabic audio accurately using a tuned Whisper configuration,
- Save a full transcription and timestamped segments to `transcription_output.txt`,
- Compare the predicted transcription with a reference (verse) and save the comparison to `comparison_result.txt`.

The main script is `Test.py` (in the project root).

## Files produced / used by the script
- `normal.dat.mp3` (example input) — change the input path in `Test.py` using the `input_audio` variable.
- `cleaned_audio.wav` — the intermediate denoised audio file produced by the script.
- `transcription_output.txt` — full transcription + timestamped segments (UTF-8 encoded).
- `comparison_result.txt` — similarity and summary comparing transcription to `ikhlas[1].txt`.
- `ikhlas[1].txt` — your reference verse file (used for comparison).

## Requirements
- Windows (instructions below are Windows-oriented), but the code works on Linux/macOS with adjusted ffmpeg install.
- Python 3.8+ (the workspace currently runs Python 3.13 in the examples).
- FFmpeg installed and available on PATH (used by Whisper to read audio formats).

Python packages (examples):
- openai-whisper
- torch (install following the official PyTorch instructions for CPU or CUDA)
- librosa
- soundfile (pysoundfile)
- noisereduce
- rapidfuzz

A short, typical install (PowerShell):

```powershell
# Install ffmpeg (Windows) using winget (requires Windows 10/11)
winget install -e --id Gyan.FFmpeg
# Restart your terminal after ffmpeg installation so PATH is updated

# Create and activate a venv (optional but recommended)
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# Install Python packages (CPU Torch example — check https://pytorch.org for matching wheel for your python & OS)
pip install openai-whisper librosa soundfile noisereduce rapidfuzz
# Install torch per official instructions; for a CPU-only example:
pip install torch --index-url https://download.pytorch.org/whl/cpu
```

Note: If you have a CUDA-capable GPU and want faster transcription with larger Whisper models, install a suitable GPU build of `torch` per PyTorch's website.

## How to run
1. Put your audio file and any reference file in the project root or adjust `input_audio` and `REFERENCE_FILE` paths in `Test.py`.
2. Run the script from the project folder:

```powershell
python Test.py
```

3. After successful run, you will see these files written to the project root:
- `cleaned_audio.wav` (intermediate)
- `transcription_output.txt` (transcribed text + timestamps, UTF-8)
- `comparison_result.txt` (similarity metrics vs the reference)

The `transcription_output.txt` format contains two sections:
- "Full Transcription" — the full concatenated text
- "Timestamped Segments" — each segment line is prefixed with a timestamp like:
  `[MM:SS.mmm --> MM:SS.mmm] <segment text>`

## Tuning & notes for Arabic transcription
- The script uses `whisper.load_model("medium")` by default for a balance of accuracy and performance. Use `large` for best accuracy (needs more RAM and CPU/GPU power).
- The script sets `language="ar"` and an `initial_prompt` to bias toward Modern Standard Arabic (MSA). For dialects, you may remove the `initial_prompt` or provide dialect-specific hints.
- `condition_on_previous_text=True` helps with context across segments.
- If you run out of memory / encounter long runtimes:
  - Use a smaller model (e.g., `small` or `base`), or
  - Process audio in shorter chunks and transcribe chunk-by-chunk.

## Troubleshooting
- "FP16 is not supported on CPU": informational; Whisper will use FP32 on CPU automatically.
- `FileNotFoundError` for ffmpeg or `ffmpeg not found`: ensure ffmpeg is installed and your terminal restarted after installation (so PATH is updated). Test with `ffmpeg -version`.
- If transcription gets interrupted or hangs on large models: try `medium` or `small`, or run on a machine with a GPU and proper CUDA PyTorch.

## Where to edit behavior
Open `Test.py` and modify these top-level variables to suit your needs:
- `input_audio` — path to the source audio file (currently set to `B:/Workspace/Qurany/normal.dat.mp3`).
- `clean_audio` — name/path for the cleaned output.
- `model = whisper.load_model("medium")` — change to `base|small|medium|large`.
- `initial_prompt` and `language` in `model.transcribe(...)` — tailor to dialect or MSA.
- `output_path` and `REFERENCE_FILE` — filenames for outputs/reference.

## Enhancements you might want next
- Add a `requirements.txt` and a tiny `run.sh`/`run.bat` for reproducible run commands.
- Add chunked audio processing for long files (streaming or sliding-window) to reduce memory usage.
- Add a CLI wrapper to pass input/output paths and model choices as arguments.

## License & credits
This repository is a small demo combining these libraries:
- Whisper (openai-whisper)
- librosa, pysoundfile, noisereduce for audio preprocessing
- rapidfuzz for fuzzy matching

Adapt and use per the licenses of the included third-party libraries.

---
If you'd like, I can also:
- Add a `requirements.txt` with pinned versions,
- Implement chunked transcription to avoid memory issues with `medium`/`large` models,
- Or add a simple CLI to pass input/output paths and model size.

Tell me which of these you'd like next and I will implement it.