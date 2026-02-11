import whisper
import re
from rapidfuzz import fuzz

# -------------------------------
# 1️⃣ Load Whisper model
# -------------------------------
print("Loading Whisper model...")
model = whisper.load_model("medium")  # 'large' gives better accuracy but slower

# -------------------------------
# 2️⃣ Transcribe Quran audio
# -------------------------------
print("Transcribing audio...")
result = model.transcribe(
    "B:/Workspace/Qurany/mistakes.dat (online-audio-converter.com).mp3",
    language="ar",           
    task="transcribe",      
    initial_prompt="يتحدث باللغة العربية الفصحى",
    condition_on_previous_text=True,
    temperature=0.0,
    best_of=5,
    fp16=False
)

# Extract results
transcribed_text = result["text"]
segments = result["segments"]

# -------------------------------
# 3️⃣ Save transcription output
# -------------------------------
output_path = "transcription_output.txt"

with open(output_path, "w", encoding="utf-8") as f:
    f.write("Full Transcription:\n")
    f.write("-" * 50 + "\n")
    f.write(transcribed_text)
    f.write("\n\n")
    f.write("Timestamped Segments:\n")
    f.write("-" * 50 + "\n")
    for segment in segments:
        start = segment["start"]
        end = segment["end"]
        text = segment["text"]
        timestamp = f"[{int(start//60):02d}:{start%60:06.3f} --> {int(end//60):02d}:{end%60:06.3f}]"
        f.write(f"{timestamp} {text}\n")

print(f"✅ Transcription saved to '{output_path}'")

# -------------------------------
# 4️⃣ Compare with reference Quran verse
# -------------------------------

# Load the reference Quran text (the correct verse)
REFERENCE_FILE = "ikhlas[1].txt"  # change path if needed

with open(REFERENCE_FILE, "r", encoding="utf-8") as f:
    reference_text = f.read().strip()

# Function to normalize Arabic text for fair comparison
def normalize_arabic(text):
    text = re.sub(r"[ًٌٍَُِّْٰـ]", "", text)  # Remove diacritics (tashkeel)
    text = re.sub(r"[^ء-ي\s]", "", text)     # Remove punctuation
    text = re.sub(r"\s+", " ", text).strip()
    return text

# Normalize both
predicted = normalize_arabic(transcribed_text)
reference = normalize_arabic(reference_text)

# Compute similarity score
similarity = fuzz.token_sort_ratio(predicted, reference)

# Count approximate mistakes
pred_words = predicted.split()
ref_words = reference.split()

matched_words = sum(1 for w in pred_words if w in ref_words)
total_words = len(ref_words)
mistakes = total_words - matched_words if total_words > matched_words else 0

# -------------------------------
# 5️⃣ Print the results
# -------------------------------
print("\n🔹 Reference Text:")
print(reference)
print("\n🔹 Predicted Text:")
print(predicted)
print("\n----------------------------------")
print(f"✅ Similarity Score: {similarity:.2f}%")
print(f"📖 Total Words in Reference: {total_words}")
print(f"✅ Matched Words: {matched_words}")
print(f"❌ Estimated Mistakes: {mistakes}")

# Optional: save comparison summary
with open("comparison_result.txt", "w", encoding="utf-8") as f:
    f.write("Reference Text:\n" + reference + "\n\n")
    f.write("Predicted Text:\n" + predicted + "\n\n")
    f.write(f"Similarity Score: {similarity:.2f}%\n")
    f.write(f"Total Words: {total_words}\nMatched Words: {matched_words}\nMistakes: {mistakes}\n")

print("\n✅ Comparison results saved to 'comparison_result.txt'")
