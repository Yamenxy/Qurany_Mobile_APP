import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../models/verse.dart';
import '../../services/auth_service.dart';
import '../../services/quran_service.dart';
import '../../services/recitation_history_service.dart';
import '../../services/schedule_service.dart';
import '../../widgets/app_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuranyTheme.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _DashboardTab(),
          const _QuranTab(),
          const _ReciteTab(),
          const _MoreTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'القرآن',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_rounded),
            label: 'التلاوة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }
}

// ─────────────────── Dashboard Tab ───────────────────
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final quran = context.read<QuranService>();
      if (quran.verseOfTheDay == null && !quran.verseOfTheDayLoading) {
        quran.loadRandomVerse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final history = context.watch<RecitationHistoryService>();
    final schedule = context.watch<ScheduleService>();
    final quran = context.watch<QuranService>();

    return Scaffold(
      backgroundColor: QuranyTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 260,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      QuranyTheme.primary.withValues(alpha: 0.06),
                      QuranyTheme.background.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DashboardTopBar(
                        onMenuTap: () =>
                            Navigator.pushNamed(context, AppRoutes.settings),
                        onNotificationsTap: () =>
                            Navigator.pushNamed(context, AppRoutes.schedule),
                      ),
                      _DashboardGreeting(
                        userName:
                            auth.userName.isNotEmpty ? auth.userName : 'ضيف',
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: _ContinueReadingCard(
                          lastSession: history.sessions.isNotEmpty
                              ? history.sessions.first
                              : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: _VerseOfTheDayCard(
                          verse: quran.verseOfTheDay,
                          isLoading: quran.verseOfTheDayLoading,
                          error: quran.verseOfTheDayError,
                          surahName: quran.verseOfTheDay != null
                              ? quran.surahNameFor(
                                  quran.verseOfTheDay!.surahNumber,
                                )
                              : null,
                          onRetry: () => quran.loadRandomVerse(),
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: _DashboardStatsRow(
                      sessions: history.totalSessions,
                      average: history.averageScore,
                      streak: schedule.dailyStreak,
                    ),
                  ),
                ),

          // Today's Schedule Card
          if (schedule.todaySchedules.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _TodayScheduleCard(schedules: schedule.todaySchedules),
              ),
            ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الوصول السريع',
                    textAlign: TextAlign.start,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: QuranyTheme.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    children: [
                      _ActionCard(
                        icon: Icons.mic_rounded,
                        title: 'تلاوة حرة',
                        subtitle: 'سجل تلاوتك',
                        color: QuranyTheme.primaryGreen,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.surahList,
                          arguments: {'selectForRecitation': true, 'mode': 'free'},
                        ),
                      ),
                      _ActionCard(
                        icon: Icons.school_rounded,
                        title: 'تحفيظ',
                        subtitle: 'احفظ آية بآية',
                        color: const Color(0xFF1565C0),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.surahList,
                          arguments: {'selectForRecitation': true, 'mode': 'tahfeez'},
                        ),
                      ),
                      _ActionCard(
                        icon: Icons.record_voice_over_rounded,
                        title: 'تسميع',
                        subtitle: 'سمّع ما حفظت',
                        color: const Color(0xFF6A1B9A),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.surahList,
                          arguments: {'selectForRecitation': true, 'mode': 'tasmee3'},
                        ),
                      ),
                      _ActionCard(
                        icon: Icons.psychology_rounded,
                        title: 'مراجعة الحفظ',
                        subtitle: 'اختبر حفظك',
                        color: QuranyTheme.primaryGold,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.surahList,
                          arguments: {'selectForRecitation': true, 'mode': 'memorization'},
                        ),
                      ),
                      _ActionCard(
                        icon: Icons.schedule_rounded,
                        title: 'جدول التلاوة',
                        subtitle: 'نظم أوردك',
                        color: const Color(0xFF00897B),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.schedule,
                        ),
                      ),
                      _ActionCard(
                        icon: Icons.menu_book_rounded,
                        title: 'قراءة القرآن',
                        subtitle: 'المصحف الشريف',
                        color: const Color(0xFF1565C0),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.surahList,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Recent Activity
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'النشاط الأخير',
                        textAlign: TextAlign.start,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: QuranyTheme.darkGreen,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.history,
                        ),
                        child: const Text('عرض الكل'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (history.sessions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: QuranyTheme.lightGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 48,
                              color: QuranyTheme.primaryGreen,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'لا توجد جلسات سابقة',
                              style: TextStyle(
                                color: QuranyTheme.primaryGreen,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'ابدأ أول تلاوة لك الآن!',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...history.sessions.take(3).map((session) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: session.similarityScore >= 85
                                ? QuranyTheme.correctGreen
                                : session.similarityScore >= 70
                                    ? QuranyTheme.warningOrange
                                    : QuranyTheme.errorRed,
                            child: Text(
                              '${session.similarityScore.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(session.surahName),
                          subtitle: Text(
                            '${session.mistakes} أخطاء • ${_formatDate(session.dateTime)}',
                          ),
                          trailing: AppIcons.forwardChevron(size: 16),
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─────────────────── Dashboard header widgets ───────────────────

class _DashboardTopBar extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationsTap;

  const _DashboardTopBar({
    required this.onMenuTap,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.menu_rounded,
            onTap: onMenuTap,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/theLogo.png',
                  height: 28,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.menu_book_rounded,
                    color: QuranyTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'قُرآنِي',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: QuranyTheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: onNotificationsTap,
          ),
        ],
      ),
    );
  }
}

class _DashboardGreeting extends StatelessWidget {
  final String userName;

  const _DashboardGreeting({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'السلام عليكم',
            textAlign: TextAlign.start,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 14,
              color: QuranyTheme.sage,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'بارك الله يومك، $userName',
                    textAlign: TextAlign.start,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: QuranyTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEAEA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFE57373),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QuranyTheme.surface.withValues(alpha: 0.7),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: QuranyTheme.primary, size: 22),
        ),
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  final dynamic lastSession;

  const _ContinueReadingCard({this.lastSession});

  static const int _defaultSurah = 18; // Al-Kahf

  @override
  Widget build(BuildContext context) {
    final surahNumber = lastSession?.surahNumber ?? _defaultSurah;
    final surahName = lastSession?.surahName ??
        AppConstants.surahNames[_defaultSurah - 1];
    final totalVerses = AppConstants.surahVerseCount[surahNumber - 1];
    final versesRead = lastSession?.versesRecited ?? (totalVerses * 0.4).round();
    final progress = (versesRead / totalVerses).clamp(0.0, 1.0);
    final progressPercent = (progress * 100).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.quranReader,
          arguments: {
            'surahNumber': surahNumber,
            'surahName': surahName,
          },
        ),
        borderRadius: BorderRadius.circular(QuranyTheme.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: QuranyTheme.primary,
            borderRadius: BorderRadius.circular(QuranyTheme.cardRadius),
            boxShadow: const [
              BoxShadow(
                color: QuranyTheme.shadow,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white.withValues(alpha: 0.95),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تابع القراءة',
                              textAlign: TextAlign.start,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'سورة $surahName',
                              textAlign: TextAlign.start,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$surahNumber:1 — $surahNumber:$totalVerses',
                              textAlign: TextAlign.start,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: AppIcons.actionForward(
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor:
                          const AlwaysStoppedAnimation(QuranyTheme.progress),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$progressPercent%',
                    textAlign: TextAlign.start,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardStatsRow extends StatelessWidget {
  final int sessions;
  final double average;
  final int streak;

  const _DashboardStatsRow({
    required this.sessions,
    required this.average,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatPill(
          icon: Icons.auto_stories_outlined,
          label: 'الجلسات',
          value: '$sessions',
        ),
        const SizedBox(width: 10),
        _StatPill(
          icon: Icons.grade_outlined,
          label: 'المتوسط',
          value: '${average.toStringAsFixed(0)}%',
        ),
        const SizedBox(width: 10),
        _StatPill(
          icon: Icons.local_fire_department_outlined,
          label: 'المتتالية',
          value: '$streak',
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: QuranyTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: QuranyTheme.border),
          boxShadow: const [
            BoxShadow(
              color: QuranyTheme.shadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: QuranyTheme.primary, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: QuranyTheme.textPrimary,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 11,
                color: QuranyTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseOfTheDayCard extends StatelessWidget {
  final Verse? verse;
  final bool isLoading;
  final String? error;
  final String? surahName;
  final VoidCallback onRetry;

  const _VerseOfTheDayCard({
    required this.verse,
    required this.isLoading,
    required this.error,
    required this.surahName,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: QuranyTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(QuranyTheme.cardRadius),
        border: Border.all(color: QuranyTheme.border),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: QuranyTheme.accent.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.wb_sunny_outlined,
                    color: QuranyTheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'آية اليوم',
                  textAlign: TextAlign.start,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: QuranyTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (verse != null && surahName != null)
                  Text(
                    '$surahName ${verse!.surahNumber}:${verse!.verseNumber}',
                    textAlign: TextAlign.start,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 13,
                      color: QuranyTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: QuranyTheme.primary,
                    ),
                  ),
                ),
              )
            else if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      error!,
                      textAlign: TextAlign.start,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(color: QuranyTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: onRetry,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ),
                  ],
                ),
              )
            else if (verse != null && verse!.text.isNotEmpty)
              Text(
                verse!.text,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 24,
                      height: 2.0,
                      color: QuranyTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.start,
                textDirection: TextDirection.rtl,
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: onRetry,
                    child: const Text('تحميل آية اليوم'),
                  ),
                ),
              ),
            if (!isLoading && verse != null) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Material(
                    color: QuranyTheme.surface,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        final reference =
                            '$surahName ${verse!.surahNumber}:${verse!.verseNumber}';
                        Clipboard.setData(
                          ClipboardData(text: '${verse!.text}\n— $reference'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ الآية'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.share_outlined,
                          color: QuranyTheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: QuranyTheme.accent.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.quranReader,
                        arguments: {
                          'surahNumber': verse!.surahNumber,
                          'surahName': surahName,
                        },
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text.rich(
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.start,
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: QuranyTheme.textPrimary,
                              height: 1.2,
                            ),
                            children: [
                              const TextSpan(text: 'عرض الكل'),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding:
                                      const EdgeInsetsDirectional.only(
                                    start: 4,
                                  ),
                                  child: AppIcons.forwardChevron(
                                    size: 14,
                                    color: QuranyTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: color.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.start,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.start,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayScheduleCard extends StatelessWidget {
  final List<dynamic> schedules;
  const _TodayScheduleCard({required this.schedules});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00897B).withValues(alpha: 0.12),
            const Color(0xFF00897B).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00897B).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_rounded, color: Color(0xFF00897B), size: 20),
              const SizedBox(width: 8),
              const Text(
                'ورد اليوم',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00897B),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.schedule),
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...schedules.take(2).map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00897B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${s.title} — ${s.surahName}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    s.timeFormatted,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────── Quran Tab ───────────────────
class _QuranTab extends StatelessWidget {
  const _QuranTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القرآن الكريم')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.menu_book_rounded,
              size: 80,
              color: QuranyTheme.primaryGreen,
            ),
            const SizedBox(height: 20),
            const Text(
              'المصحف الشريف',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('اختر سورة للقراءة'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.surahList),
              icon: const Icon(Icons.list_rounded),
              label: const Text('قائمة السور'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── Recite Tab ───────────────────
class _ReciteTab extends StatelessWidget {
  const _ReciteTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التلاوة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.mic_rounded,
              size: 80,
              color: QuranyTheme.primaryGreen,
            ),
            const SizedBox(height: 24),
            const Text(
              'اختر وضع التلاوة',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Free recitation
            _RecitationModeCard(
              icon: Icons.mic,
              title: 'تلاوة حرة',
              description:
                  'سجل تلاوتك واحصل على تقييم فوري مع تحديد الأخطاء',
              color: QuranyTheme.primaryGreen,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.surahList,
                arguments: {'selectForRecitation': true, 'mode': 'free'},
              ),
            ),
            const SizedBox(height: 16),

            // Tahfeez mode
            _RecitationModeCard(
              icon: Icons.school_rounded,
              title: 'تحفيظ',
              description:
                  'احفظ آية بآية مع إمكانية إخفاء النص لاختبار نفسك',
              color: const Color(0xFF1565C0),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.surahList,
                arguments: {'selectForRecitation': true, 'mode': 'tahfeez'},
              ),
            ),
            const SizedBox(height: 16),

            // Tasmee3 mode
            _RecitationModeCard(
              icon: Icons.record_voice_over_rounded,
              title: 'تسميع',
              description:
                  'سمّع ما حفظت — يظهر النص مباشرة أثناء القراءة',
              color: const Color(0xFF6A1B9A),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.surahList,
                arguments: {'selectForRecitation': true, 'mode': 'tasmee3'},
              ),
            ),
            const SizedBox(height: 16),

            // Memorization review
            _RecitationModeCard(
              icon: Icons.psychology,
              title: 'مراجعة الحفظ',
              description:
                  'اختبر حفظك للسور بدون النظر إلى النص',
              color: QuranyTheme.primaryGold,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.surahList,
                arguments: {
                  'selectForRecitation': true,
                  'mode': 'memorization',
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecitationModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _RecitationModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              AppIcons.forwardChevron(color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────── More Tab ───────────────────
class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المزيد')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MoreItem(
            icon: Icons.schedule_rounded,
            title: 'جدول التلاوة',
            onTap: () => Navigator.pushNamed(context, AppRoutes.schedule),
          ),
          _MoreItem(
            icon: Icons.bookmark_rounded,
            title: 'العلامات المرجعية',
            onTap: () => Navigator.pushNamed(context, AppRoutes.bookmarks),
          ),
          _MoreItem(
            icon: Icons.history_rounded,
            title: 'سجل التلاوة',
            onTap: () => Navigator.pushNamed(context, AppRoutes.history),
          ),
          _MoreItem(
            icon: Icons.trending_up_rounded,
            title: 'التقدم والإحصائيات',
            onTap: () => Navigator.pushNamed(context, AppRoutes.progress),
          ),
          _MoreItem(
            icon: Icons.search_rounded,
            title: 'البحث في القرآن',
            onTap: () => Navigator.pushNamed(context, AppRoutes.search),
          ),
          const Divider(height: 32),
          _MoreItem(
            icon: Icons.settings_rounded,
            title: 'الإعدادات',
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
          _MoreItem(
            icon: Icons.info_outline_rounded,
            title: 'عن التطبيق',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'قُرآنِي',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.menu_book_rounded,
                  color: QuranyTheme.primaryGreen,
                  size: 48,
                ),
                children: [
                  const Text(
                    'تطبيق قُرآنِي - مساعد ذكي لتلاوة القرآن الكريم\n'
                    'يستخدم تقنيات الذكاء الاصطناعي لتقييم التلاوة وكشف الأخطاء.',
                  ),
                ],
              );
            },
          ),
          const Divider(height: 32),
          _MoreItem(
            icon: Icons.logout_rounded,
            title: 'تسجيل الخروج',
            color: QuranyTheme.errorRed,
            onTap: () async {
              final auth = context.read<AuthService>();
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback onTap;

  const _MoreItem({
    required this.icon,
    required this.title,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? QuranyTheme.primaryGreen;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c),
      ),
      title: Text(title, style: TextStyle(color: c)),
      trailing: AppIcons.forwardChevron(size: 16, color: c),
      onTap: onTap,
    );
  }
}
