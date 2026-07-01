/// Static Surah -> Mushaf page index for the King Fahd Complex 15-line
/// Madani layout (the same layout served by Quran.com API v4 `mushaf=2`).
///
/// This lets the app navigate directly to a Surah's starting page without
/// any network round-trip, and lets [MushafPage] decide whether a Surah
/// needs a synthesized Basmallah line (all Surahs except Al-Fatihah and
/// At-Tawbah).
class MushafPageIndex {
  MushafPageIndex._();

  static const int totalPages = 604;
  static const int linesPerPage = 15;

  static const List<int> _surahsWithoutBasmallah = [1, 9];

  /// 1-indexed starting page for each Surah (index 0 = Surah 1).
  static const List<int> _startPage = [
    1, 2, 50, 77, 106, 128, 151, 177, 187, 208,
    221, 235, 249, 255, 262, 267, 282, 293, 305, 312,
    322, 332, 342, 350, 359, 367, 377, 385, 396, 404,
    411, 415, 418, 428, 434, 440, 446, 453, 458, 467,
    477, 483, 489, 496, 499, 502, 507, 511, 515, 518,
    520, 523, 526, 528, 531, 534, 537, 542, 545, 549,
    551, 553, 554, 556, 558, 560, 562, 564, 566, 568,
    570, 572, 574, 575, 577, 578, 580, 582, 583, 585,
    586, 587, 587, 589, 590, 591, 591, 592, 593, 594,
    595, 595, 596, 596, 597, 597, 598, 598, 599, 599,
    600, 600, 601, 601, 601, 602, 602, 602, 603, 603,
    603, 604, 604, 604,
  ];

  /// Returns the first mushaf page number (1..604) that a Surah appears on.
  static int firstPage(int surahNumber) {
    assert(surahNumber >= 1 && surahNumber <= 114, 'surahNumber out of range');
    return _startPage[surahNumber - 1];
  }

  /// Whether this Surah has its own decorative Basmallah line on the mushaf
  /// page (every Surah except Al-Fatihah, where the Basmallah is verse 1
  /// itself, and At-Tawbah, which has none).
  static bool hasBasmallah(int surahNumber) =>
      !_surahsWithoutBasmallah.contains(surahNumber);
}
