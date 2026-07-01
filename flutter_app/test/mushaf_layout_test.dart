import 'package:flutter_test/flutter_test.dart';
import 'package:qurany_app/models/mushaf_layout.dart';

void main() {
  group('MushafPage.fromQuranApiJson', () {
    // Simulates the shape returned by
    // GET /verses/by_page/282?words=true&word_fields=text_uthmani,line_number,char_type_name,position&mushaf=2
    // for the start of Surah Al-Isra (17), whose first ayah line is line 3.
    final israFixture = {
      'verses': [
        {
          'verse_key': '17:1',
          'verse_number': 1,
          'words': [
            {
              'id': 1,
              'text_uthmani': 'سُبْحَانَ',
              'line_number': 3,
              'char_type_name': 'word',
              'position': 1,
            },
            {
              'id': 2,
              'text_uthmani': 'الَّذِي',
              'line_number': 3,
              'char_type_name': 'word',
              'position': 2,
            },
            {
              'id': 3,
              'text_uthmani': '١',
              'line_number': 3,
              'char_type_name': 'end',
              'position': 3,
            },
          ],
        },
        {
          'verse_key': '17:2',
          'verse_number': 2,
          'words': [
            {
              'id': 4,
              'text_uthmani': 'وَآتَيْنَا',
              'line_number': 3,
              'char_type_name': 'word',
              'position': 1,
            },
            {
              'id': 5,
              'text_uthmani': 'مُوسَى',
              'line_number': 4,
              'char_type_name': 'word',
              'position': 2,
            },
          ],
        },
      ],
    };

    test('synthesizes surah-name and basmallah lines before the first ayah',
        () {
      final page = MushafPage.fromQuranApiJson(282, israFixture);

      final surahNameLine = page.lines.firstWhere((l) => l.isSurahName);
      final basmallahLine = page.lines.firstWhere((l) => l.isBasmallah);

      expect(surahNameLine.lineNumber, 1);
      expect(surahNameLine.surahNumber, 17);
      expect(basmallahLine.lineNumber, 2);
    });

    test('groups consecutive same-ayah words within a line', () {
      final page = MushafPage.fromQuranApiJson(282, israFixture);
      final line3 = page.lines.firstWhere((l) => l.lineNumber == 3);

      expect(line3.isAyah, true);
      expect(line3.ayahGroups.length, 2);

      expect(line3.ayahGroups[0].verseKey, '17:1');
      expect(line3.ayahGroups[0].words.length, 3);
      expect(line3.ayahGroups[0].words.last.isAyahMarker, true);

      expect(line3.ayahGroups[1].verseKey, '17:2');
      expect(line3.ayahGroups[1].words.length, 1);
      expect(line3.ayahGroups[1].words.first.text, 'وَآتَيْنَا');
    });

    test('splits an ayah spanning multiple lines correctly', () {
      final page = MushafPage.fromQuranApiJson(282, israFixture);
      final line4 = page.lines.firstWhere((l) => l.lineNumber == 4);

      expect(line4.isAyah, true);
      expect(line4.ayahGroups.length, 1);
      expect(line4.ayahGroups.single.verseKey, '17:2');
      expect(line4.ayahGroups.single.words.single.text, 'مُوسَى');
    });

    test('skips basmallah synthesis for Al-Fatihah', () {
      final fatihaFixture = {
        'verses': [
          {
            'verse_key': '1:1',
            'verse_number': 1,
            'words': [
              {
                'id': 1,
                'text_uthmani': 'بِسْمِ',
                'line_number': 2,
                'char_type_name': 'word',
                'position': 1,
              },
            ],
          },
        ],
      };

      final page = MushafPage.fromQuranApiJson(1, fatihaFixture);

      expect(page.lines.where((l) => l.isBasmallah), isEmpty);
      expect(page.lines.firstWhere((l) => l.isSurahName).lineNumber, 1);
      expect(page.lines.firstWhere((l) => l.isSurahName).surahNumber, 1);
    });

    test('skips basmallah synthesis for At-Tawbah', () {
      final tawbahFixture = {
        'verses': [
          {
            'verse_key': '9:1',
            'verse_number': 1,
            'words': [
              {
                'id': 1,
                'text_uthmani': 'بَرَاءَةٌ',
                'line_number': 2,
                'char_type_name': 'word',
                'position': 1,
              },
            ],
          },
        ],
      };

      final page = MushafPage.fromQuranApiJson(187, tawbahFixture);

      expect(page.lines.where((l) => l.isBasmallah), isEmpty);
      expect(page.lines.firstWhere((l) => l.isSurahName).surahNumber, 9);
    });

    test('leaves lines with no data blank', () {
      final page = MushafPage.fromQuranApiJson(282, israFixture);
      final lineNumbers = page.lines.map((l) => l.lineNumber).toSet();

      // Only lines 1-4 have data in this fixture; 5-15 should be absent.
      expect(lineNumbers, {1, 2, 3, 4});
    });
  });
}
