import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentFilePath;
  Timer? _durationTimer;
  int _recordingDurationSeconds = 0;
  final StreamController<int> _durationController =
      StreamController<int>.broadcast();

  bool get isRecording => _isRecording;
  String? get currentFilePath => _currentFilePath;
  int get recordingDuration => _recordingDurationSeconds;
  Stream<int> get durationStream => _durationController.stream;

  /// Check and request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return false;

      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentFilePath = '${dir.path}/recitation_$timestamp.wav';

      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 128000,
      );

      await _recorder.start(config, path: _currentFilePath!);
      _isRecording = true;
      _recordingDurationSeconds = 0;

      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _recordingDurationSeconds++;
        _durationController.add(_recordingDurationSeconds);
      });

      return true;
    } catch (e) {
      _isRecording = false;
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      _durationTimer?.cancel();

      if (await _recorder.isRecording()) {
        final path = await _recorder.stop();
        _isRecording = false;
        _currentFilePath = path;
        return path;
      }
      _isRecording = false;
      return _currentFilePath;
    } catch (e) {
      _isRecording = false;
      return null;
    }
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    _durationTimer?.cancel();
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}
    _isRecording = false;
    _currentFilePath = null;
  }

  /// Get amplitude stream for visualizer
  Stream<double> get amplitudeStream {
    return Stream.periodic(const Duration(milliseconds: 100)).asyncMap((_) async {
      try {
        final amp = await _recorder.getAmplitude();
        // Normalize: dBFS is typically -160 to 0
        final normalized = (amp.current + 60) / 60;
        return normalized.clamp(0.0, 1.0);
      } catch (_) {
        return 0.0;
      }
    });
  }

  String formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void dispose() {
    _durationTimer?.cancel();
    _durationController.close();
    _recorder.dispose();
  }
}
