import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/recitation_history_service.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<RecitationHistoryService>();
    final recentSessions = history.getRecentSessions(7);
    final surahCounts = history.surahRecitationCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقدم والإحصائيات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall stats
            const Text(
              'الإحصائيات العامة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: QuranyTheme.darkGreen,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _ProgressCard(
                  icon: Icons.auto_stories,
                  title: 'إجمالي الجلسات',
                  value: '${history.totalSessions}',
                  color: QuranyTheme.primaryGreen,
                ),
                const SizedBox(width: 12),
                _ProgressCard(
                  icon: Icons.grade,
                  title: 'متوسط الدقة',
                  value: '${history.averageScore.toStringAsFixed(1)}%',
                  color: QuranyTheme.primaryGold,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ProgressCard(
                  icon: Icons.menu_book,
                  title: 'الآيات المقروءة',
                  value: '${history.totalVersesRecited}',
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _ProgressCard(
                  icon: Icons.error_outline,
                  title: 'إجمالي الأخطاء',
                  value: '${history.totalMistakes}',
                  color: QuranyTheme.errorRed,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Recent activity (last 7 days)
            const Text(
              'نشاط آخر 7 أيام',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: QuranyTheme.darkGreen,
              ),
            ),
            const SizedBox(height: 16),

            if (recentSessions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: QuranyTheme.lightGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 48, color: QuranyTheme.primaryGreen),
                    SizedBox(height: 12),
                    Text(
                      'لا يوجد نشاط في آخر 7 أيام',
                      style: TextStyle(
                        color: QuranyTheme.primaryGreen,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else
              // Simple bar chart
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
                  children: [
                    Text(
                      '${recentSessions.length} جلسة في آخر 7 أيام',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(7, (i) {
                      final day = DateTime.now().subtract(Duration(days: 6 - i));
                      final dayName = _getDayName(day.weekday);
                      final daySessions = recentSessions
                          .where((s) =>
                              s.dateTime.day == day.day &&
                              s.dateTime.month == day.month)
                          .length;
                      final maxSessions = recentSessions.isNotEmpty
                          ? recentSessions.length
                          : 1;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              child: Text(
                                dayName,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerRight,
                                  widthFactor: daySessions / maxSessions,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: QuranyTheme.primaryGreen,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 20,
                              child: Text(
                                '$daySessions',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Most recited surahs
            if (surahCounts.isNotEmpty) ...[
              const Text(
                'أكثر السور تلاوة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: QuranyTheme.darkGreen,
                ),
              ),
              const SizedBox(height: 16),
              ...surahCounts.entries.take(5).map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: QuranyTheme.primaryGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.value}',
                          style: const TextStyle(
                            color: QuranyTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text('سورة ${entry.key}'),
                    subtitle: Text('${entry.value} مرة'),
                  ),
                );
              }),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'الاثنين';
      case 2:
        return 'الثلاثاء';
      case 3:
        return 'الأربعاء';
      case 4:
        return 'الخميس';
      case 5:
        return 'الجمعة';
      case 6:
        return 'السبت';
      case 7:
        return 'الأحد';
      default:
        return '';
    }
  }
}

class _ProgressCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _ProgressCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: color.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
