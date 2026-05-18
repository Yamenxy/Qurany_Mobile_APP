/// A recitation schedule entry for the timetable / daily wird
class RecitationSchedule {
  final String id;
  final String title; // e.g. "ورد الصباح" or "مراجعة سورة البقرة"
  final int surahNumber;
  final String surahName;
  final int dayOfWeek; // 1=Mon .. 7=Sun, 0=daily
  final int hour;
  final int minute;
  final String mode; // 'free' or 'memorization'
  final bool enabled;
  final bool repeat; // repeats weekly or one-time
  final DateTime createdAt;

  const RecitationSchedule({
    required this.id,
    required this.title,
    required this.surahNumber,
    required this.surahName,
    required this.dayOfWeek,
    required this.hour,
    required this.minute,
    required this.mode,
    this.enabled = true,
    this.repeat = true,
    required this.createdAt,
  });

  RecitationSchedule copyWith({
    String? title,
    int? surahNumber,
    String? surahName,
    int? dayOfWeek,
    int? hour,
    int? minute,
    String? mode,
    bool? enabled,
    bool? repeat,
  }) {
    return RecitationSchedule(
      id: id,
      title: title ?? this.title,
      surahNumber: surahNumber ?? this.surahNumber,
      surahName: surahName ?? this.surahName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      mode: mode ?? this.mode,
      enabled: enabled ?? this.enabled,
      repeat: repeat ?? this.repeat,
      createdAt: createdAt,
    );
  }

  factory RecitationSchedule.fromJson(Map<String, dynamic> json) {
    return RecitationSchedule(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      surahNumber: json['surahNumber'] ?? 1,
      surahName: json['surahName'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 0,
      hour: json['hour'] ?? 6,
      minute: json['minute'] ?? 0,
      mode: json['mode'] ?? 'free',
      enabled: json['enabled'] ?? true,
      repeat: json['repeat'] ?? true,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'surahNumber': surahNumber,
        'surahName': surahName,
        'dayOfWeek': dayOfWeek,
        'hour': hour,
        'minute': minute,
        'mode': mode,
        'enabled': enabled,
        'repeat': repeat,
        'createdAt': createdAt.toIso8601String(),
      };

  String get dayName {
    switch (dayOfWeek) {
      case 0:
        return 'يوميًا';
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

  String get timeFormatted {
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'ص' : 'م';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:$m $period';
  }
}
