import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../models/mushaf_layout.dart';
import '../../../config/theme.dart';

class MushafPageWidget extends StatelessWidget {
  final MushafPage page;
  final double fontSize;
  final String fontFamily;
  final int? selectedWordIndex;
  final int? selectedAyahNumber;
  final Function(MushafWordToken word)? onWordTap;

  const MushafPageWidget({
    super.key,
    required this.page,
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
    final pageBgColor = isDarkMode ? const Color(0xFF1E281F) : QuranyTheme.cream;
    final borderColor = QuranyTheme.primaryGold;
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
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: borderColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor.withOpacity(0.6),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: page.lines.map((line) {
                if (line.isSurahName) {
                  return _buildSurahNameBanner(context, line, bannerBgColor, borderColor);
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
    // Determine Surah Name from text in layout, e.g. "surah017" -> "سُورَةُ الإِسْرَاءِ"
    String surahTitle = "سُورَةُ الإِسْرَاءِ";
    if (line.text.contains("17") || line.text.contains("017")) {
      surahTitle = "سُورَةُ الإِسْرَاءِ";
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
          surahTitle,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: fontSize * 0.9,
            fontWeight: FontWeight.bold,
            color: QuranyTheme.primaryGold,
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
        wordBgColor = QuranyTheme.primaryGold.withOpacity(0.4);
      } else if (isAyahSelected) {
        wordBgColor = QuranyTheme.primaryGold.withOpacity(0.15);
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
            color: word.isAyahMarker ? QuranyTheme.primaryGold : textCol,
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
