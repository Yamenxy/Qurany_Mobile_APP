import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/verse.dart';
import '../config/constants.dart';

class QuranService extends ChangeNotifier {
  final Map<int, List<Verse>> _surahCache = {};
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch verses for a specific Surah from the Quran API
  Future<List<Verse>> getSurahVerses(int surahNumber) async {
    // Return from cache if available
    if (_surahCache.containsKey(surahNumber)) {
      return _surahCache[surahNumber]!;
    }

    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.quranApiBaseUrl}/surah/$surahNumber/ar.uthmani',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ayahs = data['data']['ayahs'] as List;
        final verses = ayahs.map((a) => Verse.fromJson(a)).toList();

        _surahCache[surahNumber] = verses;
        _isLoading = false;
        _safeNotify();
        return verses;
      } else {
        throw Exception('Failed to load Surah: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'فشل تحميل السورة. تأكد من اتصالك بالإنترنت.';
      _isLoading = false;
      _safeNotify();
      return [];
    }
  }

  /// Notify listeners safely, deferring if called during build phase
  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Search across the Quran
  Future<List<Map<String, dynamic>>> searchQuran(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.quranApiBaseUrl}/search/$query/all/ar',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matches = data['data']['matches'] as List? ?? [];
        return matches.map((m) {
          return {
            'text': m['text'] ?? '',
            'surahNumber': m['surah']?['number'] ?? 0,
            'surahName': m['surah']?['name'] ?? '',
            'verseNumber': m['numberInSurah'] ?? 0,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get the full text of a surah (all verses concatenated) for recitation comparison
  Future<String> getSurahFullText(int surahNumber) async {
    final verses = await getSurahVerses(surahNumber);
    return verses.map((v) => v.text).join(' ');
  }

  /// Clear cache
  void clearCache() {
    _surahCache.clear();
    notifyListeners();
  }
}
