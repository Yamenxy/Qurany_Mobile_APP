import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recitation_session.dart';

class BookmarkService extends ChangeNotifier {
  final SharedPreferences _prefs;
  List<Bookmark> _bookmarks = [];

  BookmarkService(this._prefs) {
    _loadBookmarks();
  }

  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  void _loadBookmarks() {
    final data = _prefs.getString('bookmarks');
    if (data != null) {
      final list = json.decode(data) as List;
      _bookmarks = list.map((e) => Bookmark.fromJson(e)).toList();
    }
  }

  Future<void> _saveBookmarks() async {
    final data = json.encode(_bookmarks.map((b) => b.toJson()).toList());
    await _prefs.setString('bookmarks', data);
  }

  Future<void> addBookmark(Bookmark bookmark) async {
    // Remove existing bookmark for same surah/verse
    _bookmarks.removeWhere(
      (b) =>
          b.surahNumber == bookmark.surahNumber &&
          b.verseNumber == bookmark.verseNumber,
    );
    _bookmarks.insert(0, bookmark);
    await _saveBookmarks();
    notifyListeners();
  }

  Future<void> removeBookmark(int surahNumber, int verseNumber) async {
    _bookmarks.removeWhere(
      (b) => b.surahNumber == surahNumber && b.verseNumber == verseNumber,
    );
    await _saveBookmarks();
    notifyListeners();
  }

  bool isBookmarked(int surahNumber, int verseNumber) {
    return _bookmarks.any(
      (b) => b.surahNumber == surahNumber && b.verseNumber == verseNumber,
    );
  }

  Future<void> clearAll() async {
    _bookmarks.clear();
    await _saveBookmarks();
    notifyListeners();
  }
}
