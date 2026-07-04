/// Recitation mode identifiers used across the app.
class RecitationModes {
  RecitationModes._();

  /// On-device live STT + local word matching (Flutter only).
  static const liveFree = 'free';
  static const liveMemorization = 'memorization';
  static const liveTahfeez = 'tahfeez';
  static const liveTasmee3 = 'tasmee3';

  /// Record audio then analyze on the FastAPI backend (Whisper + harakat + qira'a).
  static const aiAnalysis = 'ai_analysis';

  static bool isLiveMode(String mode) =>
      mode == liveFree ||
      mode == liveMemorization ||
      mode == liveTahfeez ||
      mode == liveTasmee3;

  static bool isAiAnalysisMode(String mode) => mode == aiAnalysis;
}
