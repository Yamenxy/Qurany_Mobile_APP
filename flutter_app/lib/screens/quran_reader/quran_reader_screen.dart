import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../models/verse.dart';
import '../../models/recitation_session.dart';
import '../../models/mushaf_layout.dart';
import '../../services/quran_service.dart';
import '../../services/bookmark_service.dart';
import 'widgets/mushaf_page_widget.dart';

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
  // Standard list state
  List<Verse> _verses = [];
  bool _isLoading = true;
  String? _error;
  double _fontSize = 26.0;

  // Mushaf layout state (Surah Al-Isra)
  List<MushafPage> _mushafPages = [];
  bool _isLayoutLoading = false;
  int _currentPageIndex = 0;
  String _selectedFontFamily = 'QPCHafs';
  int? _selectedWordIndex;
  int? _selectedAyahNumber;

  @override
  void initState() {
    super.initState();
    if (widget.surahNumber == 17) {
      _loadLayoutData();
    } else {
      _loadVerses();
    }
  }

  Future<void> _loadLayoutData() async {
    setState(() {
      _isLayoutLoading = true;
      _isLoading = false;
    });

    try {
      final jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/data/quran_isra_layout.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      final pages = jsonList.map((j) => MushafPage.fromJson(j)).toList();

      setState(() {
        _mushafPages = pages;
        _isLayoutLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLayoutLoading = false;
        _error = 'فشل تحميل بيانات المصحف: $e';
      });
    }
  }

  Future<void> _loadVerses() async {
    setState(() {
      _isLoading = true;
      _isLayoutLoading = false;
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
    final isMushafLayout = widget.surahNumber == 17 && _mushafPages.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('سورة ${widget.surahName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Font family selector (only for Mushaf layout)
          if (isMushafLayout)
            PopupMenuButton<String>(
              icon: const Icon(Icons.font_download_outlined),
              tooltip: 'تغيير الخط',
              onSelected: (String value) {
                setState(() {
                  _selectedFontFamily = value;
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'QPCHafs',
                  child: Text('خط حفص الرسمي (QPC)'),
                ),
                const PopupMenuItem<String>(
                  value: 'KFGQPCNastaleeq',
                  child: Text('خط نستعليق (Nastaleeq)'),
                ),
                const PopupMenuItem<String>(
                  value: 'MeQuran',
                  child: Text('خط مِي المطور (MeQuran)'),
                ),
                const PopupMenuItem<String>(
                  value: 'DigitalKhattV1',
                  child: Text('خط ديجيتال 1 (Digital V1)'),
                ),
                const PopupMenuItem<String>(
                  value: 'DigitalKhattV2',
                  child: Text('خط ديجيتال 2 (Digital V2)'),
                ),
                const PopupMenuItem<String>(
                  value: 'DigitalKhattIndoPak',
                  child: Text('خط ديجيتال إندوباك'),
                ),
                const PopupMenuItem<String>(
                  value: 'IndopakNastaleeq',
                  child: Text('خط نستعليق هندي/باكستاني'),
                ),
              ],
            ),
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
      body: _isLayoutLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: QuranyTheme.errorRed),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: widget.surahNumber == 17 ? _loadLayoutData : _loadVerses,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : isMushafLayout
                  ? _buildMushafLayout()
                  : _buildStandardList(bookmarks),
    );
  }

  Widget _buildMushafLayout() {
    return Column(
      children: [
        // Page metadata header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0D1C0F)
              : QuranyTheme.lightGreen,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'صفحة ${_mushafPages[_currentPageIndex].pageNumber}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: QuranyTheme.primaryGold,
                ),
              ),
              const Text(
                'الجزء الخامس عشر',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Horizontal PageView for pages
        Expanded(
          child: PageView.builder(
            itemCount: _mushafPages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
                _selectedWordIndex = null;
                _selectedAyahNumber = null;
              });
            },
            itemBuilder: (context, index) {
              final page = _mushafPages[index];
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: MushafPageWidget(
                  page: page,
                  fontSize: _fontSize,
                  fontFamily: _selectedFontFamily,
                  selectedWordIndex: _selectedWordIndex,
                  selectedAyahNumber: _selectedAyahNumber,
                  onWordTap: (word) {
                    setState(() {
                      _selectedWordIndex = word.indexInPage;
                      _selectedAyahNumber = word.ayahNumber;
                    });

                    // Reconstruct full Ayah text from page tokens
                    final ayahText = page.lines
                        .expand((l) => l.wordTokens)
                        .where((w) => w.ayahNumber == word.ayahNumber && !w.isAyahMarker)
                        .map((w) => w.text)
                        .join(' ');

                    _showMushafWordOptions(context, word, ayahText);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStandardList(BookmarkService bookmarks) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Surah header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [QuranyTheme.darkGreen, QuranyTheme.primaryGreen],
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
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bismillah
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

          // Linear Verses List
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
                      ? QuranyTheme.primaryGold.withOpacity(0.08)
                      : (verse.verseNumber.isOdd
                          ? Colors.grey.withOpacity(0.03)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                  border: isBookmarked
                      ? Border.all(color: QuranyTheme.primaryGold.withOpacity(0.3))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            color: QuranyTheme.primaryGreen.withOpacity(0.1),
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

          // Bottom navigation
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
                        'surahName': AppConstants.surahNames[widget.surahNumber],
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
                        'surahName': AppConstants.surahNames[widget.surahNumber - 2],
                      },
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    AppConstants.surahNames[widget.surahNumber - 2],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showVerseOptions(BuildContext context, Verse verse, bool isBookmarked) {
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
                  setState(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: QuranyTheme.primaryGreen),
                title: const Text('نسخ الآية'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: verse.text));
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

  void _showMushafWordOptions(BuildContext context, MushafWordToken word, String ayahText) {
    final bookmarks = context.read<BookmarkService>();
    final isBookmarked = bookmarks.isBookmarked(widget.surahNumber, word.ayahNumber);

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الآية ${word.ayahNumber} من سورة ${widget.surahName}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'الكلمة المحددة: ${word.text}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: QuranyTheme.primaryGold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    ayahText,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 20,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add,
                  color: QuranyTheme.primaryGold,
                ),
                title: Text(isBookmarked ? 'إزالة العلامة للآية' : 'إضافة علامة للآية'),
                onTap: () {
                  if (isBookmarked) {
                    bookmarks.removeBookmark(
                      widget.surahNumber,
                      word.ayahNumber,
                    );
                  } else {
                    bookmarks.addBookmark(Bookmark(
                      surahNumber: widget.surahNumber,
                      surahName: widget.surahName,
                      verseNumber: word.ayahNumber,
                      dateTime: DateTime.now(),
                    ));
                  }
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: QuranyTheme.primaryGreen),
                title: const Text('نسخ الآية كاملة'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: ayahText));
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
