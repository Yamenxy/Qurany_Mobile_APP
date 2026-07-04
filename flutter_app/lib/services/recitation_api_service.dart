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
class RecitationApiService {
  final String? _baseUrlOverride;
  final http.Client _client;

  RecitationApiService({String? baseUrl, http.Client? client})
      : _baseUrlOverride = baseUrl,
        _client = client ?? http.Client();

  /// Resolved per call so an address saved in Settings takes effect immediately.
  String get baseUrl => _baseUrlOverride ?? AppConstants.recitationApiBaseUrl;

  bool supportsSurah(int surahNumber) =>
      AppConstants.serverSupportedSurahs.contains(surahNumber);

  Future<bool> isHealthy({Duration timeout = const Duration(seconds: 3)}) async {
    try {
      final resp = await _client
          .get(AppConstants.apiUri(baseUrl, '/health'))
          .timeout(timeout);
      if (resp.statusCode != 200) return false;
      final body = json.decode(resp.body) as Map<String, dynamic>;
      return body['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// Full AI pipeline: audio -> Whisper ASR -> alignment -> harakat/tajweed.
  Future<Map<String, dynamic>> analyzeRecitation({
    required String audioFilePath,
    required int surahNumber,
    String riwayah = 'hafs',
    int? startAyah,
    int? endAyah,
    bool autoDetectAyahRange = true,
    Duration timeout = const Duration(seconds: 180),
  }) async {
    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw RecitationApiException('Audio file not found: $audioFilePath');
    }

    final request = http.MultipartRequest(
      'POST',
      AppConstants.apiUri(baseUrl, '/api/v1/analyze'),
    )
      ..fields['surah_number'] = surahNumber.toString()
      ..fields['riwayah'] = riwayah;

    if (startAyah != null) {
      request.fields['start_ayah'] = startAyah.toString();
    }
    if (endAyah != null) {
      request.fields['end_ayah'] = endAyah.toString();
    }
    if (startAyah == null && autoDetectAyahRange) {
      request.fields['auto_detect_ayah_range'] = 'true';
    }

    request.files.add(await http.MultipartFile.fromPath('file', audioFilePath));

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

  Future<Map<String, dynamic>> analyzeText({
    required int surahNumber,
    required String transcribedText,
    String riwayah = 'hafs',
    int? startAyah,
    int? endAyah,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final body = <String, dynamic>{
        'surah_number': surahNumber,
        'transcribed_text': transcribedText,
        'riwayah': riwayah,
      };
      if (startAyah != null) body['startAyah'] = startAyah;
      if (endAyah != null) body['endAyah'] = endAyah;

      final resp = await _client
          .post(
            AppConstants.apiUri(baseUrl, '/api/v1/analyze-text'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
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
/// back to the on-device path (tahfeez per-ayah tashkeel).
extension SafeRecitationApi on RecitationApiService {
  Future<Map<String, dynamic>?> tryAnalyzeRecitation({
    required String audioFilePath,
    required int surahNumber,
    String riwayah = 'hafs',
    int? startAyah,
    int? endAyah,
  }) async {
    try {
      return await analyzeRecitation(
        audioFilePath: audioFilePath,
        surahNumber: surahNumber,
        riwayah: riwayah,
        startAyah: startAyah,
        endAyah: endAyah,
        autoDetectAyahRange: startAyah == null,
        timeout: const Duration(seconds: 90),
      );
    } catch (e) {
      debugPrint('Server recitation analysis failed, using on-device: $e');
      return null;
    }
  }
}
