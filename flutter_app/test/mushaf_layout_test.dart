import 'package:flutter_test/flutter_test.dart';
import 'package:qurany_app/models/mushaf_layout.dart';

void main() {
  group('MushafLayout Parsing Tests', () {
    test('Should parse page and lines correctly', () {
      final jsonMap = {
        'page_number': 282,
        'lines': [
          {
            'line_number': 1,
            'type': 'surah_name',
            'centered': true,
            'text': 'surah017'
          },
          {
            'line_number': 2,
            'type': 'basmallah',
            'centered': true,
            'text': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'
          },
          {
            'line_number': 3,
            'type': 'ayah',
            'centered': false,
            'text': 'سُبْحَانَ الَّذِي أَسْرَىٰ بِعَبْدِهِ لَيْلًا'
          },
          {
            'line_number': 4,
            'type': 'ayah',
            'centered': false,
            'text': 'مِنَ الْمَسْجِدِ ۝١ وَآتَيْنَا مُوسَى'
          }
        ]
      };

      final page = MushafPage.fromJson(jsonMap);

      expect(page.pageNumber, 282);
      expect(page.lines.length, 4);

      // Verify line types
      expect(page.lines[0].isSurahName, true);
      expect(page.lines[1].isBasmallah, true);
      expect(page.lines[2].isAyah, true);

      // Verify word token counting and index sequencing
      expect(page.lines[2].wordTokens.length, 5); // سُبْحَانَ الَّذِي أَسْرَىٰ بِعَبْدِهِ لَيْلًا
      expect(page.lines[3].wordTokens.length, 5); // مِنَ الْمَسْجِدِ ۝١ وَآتَيْنَا مُوسَى

      // Verify Ayah assignment
      // Line 3 words are before ۝١, so they should be Ayah 1
      expect(page.lines[2].wordTokens[0].ayahNumber, 1);
      expect(page.lines[2].wordTokens[0].text, 'سُبْحَانَ');
      expect(page.lines[2].wordTokens[0].indexInPage, 0);

      // Line 4 has ۝١ marker and subsequent words
      expect(page.lines[3].wordTokens[0].text, 'مِنَ');
      expect(page.lines[3].wordTokens[0].ayahNumber, 1);
      expect(page.lines[3].wordTokens[0].indexInPage, 5);

      expect(page.lines[3].wordTokens[2].text, '۝١');
      expect(page.lines[3].wordTokens[2].isAyahMarker, true);
      expect(page.lines[3].wordTokens[2].ayahNumber, 1);

      // Subsequent words after ۝١ should belong to Ayah 2
      expect(page.lines[3].wordTokens[3].text, 'وَآتَيْنَا');
      expect(page.lines[3].wordTokens[3].ayahNumber, 2);
      expect(page.lines[3].wordTokens[3].indexInPage, 8);
    });
  });
}
