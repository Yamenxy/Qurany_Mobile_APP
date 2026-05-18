class Surah {
  final int number;
  final String nameArabic;
  final String revelationType;
  final int versesCount;

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.revelationType,
    required this.versesCount,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] ?? 0,
      nameArabic: json['name'] ?? json['nameArabic'] ?? '',
      revelationType: json['revelationType'] ?? '',
      versesCount: json['numberOfAyahs'] ?? json['versesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'nameArabic': nameArabic,
        'revelationType': revelationType,
        'versesCount': versesCount,
      };
}
