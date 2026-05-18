class Verse {
  final int surahNumber;
  final int verseNumber;
  final int globalNumber; // Global ayah number (1-6236) for audio URLs
  final String text; // Uthmani script with diacritics
  final String textSimple; // Without diacritics

  const Verse({
    required this.surahNumber,
    required this.verseNumber,
    this.globalNumber = 0,
    required this.text,
    this.textSimple = '',
  });

  /// Husary audio URL for this verse
  String get husaryAudioUrl =>
      'https://cdn.islamic.network/quran/audio/128/ar.husary/$globalNumber.mp3';

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      surahNumber: json['surah']?['number'] ?? json['surahNumber'] ?? 0,
      verseNumber: json['numberInSurah'] ?? json['verseNumber'] ?? 0,
      globalNumber: json['number'] ?? json['globalNumber'] ?? 0,
      text: json['text'] ?? '',
      textSimple: json['textSimple'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'verseNumber': verseNumber,
        'globalNumber': globalNumber,
        'text': text,
        'textSimple': textSimple,
      };
}
