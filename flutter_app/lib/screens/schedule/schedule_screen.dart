import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../models/schedule.dart';
import '../../services/schedule_service.dart';
import '../../widgets/app_icons.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheduleService = context.watch<ScheduleService>();
    final schedules = scheduleService.schedules;

    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول التلاوة'),
        leading: AppIcons.backButton(context: context),
        actions: [
          if (schedules.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmClearAll(context, scheduleService),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddScheduleSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('إضافة ورد'),
        backgroundColor: QuranyTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: schedules.isEmpty
          ? _buildEmptyState(context)
          : _buildScheduleList(context, schedules),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: QuranyTheme.primaryGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule_rounded,
                size: 64,
                color: QuranyTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا يوجد جدول تلاوة',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: QuranyTheme.darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'أنشئ جدولًا يوميًا أو أسبوعيًا لتلاوة القرآن\nوسنذكرك في الموعد المحدد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            // Quick presets
            const Text(
              'أوردة مقترحة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: QuranyTheme.darkGreen,
              ),
            ),
            const SizedBox(height: 16),
            _PresetCard(
              icon: Icons.wb_sunny_rounded,
              title: 'ورد الصباح',
              subtitle: 'سورة الكهف - كل جمعة',
              color: const Color(0xFFF57C00),
              onTap: () => _quickAddPreset(context,
                  title: 'ورد الجمعة',
                  surahNumber: 18,
                  surahName: 'الكهف',
                  hour: 7,
                  minute: 0,
                  dayOfWeek: 5),
            ),
            const SizedBox(height: 8),
            _PresetCard(
              icon: Icons.nightlight_round,
              title: 'ورد المساء',
              subtitle: 'سورة الملك - يوميًا',
              color: const Color(0xFF1565C0),
              onTap: () => _quickAddPreset(context,
                  title: 'ورد المساء',
                  surahNumber: 67,
                  surahName: 'الملك',
                  hour: 21,
                  minute: 0,
                  dayOfWeek: 0),
            ),
            const SizedBox(height: 8),
            _PresetCard(
              icon: Icons.auto_awesome,
              title: 'ورد الفجر',
              subtitle: 'سورة يس - يوميًا',
              color: const Color(0xFF6A1B9A),
              onTap: () => _quickAddPreset(context,
                  title: 'ورد الفجر',
                  surahNumber: 36,
                  surahName: 'يس',
                  hour: 5,
                  minute: 30,
                  dayOfWeek: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList(
      BuildContext context, List<RecitationSchedule> schedules) {
    final today = schedules
        .where(
            (s) => s.enabled && (s.dayOfWeek == 0 || s.dayOfWeek == DateTime.now().weekday))
        .toList()
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Today's schedule section
        if (today.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [QuranyTheme.darkGreen, QuranyTheme.primaryGreen],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.today, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'أوردة اليوم',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...today.map((s) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            s.timeFormatted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'سورة ${s.surahName}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_circle_filled,
                                color: QuranyTheme.primaryGold, size: 32),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.recitation,
                                arguments: {
                                  'surahNumber': s.surahNumber,
                                  'surahName': s.surahName,
                                  'mode': s.mode,
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // All schedules
        const Text(
          'جميع الأوردة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: QuranyTheme.darkGreen,
          ),
        ),
        const SizedBox(height: 12),
        ...schedules.map((schedule) => _ScheduleCard(schedule: schedule)),
      ],
    );
  }

  void _quickAddPreset(
    BuildContext context, {
    required String title,
    required int surahNumber,
    required String surahName,
    required int hour,
    required int minute,
    required int dayOfWeek,
  }) {
    final service = context.read<ScheduleService>();
    final schedule = service.createPreset(
      title: title,
      surahNumber: surahNumber,
      surahName: surahName,
      hour: hour,
      minute: minute,
      dayOfWeek: dayOfWeek,
    );
    service.addSchedule(schedule);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إضافة "$title" إلى الجدول'),
        backgroundColor: QuranyTheme.primaryGreen,
      ),
    );
  }

  void _showAddScheduleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddScheduleSheet(),
    );
  }

  void _confirmClearAll(BuildContext context, ScheduleService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف جميع الأوردة؟'),
        content: const Text('سيتم حذف جميع الأوردة والتنبيهات المجدولة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              service.clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('حذف الكل',
                style: TextStyle(color: QuranyTheme.errorRed)),
          ),
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PresetCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: Size.zero,
          ),
          child: const Text('إضافة', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final RecitationSchedule schedule;

  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final service = context.read<ScheduleService>();

    return Dismissible(
      key: Key(schedule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: QuranyTheme.errorRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => service.removeSchedule(schedule.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Time
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: schedule.enabled
                      ? QuranyTheme.primaryGreen.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    schedule.timeFormatted,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: schedule.enabled
                          ? QuranyTheme.primaryGreen
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: schedule.enabled
                            ? QuranyTheme.darkGreen
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'سورة ${schedule.surahName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: schedule.enabled ? Colors.grey[700] : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          schedule.dayOfWeek == 0
                              ? Icons.repeat
                              : Icons.calendar_today,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          schedule.dayName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          schedule.mode == 'memorization'
                              ? Icons.psychology
                              : Icons.mic,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          schedule.mode == 'memorization'
                              ? 'مراجعة حفظ'
                              : 'تلاوة حرة',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Toggle
              Switch(
                value: schedule.enabled,
                activeTrackColor: QuranyTheme.primaryGreen.withValues(alpha: 0.5),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? QuranyTheme.primaryGreen
                      : Colors.grey;
                }),
                onChanged: (_) => service.toggleSchedule(schedule.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddScheduleSheet extends StatefulWidget {
  @override
  State<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<_AddScheduleSheet> {
  final _titleController = TextEditingController(text: 'ورد التلاوة');
  int _selectedSurah = 1;
  int _dayOfWeek = 0; // daily
  TimeOfDay _time = const TimeOfDay(hour: 6, minute: 0);
  String _mode = 'free';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
            const Center(
              child: Text(
                'إضافة ورد جديد',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: QuranyTheme.darkGreen,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان الورد',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),

            // Surah selector
            const Text('اختر السورة',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(
                    color: QuranyTheme.primaryGreen.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedSurah,
                  isExpanded: true,
                  items: List.generate(114, (i) {
                    return DropdownMenuItem(
                      value: i + 1,
                      child: Text(
                          '${i + 1}. ${AppConstants.surahNames[i]}'),
                    );
                  }),
                  onChanged: (v) => setState(() => _selectedSurah = v ?? 1),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Day selector
            const Text('التكرار',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _DayChip(
                    label: 'يوميًا',
                    selected: _dayOfWeek == 0,
                    onTap: () => setState(() => _dayOfWeek = 0)),
                _DayChip(
                    label: 'الأحد',
                    selected: _dayOfWeek == 7,
                    onTap: () => setState(() => _dayOfWeek = 7)),
                _DayChip(
                    label: 'الاثنين',
                    selected: _dayOfWeek == 1,
                    onTap: () => setState(() => _dayOfWeek = 1)),
                _DayChip(
                    label: 'الثلاثاء',
                    selected: _dayOfWeek == 2,
                    onTap: () => setState(() => _dayOfWeek = 2)),
                _DayChip(
                    label: 'الأربعاء',
                    selected: _dayOfWeek == 3,
                    onTap: () => setState(() => _dayOfWeek = 3)),
                _DayChip(
                    label: 'الخميس',
                    selected: _dayOfWeek == 4,
                    onTap: () => setState(() => _dayOfWeek = 4)),
                _DayChip(
                    label: 'الجمعة',
                    selected: _dayOfWeek == 5,
                    onTap: () => setState(() => _dayOfWeek = 5)),
                _DayChip(
                    label: 'السبت',
                    selected: _dayOfWeek == 6,
                    onTap: () => setState(() => _dayOfWeek = 6)),
              ],
            ),
            const SizedBox(height: 16),

            // Time picker
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (picked != null) setState(() => _time = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: QuranyTheme.primaryGreen.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: QuranyTheme.primaryGreen),
                    const SizedBox(width: 12),
                    Text(
                      '${_time.hourOfPeriod == 0 ? 12 : _time.hourOfPeriod}:${_time.minute.toString().padLeft(2, '0')} ${_time.period == DayPeriod.am ? 'ص' : 'م'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Text('تغيير', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mode selector
            const Text('وضع التلاوة',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ModeOption(
                    icon: Icons.mic,
                    label: 'تلاوة حرة',
                    selected: _mode == 'free',
                    onTap: () => setState(() => _mode = 'free'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeOption(
                    icon: Icons.psychology,
                    label: 'مراجعة حفظ',
                    selected: _mode == 'memorization',
                    onTap: () => setState(() => _mode = 'memorization'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addSchedule,
                icon: const Icon(Icons.add),
                label: const Text('إضافة الورد'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSchedule() {
    final service = context.read<ScheduleService>();
    final schedule = RecitationSchedule(
      id: const Uuid().v4(),
      title: _titleController.text.trim().isEmpty
          ? 'ورد التلاوة'
          : _titleController.text.trim(),
      surahNumber: _selectedSurah,
      surahName: AppConstants.surahNames[_selectedSurah - 1],
      dayOfWeek: _dayOfWeek,
      hour: _time.hour,
      minute: _time.minute,
      mode: _mode,
      createdAt: DateTime.now(),
    );
    service.addSchedule(schedule);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إضافة "${schedule.title}"'),
        backgroundColor: QuranyTheme.primaryGreen,
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : QuranyTheme.darkGreen,
          fontSize: 12,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: QuranyTheme.primaryGreen,
      backgroundColor: QuranyTheme.lightGreen,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? QuranyTheme.primaryGreen.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? QuranyTheme.primaryGreen : Colors.grey.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? QuranyTheme.primaryGreen : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? QuranyTheme.primaryGreen : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
