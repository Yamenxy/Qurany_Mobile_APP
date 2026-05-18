import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/schedule.dart';
import 'notification_service.dart';

class ScheduleService extends ChangeNotifier {
  final SharedPreferences _prefs;
  final NotificationService _notificationService = NotificationService();
  List<RecitationSchedule> _schedules = [];

  ScheduleService(this._prefs) {
    _loadSchedules();
  }

  List<RecitationSchedule> get schedules => List.unmodifiable(_schedules);

  List<RecitationSchedule> get enabledSchedules =>
      _schedules.where((s) => s.enabled).toList();

  List<RecitationSchedule> get todaySchedules {
    final today = DateTime.now().weekday; // 1=Mon .. 7=Sun
    return _schedules.where((s) {
      return s.enabled && (s.dayOfWeek == 0 || s.dayOfWeek == today);
    }).toList()
      ..sort((a, b) {
        final aMin = a.hour * 60 + a.minute;
        final bMin = b.hour * 60 + b.minute;
        return aMin.compareTo(bMin);
      });
  }

  /// Get current daily streak (consecutive days with at least one completed session)
  int get dailyStreak {
    return _prefs.getInt('daily_streak') ?? 0;
  }

  Future<void> updateStreak() async {
    final lastActive = _prefs.getString('last_active_date');
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (lastActive == todayStr) return; // Already counted today

    if (lastActive != null) {
      final lastDate = DateTime.parse(lastActive);
      final diff = today.difference(lastDate).inDays;
      if (diff == 1) {
        // Consecutive day
        await _prefs.setInt('daily_streak', dailyStreak + 1);
      } else if (diff > 1) {
        // Streak broken
        await _prefs.setInt('daily_streak', 1);
      }
    } else {
      await _prefs.setInt('daily_streak', 1);
    }

    await _prefs.setString('last_active_date', todayStr);
    notifyListeners();
  }

  void _loadSchedules() {
    final data = _prefs.getString('recitation_schedules');
    if (data != null) {
      final list = json.decode(data) as List;
      _schedules = list.map((e) => RecitationSchedule.fromJson(e)).toList();
    }
  }

  Future<void> _saveSchedules() async {
    final data = json.encode(_schedules.map((s) => s.toJson()).toList());
    await _prefs.setString('recitation_schedules', data);
  }

  Future<void> addSchedule(RecitationSchedule schedule) async {
    _schedules.add(schedule);
    await _saveSchedules();
    if (schedule.enabled) {
      await _scheduleNotification(schedule);
    }
    notifyListeners();
  }

  Future<void> updateSchedule(RecitationSchedule schedule) async {
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index >= 0) {
      _schedules[index] = schedule;
      await _saveSchedules();
      // Re-schedule notification
      await _cancelNotification(schedule);
      if (schedule.enabled) {
        await _scheduleNotification(schedule);
      }
      notifyListeners();
    }
  }

  Future<void> removeSchedule(String id) async {
    final schedule = _schedules.firstWhere((s) => s.id == id);
    await _cancelNotification(schedule);
    _schedules.removeWhere((s) => s.id == id);
    await _saveSchedules();
    notifyListeners();
  }

  Future<void> toggleSchedule(String id) async {
    final index = _schedules.indexWhere((s) => s.id == id);
    if (index >= 0) {
      final schedule = _schedules[index];
      final updated = schedule.copyWith(enabled: !schedule.enabled);
      _schedules[index] = updated;
      await _saveSchedules();
      if (updated.enabled) {
        await _scheduleNotification(updated);
      } else {
        await _cancelNotification(updated);
      }
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    await _notificationService.cancelAll();
    _schedules.clear();
    await _saveSchedules();
    notifyListeners();
  }

  Future<void> _scheduleNotification(RecitationSchedule schedule) async {
    final notifId = schedule.id.hashCode.abs() % 100000;
    final body =
        '🕌 حان وقت تلاوة سورة ${schedule.surahName}\n${schedule.mode == "memorization" ? "مراجعة الحفظ" : "تلاوة حرة"}';

    if (schedule.dayOfWeek == 0) {
      // Daily
      await _notificationService.scheduleDailyNotification(
        id: notifId,
        title: '📖 ${schedule.title}',
        body: body,
        hour: schedule.hour,
        minute: schedule.minute,
        payload: json.encode({
          'surahNumber': schedule.surahNumber,
          'surahName': schedule.surahName,
          'mode': schedule.mode,
        }),
      );
    } else {
      // Weekly
      await _notificationService.scheduleWeeklyNotification(
        id: notifId,
        title: '📖 ${schedule.title}',
        body: body,
        dayOfWeek: schedule.dayOfWeek,
        hour: schedule.hour,
        minute: schedule.minute,
        payload: json.encode({
          'surahNumber': schedule.surahNumber,
          'surahName': schedule.surahName,
          'mode': schedule.mode,
        }),
      );
    }
  }

  Future<void> _cancelNotification(RecitationSchedule schedule) async {
    final notifId = schedule.id.hashCode.abs() % 100000;
    await _notificationService.cancelNotification(notifId);
  }

  /// Create a quick preset schedule
  RecitationSchedule createPreset({
    required String title,
    required int surahNumber,
    required String surahName,
    required int hour,
    required int minute,
    int dayOfWeek = 0,
    String mode = 'free',
  }) {
    return RecitationSchedule(
      id: const Uuid().v4(),
      title: title,
      surahNumber: surahNumber,
      surahName: surahName,
      dayOfWeek: dayOfWeek,
      hour: hour,
      minute: minute,
      mode: mode,
      createdAt: DateTime.now(),
    );
  }
}
