import whisper
import re
import librosa
import soundfile as sf
import noisereduce as nr
from rapidfuzz import fuzz

# -------------------------------
# 1️⃣ Preprocess Audio (Noise Reduction)
# -------------------------------
input_audio = "B:/Workspace/Qurany/normal.dat.mp3"
clean_audio = "cleaned_audio.wav"

print("🔊 Loading and cleaning audio...")
y, sr = librosa.load(input_audio, sr=None)

# Reduce background noise
y_reduced = nr.reduce_noise(y=y, sr=sr)

# Save the cleaned audio for Whisper
sf.write(clean_audio, y_reduced, sr)
print("✅ Audio cleaned and saved as:", clean_audio)

# -------------------------------
# 2️⃣ Load Whisper model
# -------------------------------
print("Loading Whisper model...")
model = whisper.load_model("medium")  # 'large' for higher accuracy

# -------------------------------
# 3️⃣ Transcribe Quran audio
# -------------------------------
print("Transcribing cleaned audio...")
result = model.transcribe(
    clean_audio,
    language="ar",
    task="transcribe",
    initial_prompt="الاستماع إلى تلاوة القرآن الكريم بالعربية الفصحى.",
    condition_on_previous_text=True,
    temperature=0.0,
    best_of=5,
    fp16=False
)

transcribed_text = result["text"]
segments = result["segments"]

# -------------------------------
# 4️⃣ Save transcription output
# -------------------------------
output_path = "transcription_output.txt"

with open(output_path, "w", encoding="utf-8") as f:
    f.write("Full Transcription:\n")
    f.write("-" * 50 + "\n")
    f.write(transcribed_text)
    f.write("\n\nTimestamped Segments:\n")
    f.write("-" * 50 + "\n")
    for segment in segments:
        start = segment["start"]
        end = segment["end"]
        text = segment["text"]
        timestamp = f"[{int(start//60):02d}:{start%60:06.3f} --> {int(end//60):02d}:{end%60:06.3f}]"
        f.write(f"{timestamp} {text}\n")

print(f"✅ Transcription saved to '{output_path}'")

# -------------------------------
# 5️⃣ Compare with reference Quran verse
# -------------------------------
REFERENCE_FILE = "ikhlas[1].txt"

with open(REFERENCE_FILE, "r", encoding="utf-8") as f:
    reference_text = f.read().strip()

# Normalization functions
def normalize_keep_tashkeel(text):
    # Keep tashkeel, only remove punctuation & normalize spaces
    text = re.sub(r"[^\u0600-\u06FF\sًٌٍَُِّْٰـ]", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text

def normalize_remove_tashkeel(text):
    # Remove tashkeel for comparison without diacritics
    text = re.sub(r"[ًٌٍَُِّْٰـ]", "", text)
    text = re.sub(r"[^\u0600-\u06FF\s]", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text

# Prepare all versions
predicted_raw = transcribed_text.strip()
predicted_with_tashkeel = normalize_keep_tashkeel(predicted_raw)
predicted_no_tashkeel = normalize_remove_tashkeel(predicted_raw)
reference_with_tashkeel = normalize_keep_tashkeel(reference_text)
reference_no_tashkeel = normalize_remove_tashkeel(reference_text)

# Similarity scores
similarity_with_tashkeel = fuzz.token_sort_ratio(predicted_with_tashkeel, reference_with_tashkeel)
similarity_no_tashkeel = fuzz.token_sort_ratio(predicted_no_tashkeel, reference_no_tashkeel)

# Word-level match count (no tashkeel)
pred_words = predicted_no_tashkeel.split()
ref_words = reference_no_tashkeel.split()
matched_words = sum(1 for w in pred_words if w in ref_words)
total_words = len(ref_words)
mistakes = total_words - matched_words if total_words > matched_words else 0

# -------------------------------
# 6️⃣ Print results
# -------------------------------
print("\n🔹 Reference Text (with Tashkeel):")
print(reference_with_tashkeel)
print("\n🔹 Predicted Text (with Tashkeel):")
print(predicted_with_tashkeel)
print("\n----------------------------------")
print(f"✅ Similarity WITH Tashkeel: {similarity_with_tashkeel:.2f}%")
print(f"✅ Similarity WITHOUT Tashkeel: {similarity_no_tashkeel:.2f}%")
print(f"📖 Total Words in Reference: {total_words}")
print(f"✅ Matched Words: {matched_words}")
print(f"❌ Estimated Mistakes: {mistakes}")

# Save summary
with open("comparison_result.txt", "w", encoding="utf-8") as f:
    f.write("Reference Text (with Tashkeel):\n" + reference_with_tashkeel + "\n\n")
    f.write("Predicted Text (with Tashkeel):\n" + predicted_with_tashkeel + "\n\n")
    f.write(f"Similarity WITH Tashkeel: {similarity_with_tashkeel:.2f}%\n")
    f.write(f"Similarity WITHOUT Tashkeel: {similarity_no_tashkeel:.2f}%\n")
    f.write(f"Total Words: {total_words}\nMatched Words: {matched_words}\nMistakes: {mistakes}\n")

print("\n✅ Comparison results saved to 'comparison_result.txt'")
