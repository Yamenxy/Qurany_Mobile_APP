import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurany_app/models/mushaf_layout.dart';
import 'package:qurany_app/screens/mushaf_reader/widgets/mushaf_page_widget.dart';

MushafWord _word(int id, String text, {String verseKey = '2:1'}) {
  return MushafWord(
    id: id,
    text: text,
    verseKey: verseKey,
    positionInVerse: id,
    isAyahMarker: false,
  );
}

/// Pumps [page] inside the same LayoutBuilder + SingleChildScrollView +
/// ConstrainedBox(minHeight) wrapper that `mushaf_reader_screen.dart` uses,
/// with the test surface itself sized to [width]x[height] so the Scaffold
/// body (and therefore the viewport constraints MushafPageWidget sees)
/// exactly match those dimensions instead of being clamped by the default
/// 800x600 test surface.
Future<void> _pumpPage(
  WidgetTester tester, {
  required MushafPage page,
  required double width,
  required double height,
  double fontSize = 22,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LayoutBuilder(
          builder: (context, viewportConstraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: viewportConstraints.maxHeight),
                child: MushafPageWidget(
                  page: page,
                  fontSize: fontSize,
                  fontFamily: 'QPCHafs',
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'a dense but realistic ayah line (12 short words) does not overflow '
    'a narrow phone width',
    (tester) async {
      // Real mushaf lines rarely exceed ~10-12 words even when packed with
      // short words; this is a realistic worst case for a narrow screen.
      final words = List.generate(12, (i) => _word(i, 'وَمِنْ'));
      final page = MushafPage(
        pageNumber: 1,
        lines: [
          MushafLine(
            lineNumber: 5,
            type: MushafLineType.ayah,
            ayahGroups: [MushafAyahGroup(verseKey: '2:1', words: words)],
          ),
        ],
      );

      await _pumpPage(tester, page: page, width: 360, height: 800);
      await tester.pumpAndSettle();

      // If the line overflowed, pumpWidget/pumpAndSettle would surface the
      // RenderFlex overflow assertion as a test failure.
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a normal line renders at exactly the requested font size, unaffected '
    'by unrelated dense lines elsewhere on the page',
    (tester) async {
      const baseFontSize = 22.0;
      final page = MushafPage(
        pageNumber: 1,
        lines: [
          // A dense line that needs shrinking to fit...
          MushafLine(
            lineNumber: 3,
            type: MushafLineType.ayah,
            ayahGroups: [
              MushafAyahGroup(
                verseKey: '2:1',
                words: List.generate(12, (i) => _word(i, 'وَمِنْ')),
              ),
            ],
          ),
          // ...shouldn't affect this normal, short line's font size.
          MushafLine(
            lineNumber: 4,
            type: MushafLineType.ayah,
            ayahGroups: [
              MushafAyahGroup(
                verseKey: '2:2',
                words: [_word(100, 'بِسْمِ'), _word(101, 'اللَّهِ')],
              ),
            ],
          ),
        ],
      );

      await _pumpPage(
        tester,
        page: page,
        width: 360,
        height: 800,
        fontSize: baseFontSize,
      );
      await tester.pumpAndSettle();

      final normalWordText =
          tester.widget<Text>(find.text('بِسْمِ'));
      expect(normalWordText.style?.fontSize, baseFontSize);
    },
  );

  testWidgets(
    'a short page (fewer than 15 lines) is vertically centered',
    (tester) async {
      final page = MushafPage(
        pageNumber: 1,
        lines: [
          MushafLine(
            lineNumber: 5,
            type: MushafLineType.ayah,
            ayahGroups: [
              MushafAyahGroup(verseKey: '1:1', words: [_word(1, 'بِسْمِ')]),
            ],
          ),
          MushafLine(
            lineNumber: 6,
            type: MushafLineType.ayah,
            ayahGroups: [
              MushafAyahGroup(verseKey: '1:2', words: [_word(2, 'الْحَمْدُ')]),
            ],
          ),
        ],
      );

      const viewportHeight = 800.0;
      await _pumpPage(
        tester,
        page: page,
        width: 360,
        height: viewportHeight,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final columnFinder = find.byKey(const ValueKey('mushafPageColumn'));
      final contentTop = tester.getTopLeft(columnFinder).dy;
      final contentBottom = tester.getBottomLeft(columnFinder).dy;
      final topGap = contentTop;
      final bottomGap = viewportHeight - contentBottom;

      // Centered means the leftover space above and below the content block
      // should be roughly equal (well within half the content's own height).
      expect((topGap - bottomGap).abs(), lessThan(20));
    },
  );

  testWidgets(
    'a full 15-line page stretches edge-to-edge instead of centering',
    (tester) async {
      final lines = List.generate(
        15,
        (i) => MushafLine(
          lineNumber: i + 1,
          type: MushafLineType.ayah,
          ayahGroups: [
            MushafAyahGroup(verseKey: '2:1', words: [_word(i, 'كلمة')]),
          ],
        ),
      );
      final page = MushafPage(pageNumber: 2, lines: lines);

      const viewportHeight = 800.0;
      await _pumpPage(
        tester,
        page: page,
        width: 360,
        height: viewportHeight,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final columnFinder = find.byKey(const ValueKey('mushafPageColumn'));
      final contentTop = tester.getTopLeft(columnFinder).dy;
      final contentBottom = tester.getBottomLeft(columnFinder).dy;
      final topGap = contentTop;
      final bottomGap = viewportHeight - contentBottom;

      // A full page should stretch to (roughly) fill the viewport, so the
      // gaps above/below should both be small, not just equal to each other.
      expect(topGap, lessThan(20));
      expect(bottomGap, lessThan(20));
    },
  );
}
