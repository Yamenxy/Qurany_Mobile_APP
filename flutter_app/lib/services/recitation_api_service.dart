import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/constants.dart';

/// Thrown when the recitation backend is unreachable or returns an error.
class RecitationApiException implements Exception {
  final String message;
  final int? statusCode;
  RecitationApiException(this.message, {this.statusCode});

  @override
  String toString() => 'RecitationApiException($statusCode): $message';
}

/// Client for the Qurany FastAPI backend (transcription + recitation analysis).
///
/// The backend transcribes recorded audio with faster-whisper and aligns it
/// against the canonical Surah text, returning the same result shape the app
/// already builds on-device. When the backend is unavailable, callers should
/// fall back to the on-device comparison path.
class RecitationApiService {
  final String baseUrl;
  final http.Client _client;

  RecitationApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? AppConstants.recitationApiBaseUrl,
        _client = client ?? http.Client();

  /// Whether the surah is handled by the backend (MVP: Surah Al-Naba only).
  bool supportsSurah(int surahNumber) =>
      AppConstants.serverSupportedSurahs.contains(surahNumber);

  /// Quick health probe used to decide between server and on-device analysis.
  Future<bool> isHealthy({Duration timeout = const Duration(seconds: 3)}) async {
    try {
      final resp =
          await _client.get(Uri.parse('$baseUrl/health')).timeout(timeout);
      if (resp.statusCode != 200) return false;
      final body = json.decode(resp.body) as Map<String, dynamic>;
      return body['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// Upload a recorded audio file for transcription + comparison.
  ///
  /// Returns the analysis result map with the same keys the on-device path
  /// produces: `transcribed_text`, `reference_text`, `similarity_score`,
  /// `total_words`, `matched_words`, `mistakes`, `errors`, `segments`.
  Future<Map<String, dynamic>> analyzeRecitation({
    required String audioFilePath,
    required int surahNumber,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw RecitationApiException('Audio file not found: $audioFilePath');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/analyze'),
    )
      ..fields['surah_number'] = surahNumber.toString()
      ..files.add(await http.MultipartFile.fromPath('file', audioFilePath));

    try {
      final streamed = await _client.send(request).timeout(timeout);
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode != 200) {
        throw RecitationApiException(
          'Analyze failed: ${resp.body}',
          statusCode: resp.statusCode,
        );
      }
      return json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    } on RecitationApiException {
      rethrow;
    } catch (e) {
      throw RecitationApiException('Network error during analyze: $e');
    }
  }

  /// Compare an already-transcribed text against the surah reference.
  ///
  /// Useful as a lightweight path (e.g. sending the on-device speech-to-text
  /// transcript to the server for consistent alignment/scoring).
  Future<Map<String, dynamic>> analyzeText({
    required int surahNumber,
    required String transcribedText,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final resp = await _client
          .post(
            Uri.parse('$baseUrl/api/v1/analyze-text'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'surah_number': surahNumber,
              'transcribed_text': transcribedText,
            }),
          )
          .timeout(timeout);
      if (resp.statusCode != 200) {
        throw RecitationApiException(
          'Analyze-text failed: ${resp.body}',
          statusCode: resp.statusCode,
        );
      }
      return json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    } on RecitationApiException {
      rethrow;
    } catch (e) {
      throw RecitationApiException('Network error during analyze-text: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Convenience: log + swallow errors, returning null so the caller can fall
/// back to the on-device path.
extension SafeRecitationApi on RecitationApiService {
  Future<Map<String, dynamic>?> tryAnalyzeRecitation({
    required String audioFilePath,
    required int surahNumber,
  }) async {
    try {
      return await analyzeRecitation(
        audioFilePath: audioFilePath,
        surahNumber: surahNumber,
      );
    } catch (e) {
      debugPrint('Server recitation analysis failed, using on-device: $e');
      return null;
    }
  }
}
