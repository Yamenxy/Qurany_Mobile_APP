import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../models/verse.dart';
import '../../models/recitation_session.dart';
import '../../services/quran_service.dart';
import '../../services/bookmark_service.dart';

class QuranReaderScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const QuranReaderScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  List<Verse> _verses = [];
  bool _isLoading = true;
  String? _error;
  double _fontSize = 28.0;

  @override
  void initState() {
    super.initState();
    _loadVerses();
  }

  Future<void> _loadVerses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final quranService = context.read<QuranService>();
    final verses = await quranService.getSurahVerses(widget.surahNumber);

    if (mounted) {
      setState(() {
        _verses = verses;
        _isLoading = false;
        if (verses.isEmpty) {
          _error = 'فشل تحميل السورة. تأكد من اتصالك بالإنترنت.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarkService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('سورة ${widget.surahName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Font size controls
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: () {
              if (_fontSize > 18) setState(() => _fontSize -= 2);
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: () {
              if (_fontSize < 48) setState(() => _fontSize += 2);
            },
          ),
          // Navigate to recitation
          IconButton(
            icon: const Icon(Icons.mic_rounded),
            tooltip: 'تلاوة هذه السورة',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.recitation, arguments: {
                'surahNumber': widget.surahNumber,
                'surahName': widget.surahName,
                'mode': 'free',
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: QuranyTheme.errorRed),
                      const SizedBox(height: 16),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadVerses,
                          child: const Text('إعادة المحاولة')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Surah header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              QuranyTheme.darkGreen,
                              QuranyTheme.primaryGreen
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'سورة ${widget.surahName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Amiri',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${AppConstants.surahVerseCount[widget.surahNumber - 1]} آية • ${AppConstants.surahRevelationType[widget.surahNumber - 1]}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bismillah (except for Surah At-Tawbah #9)
                      if (widget.surahNumber != 9 && widget.surahNumber != 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                            style: TextStyle(
                              fontSize: _fontSize,
                              fontFamily: 'Amiri',
                              color: QuranyTheme.darkGreen,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                        ),

                      // Verses
                      ..._verses.map((verse) {
                        final isBookmarked = bookmarks.isBookmarked(
                          widget.surahNumber,
                          verse.verseNumber,
                        );

                        return GestureDetector(
                          onLongPress: () {
                            _showVerseOptions(context, verse, isBookmarked);
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isBookmarked
                                  ? QuranyTheme.primaryGold.withValues(alpha: 0.08)
                                  : (verse.verseNumber.isOdd
                                      ? Colors.grey.withValues(alpha: 0.03)
                                      : Colors.transparent),
                              borderRadius: BorderRadius.circular(8),
                              border: isBookmarked
                                  ? Border.all(
                                      color: QuranyTheme.primaryGold
                                          .withValues(alpha: 0.3))
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Verse number badge
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (isBookmarked)
                                      const Icon(
                                        Icons.bookmark,
                                        color: QuranyTheme.primaryGold,
                                        size: 20,
                                      ),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: QuranyTheme.primaryGreen
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${verse.verseNumber}',
                                          style: const TextStyle(
                                            color: QuranyTheme.primaryGreen,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Verse text
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    verse.text,
                                    style: TextStyle(
                                      fontSize: _fontSize,
                                      fontFamily: 'Amiri',
                                      height: 2.0,
                                      color: QuranyTheme.darkGreen,
                                    ),
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 32),

                      // Navigation buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.surahNumber < 114)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.quranReader,
                                  arguments: {
                                    'surahNumber': widget.surahNumber + 1,
                                    'surahName': AppConstants
                                        .surahNames[widget.surahNumber],
                                  },
                                );
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: Text(
                                AppConstants.surahNames[widget.surahNumber],
                              ),
                            ),
                          if (widget.surahNumber > 1)
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.quranReader,
                                  arguments: {
                                    'surahNumber': widget.surahNumber - 1,
                                    'surahName': AppConstants
                                        .surahNames[widget.surahNumber - 2],
                                  },
                                );
                              },
                              icon: const Icon(Icons.arrow_forward),
                              label: Text(
                                AppConstants
                                    .surahNames[widget.surahNumber - 2],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  void _showVerseOptions(
      BuildContext context, Verse verse, bool isBookmarked) {
    final bookmarks = context.read<BookmarkService>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'الآية ${verse.verseNumber} من سورة ${widget.surahName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add,
                  color: QuranyTheme.primaryGold,
                ),
                title: Text(isBookmarked ? 'إزالة العلامة' : 'إضافة علامة'),
                onTap: () {
                  if (isBookmarked) {
                    bookmarks.removeBookmark(
                      widget.surahNumber,
                      verse.verseNumber,
                    );
                  } else {
                    bookmarks.addBookmark(Bookmark(
                      surahNumber: widget.surahNumber,
                      surahName: widget.surahName,
                      verseNumber: verse.verseNumber,
                      dateTime: DateTime.now(),
                    ));
                  }
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: QuranyTheme.primaryGreen),
                title: const Text('نسخ الآية'),
                onTap: () {
                  // Copy to clipboard
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ الآية')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
