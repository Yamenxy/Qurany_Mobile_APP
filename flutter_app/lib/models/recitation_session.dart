import 'package:uuid/uuid.dart';

import 'sync_metadata.dart';

class RecitationSession {
  final String id;
  final int surahNumber;
  final String surahName;
  final String mode; // 'free' or 'memorization'
  final DateTime dateTime;
  final double similarityScore;
  final int totalWords;
  final int matchedWords;
  final int mistakes;
  final int versesRecited;
  final String? transcribedText;
  final String? referenceText;
  final List<RecitationError> errors;
  final SyncMetadata sync;
  // Harakat (tashkeel) correctness, scored independently from [mistakes]
  // above. Null when nothing was checkable (e.g. the ASR backend in use
  // doesn't output diacritics) -- treat as "not available", not 0.
  final double? harakatScore;
  final int harakatMistakes;
  final int harakatChecked;
  final String? riwayah;
  final List<TajweedNote> tajweedNotes;

  RecitationSession({
    required this.id,
    required this.surahNumber,
    required this.surahName,
    required this.mode,
    required this.dateTime,
    required this.similarityScore,
    required this.totalWords,
    required this.matchedWords,
    required this.mistakes,
    this.versesRecited = 0,
    this.transcribedText,
    this.referenceText,
    this.errors = const [],
    SyncMetadata? sync,
    this.harakatScore,
    this.harakatMistakes = 0,
    this.harakatChecked = 0,
    this.riwayah,
    this.tajweedNotes = const [],
  }) : sync = sync ?? SyncMetadata.fresh();

  RecitationSession copyWith({
    SyncMetadata? sync,
    bool? isDeleted,
    double? harakatScore,
    int? harakatMistakes,
    int? harakatChecked,
    String? riwayah,
    List<TajweedNote>? tajweedNotes,
  }) {
    return RecitationSession(
      id: id,
      surahNumber: surahNumber,
      surahName: surahName,
      mode: mode,
      dateTime: dateTime,
      similarityScore: similarityScore,
      totalWords: totalWords,
      matchedWords: matchedWords,
      mistakes: mistakes,
      versesRecited: versesRecited,
      transcribedText: transcribedText,
      referenceText: referenceText,
      errors: errors,
      sync: sync ?? this.sync.markPending(isDeleted: isDeleted),
      harakatScore: harakatScore ?? this.harakatScore,
      harakatMistakes: harakatMistakes ?? this.harakatMistakes,
      harakatChecked: harakatChecked ?? this.harakatChecked,
      riwayah: riwayah ?? this.riwayah,
      tajweedNotes: tajweedNotes ?? this.tajweedNotes,
    );
  }

  factory RecitationSession.fromJson(Map<String, dynamic> json) {
    return RecitationSession(
      id: json['id'] ?? '',
      surahNumber: json['surahNumber'] ?? 0,
      surahName: json['surahName'] ?? '',
      mode: json['mode'] ?? 'free',
      dateTime: DateTime.parse(
        json['dateTime'] ?? DateTime.now().toIso8601String(),
      ),
      similarityScore: (json['similarityScore'] ?? 0).toDouble(),
      totalWords: json['totalWords'] ?? 0,
      matchedWords: json['matchedWords'] ?? 0,
      mistakes: json['mistakes'] ?? 0,
      versesRecited: json['versesRecited'] ?? 0,
      transcribedText: json['transcribedText'],
      referenceText: json['referenceText'],
      errors: (json['errors'] as List?)
              ?.map((e) => RecitationError.fromJson(e))
              .toList() ??
          [],
      sync: SyncMetadata.fromJson(json),
      harakatScore: json['harakatScore'] == null
          ? null
          : (json['harakatScore'] as num).toDouble(),
      harakatMistakes: json['harakatMistakes'] ?? 0,
      harakatChecked: json['harakatChecked'] ?? 0,
      riwayah: json['riwayah'] as String?,
      tajweedNotes: (json['tajweedNotes'] as List?)
              ?.map((e) => TajweedNote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'surahNumber': surahNumber,
        'surahName': surahName,
        'mode': mode,
        'dateTime': dateTime.toIso8601String(),
        'similarityScore': similarityScore,
        'totalWords': totalWords,
        'matchedWords': matchedWords,
        'mistakes': mistakes,
        'versesRecited': versesRecited,
        'transcribedText': transcribedText,
        'referenceText': referenceText,
        'errors': errors.map((e) => e.toJson()).toList(),
        ...sync.toJson(),
        'harakatScore': harakatScore,
        'harakatMistakes': harakatMistakes,
        'harakatChecked': harakatChecked,
        'riwayah': riwayah,
        'tajweedNotes': tajweedNotes.map((n) => n.toJson()).toList(),
      };
}

class TajweedNote {
  final String type;
  final String expectedWord;
  final int wordIndex;
  final String message;
  final String severity;

  const TajweedNote({
    required this.type,
    required this.expectedWord,
    required this.wordIndex,
    required this.message,
    this.severity = 'warning',
  });

  factory TajweedNote.fromJson(Map<String, dynamic> json) {
    return TajweedNote(
      type: json['type'] ?? '',
      expectedWord: json['expectedWord'] ?? json['expected_word'] ?? '',
      wordIndex: json['wordIndex'] ?? json['word_index'] ?? 0,
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'warning',
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'expectedWord': expectedWord,
        'wordIndex': wordIndex,
        'message': message,
        'severity': severity,
      };

  String get typeArabic {
    switch (type) {
      case 'madd':
        return 'مد';
      case 'ghunnah':
        return 'غنة';
      case 'waqf':
        return 'وقف';
      case 'qalqalah':
        return 'قلقلة';
      default:
        return type;
    }
  }
}

class RecitationError {
  final String type; // 'substitution', 'omission', 'addition', 'sequence', 'harakat'
  final String expectedWord;
  final String recitedWord;
  final int wordIndex;

  const RecitationError({
    required this.type,
    required this.expectedWord,
    required this.recitedWord,
    required this.wordIndex,
  });

  factory RecitationError.fromJson(Map<String, dynamic> json) {
    return RecitationError(
      type: json['type'] ?? '',
      expectedWord: json['expectedWord'] ?? '',
      recitedWord: json['recitedWord'] ?? '',
      wordIndex: json['wordIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'expectedWord': expectedWord,
        'recitedWord': recitedWord,
        'wordIndex': wordIndex,
      };

  String get typeArabic {
    switch (type) {
      case 'substitution':
        return 'استبدال';
      case 'omission':
        return 'حذف';
      case 'addition':
        return 'إضافة';
      case 'sequence':
        return 'ترتيب';
      case 'harakat':
        return 'حركات';
      default:
        return type;
    }
  }
}

class Bookmark {
  final String id;
  final int surahNumber;
  final String surahName;
  final int verseNumber;
  final int? pageNumber;
  final DateTime dateTime;
  final String? note;
  final SyncMetadata sync;

  Bookmark({
    String? id,
    required this.surahNumber,
    required this.surahName,
    required this.verseNumber,
    this.pageNumber,
    required this.dateTime,
    this.note,
    SyncMetadata? sync,
  })  : id = id ?? const Uuid().v4(),
        sync = sync ?? SyncMetadata.fresh();

  Bookmark copyWith({
    String? note,
    DateTime? dateTime,
    SyncMetadata? sync,
  }) {
    return Bookmark(
      id: id,
      surahNumber: surahNumber,
      surahName: surahName,
      verseNumber: verseNumber,
      pageNumber: pageNumber,
      dateTime: dateTime ?? this.dateTime,
      note: note ?? this.note,
      sync: sync ?? this.sync,
    );
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String?,
      surahNumber: json['surahNumber'] ?? 0,
      surahName: json['surahName'] ?? '',
      verseNumber: json['verseNumber'] ?? 0,
      pageNumber: json['pageNumber'],
      dateTime: DateTime.parse(
        json['dateTime'] ?? DateTime.now().toIso8601String(),
      ),
      note: json['note'],
      sync: SyncMetadata.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'surahNumber': surahNumber,
        'surahName': surahName,
        'verseNumber': verseNumber,
        'pageNumber': pageNumber,
        'dateTime': dateTime.toIso8601String(),
        'note': note,
        ...sync.toJson(),
      };
}
