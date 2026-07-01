import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/mushaf_pages.dart';
import '../../config/theme.dart';
import '../../models/mushaf_layout.dart';
import '../../services/mushaf_layout_service.dart';
import '../../widgets/app_icons.dart';
import 'widgets/mushaf_page_widget.dart';

/// Full 604-page Mushaf reader. Pages are fetched lazily via
/// [MushafLayoutService] as the user swipes, with in-memory + on-disk
/// caching so re-visiting a page (or reopening the app) doesn't require a
/// fresh network round-trip every time.
class MushafReaderScreen extends StatefulWidget {
  /// 1-indexed mushaf page (1..604) to open on. Takes precedence over
  /// [surahNumber] when both are provided.
  final int? initialPage;

  /// If [initialPage] isn't provided, opens on this Surah's first page.
  final int? surahNumber;

  const MushafReaderScreen({super.key, this.initialPage, this.surahNumber});

  @override
  State<MushafReaderScreen> createState() => _MushafReaderScreenState();
}

class _MushafReaderScreenState extends State<MushafReaderScreen> {
  final MushafLayoutService _service = MushafLayoutService();
  late final PageController _pageController;
  late int _currentPage;
  // Slightly smaller than a "print-perfect" size so that fonts with wider
  // natural letterforms (e.g. MeQuran, Nastaleeq) have enough headroom to
  // fit real mushaf lines on narrower phones without needing to shrink.
  double _fontSize = 19.0;
  String _selectedFontFamily = 'QPCHafs';
  String? _selectedVerseKey;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage ??
        (widget.surahNumber != null
            ? MushafPageIndex.firstPage(widget.surahNumber!)
            : 1);
    _pageController = PageController(initialPage: _currentPage - 1);
    _service.prefetchAround(_currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuranyTheme.background,
      appBar: AppBar(
        title: Text('صفحة $_currentPage'),
        leading: AppIcons.backButton(context: context),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.font_download_outlined),
            tooltip: 'تغيير الخط',
            onSelected: (value) => setState(() => _selectedFontFamily = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'QPCHafs', child: Text('حفص (QPC)')),
              PopupMenuItem(
                  value: 'KFGQPCNastaleeq', child: Text('نستعليق')),
              PopupMenuItem(value: 'MeQuran', child: Text('MeQuran')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease),
            tooltip: 'تصغير الخط',
            onPressed: () {
              if (_fontSize > 14) setState(() => _fontSize -= 2);
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            tooltip: 'تكبير الخط',
            onPressed: () {
              if (_fontSize < 34) setState(() => _fontSize += 2);
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: MushafPageIndex.totalPages,
        onPageChanged: (index) {
          final pageNumber = index + 1;
          setState(() {
            _currentPage = pageNumber;
            _selectedVerseKey = null;
          });
          _service.prefetchAround(pageNumber);
        },
        itemBuilder: (context, index) {
          final pageNumber = index + 1;
          return FutureBuilder<MushafPage>(
            future: _service.loadPage(pageNumber),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: QuranyTheme.errorRed),
                      const SizedBox(height: 12),
                      const Text(
                        'تعذر تحميل الصفحة. تأكد من اتصالك بالإنترنت.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              final page = snapshot.data!;
              return LayoutBuilder(
                builder: (context, viewportConstraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewportConstraints.maxHeight,
                      ),
                      child: MushafPageWidget(
                        page: page,
                        fontSize: _fontSize,
                        fontFamily: _selectedFontFamily,
                        selectedVerseKey: _selectedVerseKey,
                        onWordTap: (word) => _onWordTap(page, word),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _onWordTap(MushafPage page, MushafWord word) {
    setState(() => _selectedVerseKey = word.verseKey);

    final ayahText = page.lines
        .expand((l) => l.ayahGroups)
        .where((g) => g.verseKey == word.verseKey)
        .expand((g) => g.words)
        .where((w) => !w.isAyahMarker)
        .map((w) => w.text)
        .join(' ');

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
              Text(
                'الآية ${word.verseKey}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    ayahText,
                    style: const TextStyle(
                      fontFamily: 'QPCHafs',
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
                leading: const Icon(Icons.copy, color: QuranyTheme.primaryGreen),
                title: const Text('نسخ الآية'),
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
