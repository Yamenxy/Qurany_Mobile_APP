import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/mushaf_pages.dart';
import '../models/mushaf_layout.dart';

/// Loads mushaf page layout (Page -> Line -> Ayah -> Word) live from the
/// public Quran.com API v4, which serves the same underlying Madani 15-line
/// layout data used internally by QUL/Tarteel (`mushaf=2`).
///
/// Pages are fetched lazily as the user swipes and are cached both in memory
/// (LRU, for smooth back-and-forth swiping) and on disk (so re-opening the
/// app doesn't require a full re-download).
class MushafLayoutService {
  static const String _baseUrl = 'https://api.quran.com/api/v4/verses/by_page';
  static const String _mushafId = '2';
  static const int _maxCachedPagesInMemory = 12;

  final Map<int, MushafPage> _memoryCache = {};
  final List<int> _lruOrder = [];

  Directory? _cacheDir;

  /// Loads a single mushaf page (1..604), using memory/disk cache when
  /// available and falling back to a live network request otherwise.
  Future<MushafPage> loadPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > MushafPageIndex.totalPages) {
      throw RangeError.range(pageNumber, 1, MushafPageIndex.totalPages);
    }

    final cached = _memoryCache[pageNumber];
    if (cached != null) {
      _touch(pageNumber);
      return cached;
    }

    final diskJson = await _readFromDiskCache(pageNumber);
    final rawJson = diskJson ?? await _fetchFromNetwork(pageNumber);

    final page = MushafPage.fromQuranApiJson(pageNumber, rawJson);
    _storeInMemory(pageNumber, page);
    return page;
  }

  /// Warms the cache for pages around [pageNumber] so swiping forward/back
  /// feels instant. Failures are ignored since this is best-effort.
  Future<void> prefetchAround(int pageNumber, {int radius = 1}) async {
    for (var p = pageNumber - radius; p <= pageNumber + radius; p++) {
      if (p < 1 || p > MushafPageIndex.totalPages || p == pageNumber) continue;
      unawaited(loadPage(p).catchError((_) => MushafPage(pageNumber: p, lines: const [])));
    }
  }

  int? firstPageForSurah(int surahNumber) {
    try {
      return MushafPageIndex.firstPage(surahNumber);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _fetchFromNetwork(int pageNumber) async {
    final uri = Uri.parse(
      '$_baseUrl/$pageNumber'
      '?words=true'
      '&word_fields=text_uthmani,line_number,char_type_name,position'
      '&fields=text_uthmani'
      '&mushaf=$_mushafId'
      '&per_page=50',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load mushaf page $pageNumber (${response.statusCode})',
      );
    }

    final decoded =
        json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    unawaited(_writeToDiskCache(pageNumber, decoded));
    return decoded;
  }

  Future<Directory> _getCacheDir() async {
    final existing = _cacheDir;
    if (existing != null) return existing;

    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/mushaf_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  Future<Map<String, dynamic>?> _readFromDiskCache(int pageNumber) async {
    try {
      final dir = await _getCacheDir();
      final file = File('${dir.path}/$pageNumber.json');
      if (!await file.exists()) return null;
      return json.decode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeToDiskCache(
    int pageNumber,
    Map<String, dynamic> data,
  ) async {
    try {
      final dir = await _getCacheDir();
      final file = File('${dir.path}/$pageNumber.json');
      await file.writeAsString(json.encode(data));
    } catch (_) {
      // Disk caching is a best-effort optimization; ignore failures.
    }
  }

  void _storeInMemory(int pageNumber, MushafPage page) {
    _memoryCache[pageNumber] = page;
    _touch(pageNumber);
    while (_lruOrder.length > _maxCachedPagesInMemory) {
      final oldest = _lruOrder.removeAt(0);
      _memoryCache.remove(oldest);
    }
  }

  void _touch(int pageNumber) {
    _lruOrder.remove(pageNumber);
    _lruOrder.add(pageNumber);
  }
}
