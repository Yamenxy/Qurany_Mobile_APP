import '../models/recitation_session.dart';

/// Maps a backend `/analyze` JSON payload into a [RecitationSession].
RecitationSession recitationSessionFromAnalysisResult({
  required Map<String, dynamic> result,
  required String id,
  required int surahNumber,
  required String surahName,
  required String mode,
  required int versesRecited,
  String? riwayah,
}) {
  double? readHarakatScore() {
    final raw = result['harakatScore'] ?? result['harakat_score'];
    if (raw == null) return null;
    return (raw as num).toDouble();
  }

  return RecitationSession(
    id: id,
    surahNumber: surahNumber,
    surahName: surahName,
    mode: mode,
    dateTime: DateTime.now(),
    similarityScore: (result['similarity_score'] ?? result['similarityScore'] ?? 0)
        .toDouble(),
    totalWords: result['total_words'] ?? result['totalWords'] ?? 0,
    matchedWords: result['matched_words'] ?? result['matchedWords'] ?? 0,
    mistakes: result['mistakes'] ?? 0,
    versesRecited: versesRecited,
    transcribedText: result['transcribed_text'] ?? result['transcribedText'],
    referenceText: result['reference_text'] ?? result['referenceText'],
    errors: (result['errors'] as List?)
            ?.map((e) => RecitationError.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    harakatScore: readHarakatScore(),
    harakatMistakes:
        result['harakatMistakes'] ?? result['harakat_mistakes'] ?? 0,
    harakatChecked:
        result['harakatChecked'] ?? result['harakat_checked'] ?? 0,
    riwayah: riwayah ?? result['riwayah'] as String?,
    tajweedNotes: _parseTajweedNotes(result),
  );
}

List<TajweedNote> _parseTajweedNotes(Map<String, dynamic> result) {
  final raw = result['tajweedNotes'] ?? result['tajweed_notes'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => TajweedNote.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}
