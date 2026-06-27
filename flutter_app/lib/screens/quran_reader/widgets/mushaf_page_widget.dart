import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../models/mushaf_layout.dart';
import '../../../config/theme.dart';

class MushafPageWidget extends StatelessWidget {
  final MushafPage page;
  final String? surahTitle;
  final double fontSize;
  final String fontFamily;
  final int? selectedWordIndex;
  final int? selectedAyahNumber;
  final Function(MushafWordToken word)? onWordTap;

  const MushafPageWidget({
    super.key,
    required this.page,
    this.surahTitle,
    required this.fontSize,
    required this.fontFamily,
    this.selectedWordIndex,
    this.selectedAyahNumber,
    this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Choose colors based on theme
    final pageBgColor = isDarkMode ? const Color(0xFF1E281F) : QuranyTheme.section;
    final borderColor = QuranyTheme.primary;
    final textColor = isDarkMode ? const Color(0xFFF1F1F1) : QuranyTheme.darkGreen;
    final bannerBgColor = isDarkMode ? const Color(0xFF0D1C0F) : QuranyTheme.lightGreen;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: pageBgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: QuranyTheme.shadow,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: borderColor.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: page.lines.map((line) {
                if (line.isSurahName) {
                  return _buildSurahNameBanner(
                    context,
                    line,
                    bannerBgColor,
                    borderColor,
                  );
                } else if (line.isBasmallah) {
                  return _buildBasmallah(context, line, textColor);
                } else {
                  return _buildQuranLine(context, line, textColor);
                }
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahNameBanner(
    BuildContext context,
    MushafLine line,
    Color bannerBg,
    Color borderCol,
  ) {
    // Prefer explicit surah title; fall back to layout line text.
    String title = surahTitle ?? line.text;
    if (title.startsWith('surah')) {
      title = 'سُورَةُ الإِسْرَاءِ';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderCol,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize * 0.9,
            fontWeight: FontWeight.bold,
            color: QuranyTheme.primary,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildBasmallah(BuildContext context, MushafLine line, Color textCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Text(
          line.text,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize * 0.85,
            color: textCol,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildQuranLine(BuildContext context, MushafLine line, Color textCol) {
    // Group words of the line by Ayah number
    final Map<int, List<MushafWordToken>> ayahGroups = {};
    for (var word in line.wordTokens) {
      ayahGroups.putIfAbsent(word.ayahNumber, () => []).add(word);
    }

    // Build lists of TextSpans for each Ayah group
    final List<TextSpan> lineSpans = [];

    // To keep spacing correct, we build words in order
    for (var i = 0; i < line.wordTokens.length; i++) {
      final word = line.wordTokens[i];
      final isLastWord = i == line.wordTokens.length - 1;

      // Styling details
      final isWordSelected = selectedWordIndex == word.indexInPage;
      final isAyahSelected = selectedAyahNumber == word.ayahNumber;

      Color? wordBgColor;
      if (isWordSelected) {
        wordBgColor = QuranyTheme.primary.withValues(alpha: 0.22);
      } else if (isAyahSelected) {
        wordBgColor = QuranyTheme.accent.withValues(alpha: 0.18);
      }

      // Add a tap recognizer
      TapGestureRecognizer? recognizer;
      if (onWordTap != null) {
        recognizer = TapGestureRecognizer()..onTap = () => onWordTap!(word);
      }

      lineSpans.add(
        TextSpan(
          text: word.text + (isLastWord ? '' : ' '),
          recognizer: recognizer,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize,
            color: word.isAyahMarker ? QuranyTheme.accent : textCol,
            fontWeight: word.isAyahMarker ? FontWeight.bold : FontWeight.normal,
            backgroundColor: wordBgColor,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        textAlign: line.centered ? TextAlign.center : TextAlign.justify,
        textDirection: TextDirection.rtl,
        text: TextSpan(
          children: lineSpans,
        ),
      ),
    );
  }
}
