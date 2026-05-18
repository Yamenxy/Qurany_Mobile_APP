import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../services/auth_service.dart';
import '../../services/recitation_history_service.dart';
import '../../services/schedule_service.dart';

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
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DashboardTab(),
          _QuranTab(),
          _ReciteTab(),
          _MoreTab(),
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
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final history = context.watch<RecitationHistoryService>();
    final schedule = context.watch<ScheduleService>();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [QuranyTheme.darkGreen, QuranyTheme.primaryGreen],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'السلام عليكم',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            auth.userName.isNotEmpty ? auth.userName : 'ضيف',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Daily streak badge
                          if (schedule.dailyStreak > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: QuranyTheme.primaryGold.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${schedule.dailyStreak}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: QuranyTheme.primaryGold,
                            child: Text(
                              auth.userName.isNotEmpty
                                  ? auth.userName[0].toUpperCase()
                                  : 'ض',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick stats
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.auto_stories,
                        label: 'الجلسات',
                        value: '${history.totalSessions}',
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.grade_rounded,
                        label: 'المتوسط',
                        value:
                            '${history.averageScore.toStringAsFixed(0)}%',
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.local_fire_department,
                        label: 'المتتالية',
                        value: '${schedule.dailyStreak}',
                      ),
                    ],
                  ),
                ],
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
                          trailing: const Icon(Icons.arrow_back_ios, size: 16),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: QuranyTheme.primaryGold, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
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
              Icon(Icons.arrow_back_ios, color: color, size: 18),
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
      trailing: Icon(Icons.arrow_back_ios, size: 16, color: c),
      onTap: onTap,
    );
  }
}
