import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/constants.dart';

/// Service for communicating with the Python Flask backend
class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  /// Send recorded audio to the backend for transcription and comparison
  Future<Map<String, dynamic>> transcribeAndCompare({
    required String audioFilePath,
    required int surahNumber,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/transcribe');

      final request = http.MultipartRequest('POST', uri);
      request.fields['surah_number'] = surahNumber.toString();

      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioFilePath,
          contentType: MediaType('audio', 'wav'),
        ),
      );

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 120),
          );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Transcription failed');
      }
    } catch (e) {
      throw Exception('فشل الاتصال بالخادم: $e');
    }
  }

  /// Stream audio chunks for real-time transcription
  Future<Map<String, dynamic>> streamAudioChunk({
    required List<int> audioData,
    required String sessionId,
    required int surahNumber,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/stream');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'audio_data': base64Encode(audioData),
          'session_id': sessionId,
          'surah_number': surahNumber,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Streaming failed');
      }
    } catch (e) {
      throw Exception('فشل البث: $e');
    }
  }

  /// Check if backend is available
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.apiBaseUrl}/api/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get the reference text for a surah from the backend
  Future<String> getSurahText(int surahNumber) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/surah/$surahNumber'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['text'] ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }
}
