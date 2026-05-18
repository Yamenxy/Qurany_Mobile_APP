import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/recitation_session.dart';

class RecitationResultScreen extends StatefulWidget {
  final Map<String, dynamic> resultData;

  const RecitationResultScreen({super.key, required this.resultData});

  @override
  State<RecitationResultScreen> createState() => _RecitationResultScreenState();
}

class _RecitationResultScreenState extends State<RecitationResultScreen>
    with SingleTickerProviderStateMixin {
  late final RecitationSession session;
  late final TabController _tabController;
  late final List<_DiffWord> _diffWords;

  @override
  void initState() {
    super.initState();
    session = RecitationSession.fromJson(widget.resultData);
    _tabController = TabController(length: 3, vsync: this);
    _diffWords = _buildDiffWords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Build a word-by-word diff between reference and transcribed text
  List<_DiffWord> _buildDiffWords() {
    final refText = session.referenceText ?? '';
    final transText = session.transcribedText ?? '';
    if (refText.isEmpty) return [];

    final refWords = refText.split(RegExp(r'\s+'));
    final transWords = transText.split(RegExp(r'\s+'));

    // Create a set of error indices for quick lookup
    final errorMap = <int, RecitationError>{};
    for (final err in session.errors) {
      errorMap[err.wordIndex] = err;
    }

    final result = <_DiffWord>[];
    int ti = 0;

    for (int ri = 0; ri < refWords.length; ri++) {
      if (errorMap.containsKey(ri)) {
        final err = errorMap[ri]!;
        result.add(_DiffWord(
          referenceWord: refWords[ri],
          recitedWord: err.recitedWord.isNotEmpty ? err.recitedWord : null,
          status: _wordStatusFromError(err.type),
          errorType: err.type,
        ));
        if (err.type != 'omission') ti++;
      } else {
        result.add(_DiffWord(
          referenceWord: refWords[ri],
          recitedWord: ti < transWords.length ? transWords[ti] : null,
          status: _DiffStatus.correct,
        ));
        ti++;
      }
    }

    return result;
  }

  _DiffStatus _wordStatusFromError(String type) {
    switch (type) {
      case 'substitution':
        return _DiffStatus.substitution;
      case 'omission':
        return _DiffStatus.omission;
      case 'addition':
        return _DiffStatus.addition;
      case 'sequence':
        return _DiffStatus.sequence;
      default:
        return _DiffStatus.substitution;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = session.similarityScore >= 85
        ? QuranyTheme.correctGreen
        : session.similarityScore >= 70
            ? QuranyTheme.warningOrange
            : QuranyTheme.errorRed;

    final scoreLabel = session.similarityScore >= 85
        ? 'ممتاز!'
        : session.similarityScore >= 70
            ? 'جيد'
            : 'يحتاج تحسين';

    final scoreEmoji = session.similarityScore >= 85
        ? '🌟'
        : session.similarityScore >= 70
            ? '👍'
            : '💪';

    return Scaffold(
      appBar: AppBar(
        title: const Text('نتيجة التلاوة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Score Header
          _buildScoreHeader(scoreColor, scoreLabel, scoreEmoji),

          // Tab bar
          Container(
            color: scoreColor.withValues(alpha: 0.05),
            child: TabBar(
              controller: _tabController,
              labelColor: QuranyTheme.darkGreen,
              unselectedLabelColor: Colors.grey,
              indicatorColor: QuranyTheme.primaryGreen,
              tabs: const [
                Tab(text: 'النص المُقارن', icon: Icon(Icons.compare_arrows, size: 18)),
                Tab(text: 'الأخطاء', icon: Icon(Icons.error_outline, size: 18)),
                Tab(text: 'الإحصائيات', icon: Icon(Icons.bar_chart, size: 18)),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextComparisonTab(),
                _buildErrorsTab(),
                _buildStatsTab(scoreColor),
              ],
            ),
          ),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  // ─── Score Header ───
  Widget _buildScoreHeader(Color scoreColor, String scoreLabel, String scoreEmoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.12),
            scoreColor.withValues(alpha: 0.04),
          ],
        ),
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor, width: 3),
              color: Colors.white,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${session.similarityScore.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    'دقة',
                    style: TextStyle(
                      fontSize: 11,
                      color: scoreColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$scoreEmoji $scoreLabel',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'سورة ${session.surahName}',
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _miniStat(Icons.check_circle, '${session.matchedWords} صحيح', QuranyTheme.correctGreen),
                    const SizedBox(width: 12),
                    _miniStat(Icons.cancel, '${session.mistakes} خطأ', QuranyTheme.errorRed),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ─── Tab 1: Text Comparison (Tarteel-style word-by-word) ───
  Widget _buildTextComparisonTab() {
    if (_diffWords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.text_fields, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('لا يوجد نص للمقارنة', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Legend
          _buildColorLegend(),
          const SizedBox(height: 16),

          // Word-by-word comparison
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: QuranyTheme.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: QuranyTheme.primaryGold.withValues(alpha: 0.3)),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              textDirection: TextDirection.rtl,
              spacing: 4,
              runSpacing: 8,
              children: _diffWords.map((w) => _buildDiffWordWidget(w)).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Transcribed text section
          if (session.transcribedText != null && session.transcribedText!.isNotEmpty) ...[
            const Text(
              'نص التلاوة المُسجل',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: QuranyTheme.darkGreen,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Text(
                session.transcribedText!,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Amiri',
                  height: 2.0,
                  color: QuranyTheme.darkGreen,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColorLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem('صحيح', QuranyTheme.correctGreen, Icons.check_circle),
          _legendItem('استبدال', QuranyTheme.errorRed, Icons.swap_horiz),
          _legendItem('حذف', QuranyTheme.warningOrange, Icons.remove_circle_outline),
          _legendItem('إضافة', Colors.blue, Icons.add_circle_outline),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDiffWordWidget(_DiffWord diff) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (diff.status) {
      case _DiffStatus.correct:
        bgColor = QuranyTheme.correctGreen.withValues(alpha: 0.12);
        textColor = QuranyTheme.correctGreen;
        borderColor = QuranyTheme.correctGreen.withValues(alpha: 0.3);
        break;
      case _DiffStatus.substitution:
        bgColor = QuranyTheme.errorRed.withValues(alpha: 0.12);
        textColor = QuranyTheme.errorRed;
        borderColor = QuranyTheme.errorRed.withValues(alpha: 0.4);
        break;
      case _DiffStatus.omission:
        bgColor = QuranyTheme.warningOrange.withValues(alpha: 0.12);
        textColor = QuranyTheme.warningOrange;
        borderColor = QuranyTheme.warningOrange.withValues(alpha: 0.4);
        break;
      case _DiffStatus.addition:
        bgColor = Colors.blue.withValues(alpha: 0.12);
        textColor = Colors.blue;
        borderColor = Colors.blue.withValues(alpha: 0.4);
        break;
      case _DiffStatus.sequence:
        bgColor = Colors.purple.withValues(alpha: 0.12);
        textColor = Colors.purple;
        borderColor = Colors.purple.withValues(alpha: 0.4);
        break;
    }

    return Tooltip(
      message: diff.status == _DiffStatus.correct
          ? 'صحيح'
          : '${_errorTypeArabic(diff.errorType ?? '')}${diff.recitedWord != null ? ' — التلاوة: ${diff.recitedWord}' : ''}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: diff.status != _DiffStatus.correct
              ? Border.all(color: borderColor, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error type icon for non-correct words
            if (diff.status != _DiffStatus.correct)
              Icon(
                _errorIcon(diff.errorType ?? ''),
                size: 12,
                color: textColor,
              ),
            Text(
              diff.referenceWord,
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Amiri',
                height: 1.6,
                color: textColor,
                fontWeight: diff.status == _DiffStatus.correct
                    ? FontWeight.normal
                    : FontWeight.bold,
                decoration: diff.status == _DiffStatus.omission
                    ? TextDecoration.lineThrough
                    : null,
              ),
              textDirection: TextDirection.rtl,
            ),
            // Show what was actually recited (for substitution)
            if (diff.status == _DiffStatus.substitution && diff.recitedWord != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: QuranyTheme.errorRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  diff.recitedWord!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: QuranyTheme.errorRed,
                    decoration: TextDecoration.lineThrough,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 2: Error Details ───
  Widget _buildErrorsTab() {
    if (session.errors.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: QuranyTheme.correctGreen),
            SizedBox(height: 16),
            Text('لا توجد أخطاء! 🎉', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: QuranyTheme.correctGreen)),
            SizedBox(height: 8),
            Text('تلاوة ممتازة، بارك الله فيك', style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    // Count errors by type
    final errorCounts = <String, int>{};
    for (final err in session.errors) {
      errorCounts[err.type] = (errorCounts[err.type] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Error type summary cards
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ملخص الأخطاء حسب النوع',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: QuranyTheme.darkGreen,
                  ),
                ),
                const SizedBox(height: 16),
                ...errorCounts.entries.map((entry) {
                  final color = _errorColor(entry.key);
                  final total = session.errors.length;
                  final percentage = (entry.value / total * 100).round();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_errorIcon(entry.key), color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _errorTypeArabic(entry.key),
                                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                                  ),
                                  Text(
                                    '${entry.value} ($percentage%)',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: entry.value / total,
                                  backgroundColor: color.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation(color),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Individual error cards
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'تفاصيل كل خطأ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: QuranyTheme.darkGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...session.errors.asMap().entries.map((entry) {
            final index = entry.key;
            final error = entry.value;
            final color = _errorColor(error.type);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Error number
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Error icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_errorIcon(error.type), color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    // Error details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            error.typeArabic,
                            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          if (error.expectedWord.isNotEmpty)
                            RichText(
                              textDirection: TextDirection.rtl,
                              text: TextSpan(
                                style: const TextStyle(fontSize: 13, fontFamily: 'Amiri'),
                                children: [
                                  const TextSpan(text: 'المتوقع: ', style: TextStyle(color: Colors.grey)),
                                  TextSpan(
                                    text: error.expectedWord,
                                    style: const TextStyle(
                                      color: QuranyTheme.correctGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (error.recitedWord.isNotEmpty)
                            RichText(
                              textDirection: TextDirection.rtl,
                              text: TextSpan(
                                style: const TextStyle(fontSize: 13, fontFamily: 'Amiri'),
                                children: [
                                  const TextSpan(text: 'التلاوة: ', style: TextStyle(color: Colors.grey)),
                                  TextSpan(
                                    text: error.recitedWord,
                                    style: const TextStyle(
                                      color: QuranyTheme.errorRed,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Tab 3: Statistics ───
  Widget _buildStatsTab(Color scoreColor) {
    final correctPercentage = session.totalWords > 0
        ? (session.matchedWords / session.totalWords * 100)
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats grid
          Row(
            children: [
              _StatTile(
                icon: Icons.format_list_numbered,
                label: 'إجمالي الكلمات',
                value: '${session.totalWords}',
                color: QuranyTheme.primaryGreen,
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: Icons.check_circle,
                label: 'الكلمات الصحيحة',
                value: '${session.matchedWords}',
                color: QuranyTheme.correctGreen,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatTile(
                icon: Icons.error,
                label: 'الأخطاء',
                value: '${session.mistakes}',
                color: QuranyTheme.errorRed,
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: Icons.auto_stories,
                label: 'الآيات',
                value: '${session.versesRecited}',
                color: QuranyTheme.primaryGold,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Accuracy chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'نسبة الدقة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: QuranyTheme.darkGreen,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: _AccuracyRingPainter(
                      percentage: correctPercentage,
                      color: scoreColor,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${correctPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                          const Text(
                            'دقة الكلمات',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Accuracy breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _accuracyItem('صحيح', session.matchedWords, QuranyTheme.correctGreen),
                    _accuracyItem('خطأ', session.mistakes, QuranyTheme.errorRed),
                    _accuracyItem('الإجمالي', session.totalWords, QuranyTheme.primaryGreen),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Mode info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QuranyTheme.primaryGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  session.mode == 'memorization' ? Icons.psychology : Icons.mic,
                  color: QuranyTheme.primaryGold,
                ),
                const SizedBox(width: 12),
                Text(
                  session.mode == 'memorization' ? 'وضع مراجعة الحفظ' : 'وضع التلاوة الحرة',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: QuranyTheme.primaryGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accuracyItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  // ─── Action Buttons ───
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة التلاوة'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text('الرئيسية'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───
  String _errorTypeArabic(String type) {
    switch (type) {
      case 'substitution':
        return 'استبدال';
      case 'omission':
        return 'حذف';
      case 'addition':
        return 'إضافة';
      case 'sequence':
        return 'ترتيب';
      default:
        return type;
    }
  }

  Color _errorColor(String type) {
    switch (type) {
      case 'substitution':
        return QuranyTheme.errorRed;
      case 'omission':
        return QuranyTheme.warningOrange;
      case 'addition':
        return Colors.blue;
      case 'sequence':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _errorIcon(String type) {
    switch (type) {
      case 'substitution':
        return Icons.swap_horiz;
      case 'omission':
        return Icons.remove_circle_outline;
      case 'addition':
        return Icons.add_circle_outline;
      case 'sequence':
        return Icons.shuffle;
      default:
        return Icons.error_outline;
    }
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Diff Helper types ───

enum _DiffStatus { correct, substitution, omission, addition, sequence }

class _DiffWord {
  final String referenceWord;
  final String? recitedWord;
  final _DiffStatus status;
  final String? errorType;

  const _DiffWord({
    required this.referenceWord,
    this.recitedWord,
    required this.status,
    this.errorType,
  });
}

/// Custom painter for accuracy ring
class _AccuracyRingPainter extends CustomPainter {
  final double percentage;
  final Color color;

  _AccuracyRingPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Foreground ring
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AccuracyRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
