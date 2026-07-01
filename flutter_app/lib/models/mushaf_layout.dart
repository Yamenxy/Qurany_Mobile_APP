import '../config/mushaf_pages.dart';

/// The three line kinds that appear on a mushaf page, matching QUL/Quran.com's
/// `line--surah-name`, `line--bismillah` and default ayah line types.
enum MushafLineType { surahName, basmallah, ayah }

/// A single word (or end-of-ayah marker) on the page. This is the leaf of the
/// Page -> Line -> Ayah -> Word hierarchy.
class MushafWord {
  final int id;
  final String text;
  final String verseKey;
  final int positionInVerse;
  final bool isAyahMarker;

  const MushafWord({
    required this.id,
    required this.text,
    required this.verseKey,
    required this.positionInVerse,
    required this.isAyahMarker,
  });

  int get surahNumber => int.parse(verseKey.split(':')[0]);
  int get ayahNumber => int.parse(verseKey.split(':')[1]);

  factory MushafWord.fromApiJson(
    Map<String, dynamic> json, {
    required String verseKey,
  }) {
    return MushafWord(
      id: json['id'] as int,
      text: (json['text_uthmani'] as String?)?.trim() ?? '',
      verseKey: verseKey,
      positionInVerse: json['position'] as int? ?? 0,
      isAyahMarker: json['char_type_name'] != 'word',
    );
  }
}

/// Groups the consecutive words belonging to the same Ayah within a single
/// line, mirroring `.ayah-container > .ayah` in the reference HTML.
class MushafAyahGroup {
  final String verseKey;
  final List<MushafWord> words;

  const MushafAyahGroup({required this.verseKey, required this.words});

  int get surahNumber => int.parse(verseKey.split(':')[0]);
  int get ayahNumber => int.parse(verseKey.split(':')[1]);
}

/// A single line on the page, mirroring `.line-container > .line`.
class MushafLine {
  final int lineNumber;
  final MushafLineType type;

  /// Populated only for [MushafLineType.surahName] lines.
  final int? surahNumber;

  /// Populated only for [MushafLineType.ayah] lines.
  final List<MushafAyahGroup> ayahGroups;

  const MushafLine({
    required this.lineNumber,
    required this.type,
    this.surahNumber,
    this.ayahGroups = const [],
  });

  bool get isSurahName => type == MushafLineType.surahName;
  bool get isBasmallah => type == MushafLineType.basmallah;
  bool get isAyah => type == MushafLineType.ayah;

  List<MushafWord> get words => ayahGroups.expand((g) => g.words).toList();
}

/// A full mushaf page: Page -> Line -> Ayah -> Word.
class MushafPage {
  final int pageNumber;
  final List<MushafLine> lines;

  const MushafPage({required this.pageNumber, required this.lines});

  /// Builds a [MushafPage] from the Quran.com API v4 response shape:
  /// `GET /verses/by_page/{page}?words=true&word_fields=text_uthmani,line_number,char_type_name,position&mushaf=2`
  ///
  /// The public API doesn't expose synthetic Surah-name/Basmallah lines
  /// directly (those aren't verses), so this reconstructs them: whenever a
  /// verse numbered 1 appears on the page, the two lines immediately before
  /// its first word are treated as the Surah-name banner and the Basmallah
  /// (except for Al-Fatihah and At-Tawbah, see [MushafPageIndex.hasBasmallah]).
  factory MushafPage.fromQuranApiJson(
    int pageNumber,
    Map<String, dynamic> json,
  ) {
    final verses = (json['verses'] as List?) ?? const [];

    final Map<int, List<MushafWord>> wordsByLine = {};
    final Map<int, int> firstAyahLineOfNewSurah = {};

    for (final verseJson in verses) {
      final verse = verseJson as Map<String, dynamic>;
      final verseKey = verse['verse_key'] as String;
      final verseNumber = verse['verse_number'] as int;
      final surahNumber = int.parse(verseKey.split(':')[0]);
      final words = (verse['words'] as List?) ?? const [];

      for (final wordJson in words) {
        final word = MushafWord.fromApiJson(
          wordJson as Map<String, dynamic>,
          verseKey: verseKey,
        );
        final lineNumber = wordJson['line_number'] as int;
        wordsByLine.putIfAbsent(lineNumber, () => []).add(word);

        if (verseNumber == 1 &&
            !firstAyahLineOfNewSurah.containsKey(surahNumber)) {
          firstAyahLineOfNewSurah[surahNumber] = lineNumber;
        }
      }
    }

    final Map<int, int> surahNameLines = {};
    final Set<int> basmallahLines = {};

    firstAyahLineOfNewSurah.forEach((surahNumber, firstAyahLine) {
      if (MushafPageIndex.hasBasmallah(surahNumber)) {
        surahNameLines[firstAyahLine - 2] = surahNumber;
        basmallahLines.add(firstAyahLine - 1);
      } else {
        surahNameLines[firstAyahLine - 1] = surahNumber;
      }
    });

    final lines = <MushafLine>[];
    for (var lineNumber = 1;
        lineNumber <= MushafPageIndex.linesPerPage;
        lineNumber++) {
      if (surahNameLines.containsKey(lineNumber)) {
        lines.add(MushafLine(
          lineNumber: lineNumber,
          type: MushafLineType.surahName,
          surahNumber: surahNameLines[lineNumber],
        ));
      } else if (basmallahLines.contains(lineNumber)) {
        lines.add(MushafLine(
          lineNumber: lineNumber,
          type: MushafLineType.basmallah,
        ));
      } else if (wordsByLine.containsKey(lineNumber)) {
        lines.add(MushafLine(
          lineNumber: lineNumber,
          type: MushafLineType.ayah,
          ayahGroups: _groupByAyah(wordsByLine[lineNumber]!),
        ));
      }
      // Any other line number has no data on this page and is left blank.
    }

    return MushafPage(pageNumber: pageNumber, lines: lines);
  }

  static List<MushafAyahGroup> _groupByAyah(List<MushafWord> words) {
    final groups = <MushafAyahGroup>[];
    for (final word in words) {
      if (groups.isNotEmpty && groups.last.verseKey == word.verseKey) {
        groups.last.words.add(word);
      } else {
        groups.add(MushafAyahGroup(verseKey: word.verseKey, words: [word]));
      }
    }
    return groups;
  }
}
