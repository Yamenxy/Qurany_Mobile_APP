class MushafWordToken {
  final String text;
  final int ayahNumber;
  final bool isAyahMarker;
  final int indexInPage; // Index of the word on the page (0-based)

  const MushafWordToken({
    required this.text,
    required this.ayahNumber,
    required this.isAyahMarker,
    required this.indexInPage,
  });

  @override
  String toString() => 'MushafWordToken(text: $text, ayah: $ayahNumber, marker: $isAyahMarker, index: $indexInPage)';
}

class MushafLine {
  final int lineNumber;
  final String type; // 'surah_name', 'basmallah', 'ayah'
  final bool centered;
  final String text;
  List<MushafWordToken> wordTokens = [];

  MushafLine({
    required this.lineNumber,
    required this.type,
    required this.centered,
    required this.text,
  });

  bool get isSurahName => type == 'surah_name';
  bool get isBasmallah => type == 'basmallah';
  bool get isAyah => type == 'ayah';

  factory MushafLine.fromJson(Map<String, dynamic> json) {
    return MushafLine(
      lineNumber: json['line_number'] ?? 0,
      type: json['type'] ?? 'ayah',
      centered: json['centered'] ?? false,
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'line_number': lineNumber,
        'type': type,
        'centered': centered,
        'text': text,
      };
}

class MushafPage {
  final int pageNumber;
  final List<MushafLine> lines;

  MushafPage({
    required this.pageNumber,
    required this.lines,
  }) {
    _parseAndGroupWords();
  }

  factory MushafPage.fromJson(Map<String, dynamic> json) {
    final list = json['lines'] as List? ?? [];
    final lines = list.map((l) => MushafLine.fromJson(l)).toList();
    return MushafPage(
      pageNumber: json['page_number'] ?? 0,
      lines: lines,
    );
  }

  static int? _parseArabicIndicInt(String input) {
    final Map<String, String> arabicToLatin = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };
    
    String latinStr = '';
    for (var char in input.runes) {
      final strChar = String.fromCharCode(char);
      latinStr += arabicToLatin[strChar] ?? strChar;
    }
    
    return int.tryParse(latinStr.trim());
  }

  void _parseAndGroupWords() {
    // 1. Find the first end-of-ayah marker in the page to determine the starting Ayah number
    int? firstAyahMarker;
    for (var line in lines) {
      if (line.type != 'ayah') continue;
      final tokens = line.text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
      for (var token in tokens) {
        if (token.contains('۝')) {
          final numStr = token.replaceAll('۝', '').trim();
          final num = _parseArabicIndicInt(numStr);
          if (num != null) {
            firstAyahMarker = num;
            break;
          }
        }
      }
      if (firstAyahMarker != null) break;
    }

    int currentAyah = firstAyahMarker ?? 1;
    int pageWordCounter = 0;

    // 2. Parse all lines and assign the ayah number and word index to each word
    for (var line in lines) {
      if (line.type == 'surah_name' || line.type == 'basmallah') {
        line.wordTokens = [];
        continue;
      }

      final tokens = line.text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      final List<MushafWordToken> lineTokens = [];

      for (var token in tokens) {
        final isMarker = token.contains('۝');
        int wordAyah = currentAyah;

        if (isMarker) {
          final numStr = token.replaceAll('۝', '').trim();
          final num = _parseArabicIndicInt(numStr);
          if (num != null) {
            wordAyah = num;
            currentAyah = num + 1;
          }
        }

        lineTokens.add(MushafWordToken(
          text: token,
          ayahNumber: wordAyah,
          isAyahMarker: isMarker,
          indexInPage: pageWordCounter++,
        ));
      }
      line.wordTokens = lineTokens;
    }
  }
}
